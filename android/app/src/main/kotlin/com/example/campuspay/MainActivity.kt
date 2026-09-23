package com.example.campuspay

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.telephony.SubscriptionManager
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "campuspay/ussd"
        private const val EVENT_CHANNEL  = "campuspay/ussd_events"
        private const val REQUEST_CALL_PHONE = 1001
    }

    // Pending call while we wait for permission grant
    private var pendingUssdCode: String? = null
    private var pendingUssdResult: MethodChannel.Result? = null

    // EventChannel sink — updated live as USSD responses arrive
    private var eventSink: EventChannel.EventSink? = null

    @RequiresApi(Build.VERSION_CODES.O)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Event Channel (USSD response stream) ──────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(args: Any?) {
                    eventSink = null
                }
            })

        // ── Method Channel ─────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── startUssdSession ───────────────────────────────────────
                    // Args:  code (String)  — USSD string to dial, e.g. "*99#"
                    //        steps (List<String>) — replies to send sequentially
                    "startUssdSession" -> {
                        val code  = call.argument<String>("code") ?: "*99#"
                        val steps = call.argument<List<String>>("steps") ?: emptyList()
                        val fullCode = buildUssdString(code, steps)

                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                            // Pre-Oreo: fall back to dialer
                            dialFallback(fullCode)
                            result.success("fallback_dialer")
                            return@setMethodCallHandler
                        }

                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                            != PackageManager.PERMISSION_GRANTED
                        ) {
                            // Store pending and request at runtime
                            pendingUssdCode   = fullCode
                            pendingUssdResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.CALL_PHONE),
                                REQUEST_CALL_PHONE
                            )
                        } else {
                            executeSilentUssd(fullCode, steps, result)
                        }
                    }

                    // ── dialFallback ───────────────────────────────────────────
                    // Args:  code (String) — pre-encoded USSD URI, e.g. "*99*7*vpa*120#"
                    "dialFallback" -> {
                        val code = call.argument<String>("code") ?: "*99#"
                        dialFallback(code)
                        result.success("dialer_opened")
                    }

                    // ── checkPermission ────────────────────────────────────────
                    "checkPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this, Manifest.permission.CALL_PHONE
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Permission result callback ─────────────────────────────────────────────
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CALL_PHONE) {
            val code   = pendingUssdCode   ?: return
            val result = pendingUssdResult ?: return
            pendingUssdCode   = null
            pendingUssdResult = null

            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                executeSilentUssd(code, emptyList(), result)
            } else {
                // Permission denied — open dialer as fallback
                dialFallback(code)
                result.success("fallback_dialer")
            }
        }
    }

    // ── Core: TelephonyManager.sendUssdRequest() ───────────────────────────────
    @RequiresApi(Build.VERSION_CODES.O)
    private fun executeSilentUssd(code: String, steps: List<String>, result: MethodChannel.Result) {
        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager

        // Resolve subscription ID (for dual-SIM devices, prefer first active SIM)
        val subId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
            == PackageManager.PERMISSION_GRANTED
        ) {
            SubscriptionManager.getDefaultDataSubscriptionId()
                .takeIf { it != SubscriptionManager.INVALID_SUBSCRIPTION_ID }
                ?: SubscriptionManager.getDefaultSubscriptionId()
        } else {
            SubscriptionManager.getDefaultSubscriptionId()
        }

        val handler = Handler(Looper.getMainLooper())

        // Emit initial status
        pushEvent(mapOf("type" to "status", "text" to "Dialing *99# via GSM modem…"))

        try {
            tm.sendUssdRequest(
                code,
                object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(
                        tm: TelephonyManager,
                        request: String,
                        response: CharSequence
                    ) {
                        handler.post {
                            pushEvent(mapOf("type" to "response", "text" to response.toString()))
                            result.success(mapOf("status" to "success", "response" to response.toString()))
                        }
                    }

                    override fun onReceiveUssdResponseFailed(
                        tm: TelephonyManager,
                        request: String,
                        failureCode: Int
                    ) {
                        handler.post {
                            val msg = when (failureCode) {
                                TelephonyManager.USSD_RETURN_FAILURE -> "USSD request failed (network error)"
                                TelephonyManager.USSD_ERROR_SERVICE_UNAVAIL -> "USSD service unavailable (no GSM signal?)"
                                else -> "USSD failed — code $failureCode"
                            }
                            pushEvent(mapOf("type" to "error", "text" to msg))
                            result.success(mapOf("status" to "error", "message" to msg))
                        }
                    }
                },
                handler
            )
        } catch (e: SecurityException) {
            pushEvent(mapOf("type" to "error", "text" to "Permission denied: ${e.message}"))
            result.success(mapOf("status" to "permission_denied"))
        } catch (e: Exception) {
            pushEvent(mapOf("type" to "error", "text" to "Exception: ${e.message}"))
            result.error("USSD_EXCEPTION", e.message, null)
        }
    }

    // ── Fallback: open system dialer with USSD pre-encoded in tel: URI ─────────
    private fun dialFallback(code: String) {
        val encoded = Uri.encode(code)
        val intent  = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$encoded"))
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
        pushEvent(mapOf("type" to "fallback", "text" to "Opened system dialer for $code"))
    }

    // ── Build *99*step1*step2# style composite USSD string ────────────────────
    // NPCI allows pre-encoding sub-choices: *99*7*payee@upi*120#
    private fun buildUssdString(base: String, steps: List<String>): String {
        if (steps.isEmpty()) return base
        // Strip trailing # from base, append steps, re-add #
        val stem = base.trimEnd('#')
        return stem + "*" + steps.joinToString("*") + "#"
    }

    // ── Push to EventChannel sink safely from any thread ──────────────────────
    private fun pushEvent(data: Map<String, String>) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(data)
        }
    }
}
