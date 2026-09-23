import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter-side wrapper around the native `campuspay/ussd` MethodChannel.
///
/// Responsibilities:
///  - Request CALL_PHONE permission via native side
///  - Initiate a silent USSD session (API 26+ / TelephonyManager)
///  - Open ACTION_DIAL fallback when permission is denied or on older APIs
///  - Expose a [Stream] of raw USSD event maps from the EventChannel
class UssdService {
  static const _methodChannel = MethodChannel('campuspay/ussd');
  static const _eventChannel  = EventChannel('campuspay/ussd_events');

  Stream<Map<String, String>>? _eventStream;

  /// Broadcast stream of USSD events from the native side.
  /// Each event is a Map with keys: `type` and `text`.
  ///
  /// | type        | meaning                                    |
  /// |-------------|---------------------------------------------|
  /// | `status`    | Internal step description (dial, navigate) |
  /// | `response`  | Raw USSD response text from NPCI           |
  /// | `error`     | Error from GSM modem or permission denied  |
  /// | `fallback`  | Dialer was opened as fallback              |
  Stream<Map<String, String>> get ussdEvents {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => Map<String, String>.from(e as Map))
        .handleError((err) {
          debugPrint('[UssdService] EventChannel error: $err');
        });
    return _eventStream!;
  }

  /// Checks whether CALL_PHONE permission is currently granted.
  /// Returns `true` on non-Android platforms (no permission needed).
  Future<bool> hasCallPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on MissingPluginException {
      // Running on web/iOS — no native USSD
      return false;
    }
  }

  /// Initiates a silent *99# USSD session with automatic menu navigation.
  ///
  /// [payeeVpa]  — UPI VPA or 10-digit mobile number of the payee.
  /// [amount]    — Payment amount as a string (e.g. "120").
  ///
  /// Returns one of:
  ///  - `"success"`         — NPCI responded (PIN prompt expected)
  ///  - `"fallback_dialer"` — Dialer opened (permission denied or API < 26)
  ///  - `"error"`           — GSM-level failure
  ///
  /// The NPCI *99# menu structure targeted:
  ///   *99# → [7] Send Money → [payeeVpa] → [amount] → PIN (user types)
  Future<String> startUssdSession({
    required String payeeVpa,
    required String amount,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<dynamic>(
        'startUssdSession',
        {
          'code': '*99#',
          // Steps that will be automatically replied to NPCI sub-menus:
          // 1. "7" = Send Money by VPA/Mobile
          // 2. payeeVpa = recipient UPI ID or phone
          // 3. amount = payment amount (string, no decimals for whole rupees)
          'steps': ['7', payeeVpa, amount],
        },
      );

      if (result is Map) {
        return result['status'] as String? ?? 'error';
      }
      return result?.toString() ?? 'error';
    } on PlatformException catch (e) {
      debugPrint('[UssdService] PlatformException: ${e.message}');
      return 'error';
    } on MissingPluginException {
      debugPrint('[UssdService] No native plugin (web/iOS) — using fallback');
      return await _dialFallback(payeeVpa: payeeVpa, amount: amount);
    }
  }

  /// Opens the system dialer with the USSD string pre-encoded.
  /// This is the fallback when [startUssdSession] cannot run silently.
  ///
  /// On *99# the NPCI-spec composite format is:
  ///   `*99*7*{payeeVpa}*{amount}#`
  Future<String> dialFallback({
    required String payeeVpa,
    required String amount,
  }) =>
      _dialFallback(payeeVpa: payeeVpa, amount: amount);

  Future<String> _dialFallback({
    required String payeeVpa,
    required String amount,
  }) async {
    // NPCI composite USSD: one-shot encode avoids the interactive menu
    final compositeCode = '*99*7*$payeeVpa*$amount#';
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'dialFallback',
        {'code': compositeCode},
      );
      return result ?? 'dialer_opened';
    } on MissingPluginException {
      return 'platform_unsupported';
    }
  }
}
