package com.example.campuspay.audio

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.PI

class AcousticAudioEngine(private val context: Context) {

    companion object {
        private const val SAMPLE_RATE = 44100
        private const val BIT_DURATION_MS = 30 // 30ms per bit (~33 bps)
        private const val SYNC_DURATION_MS = 200 // 200ms sync preamble
        private const val ANALYSIS_WINDOW_MS = 10 // Short windows let the receiver recover symbol timing
        private const val FRAME_MAGIC_0 = 0xA5
        private const val FRAME_MAGIC_1 = 0x5A
        private const val FRAME_HEADER_BYTES = 4
        private const val FRAME_CHECKSUM_BYTES = 2
        private const val MAX_FRAME_PAYLOAD_BYTES = 512

        // Slow, wallet-free diagnostic protocol, modeled on the successful web demo.
        private const val DIAGNOSTIC_WAKE_FREQ = 1700.0
        private const val DIAGNOSTIC_BIT0_FREQ = 1200.0
        private const val DIAGNOSTIC_BIT1_FREQ = 2200.0
        private const val DIAGNOSTIC_WAKE_MS = 600
        private const val DIAGNOSTIC_GUARD_MS = 200
        private const val DIAGNOSTIC_BIT_MS = 120
        private const val DIAGNOSTIC_MIN_TONE_POWER = 1e6

        // Audible FSK frequencies (1.2 kHz - 2.4 kHz) - universally supported by all phone hardware
        private const val AUDIBLE_SYNC_FREQ = 1200.0
        private const val AUDIBLE_BIT0_FREQ = 1800.0
        private const val AUDIBLE_BIT1_FREQ = 2400.0

        // Ultrasonic FSK frequencies (17.5 kHz - 19.5 kHz)
        private const val ULTRASONIC_SYNC_FREQ = 17500.0
        private const val ULTRASONIC_BIT0_FREQ = 18500.0
        private const val ULTRASONIC_BIT1_FREQ = 19500.0

        private const val STATE_SEARCHING_SYNC = 0
        private const val STATE_IN_SYNC = 1
        private const val STATE_RECEIVING_BITS = 2
    }

    @Volatile private var isListening = false
    @Volatile private var isTransmitting = false
    @Volatile private var diagnosticListening = false
    private var listenerThread: Thread? = null
    @Volatile private var activeRecorder: AudioRecord? = null
    private var currentMode = "audible" // "audible" or "ultrasonic"

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun setMode(mode: String) {
        if (mode.equals("ultrasonic", ignoreCase = true)) {
            currentMode = "ultrasonic"
        } else {
            currentMode = "audible"
        }
    }

    fun checkRecordPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun startListening(diagnostic: Boolean = false): Boolean {
        if (!checkRecordPermission()) {
            sendEvent(mapOf("type" to "error", "message" to "PERMISSION_DENIED: RECORD_AUDIO not granted"))
            return false
        }

        if (isListening) return diagnosticListening == diagnostic

        val recorder = createAudioRecord()
        if (recorder == null) {
            sendEvent(mapOf("type" to "error", "message" to "MIC_INIT_FAILED"))
            return false
        }
        try {
            recorder.startRecording()
            if (recorder.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                recorder.release()
                sendEvent(mapOf("type" to "error", "message" to "MIC_START_FAILED"))
                return false
            }
        } catch (e: Exception) {
            try { recorder.release() } catch (_: Exception) {}
            sendEvent(mapOf("type" to "error", "message" to "MIC_START_FAILED: ${e.message}"))
            return false
        }

        activeRecorder = recorder
        diagnosticListening = diagnostic
        isListening = true
        requestAudioFocus()

        listenerThread = thread(start = true, isDaemon = true, name = "AcousticListener") {
            runAudioReceiverLoop(recorder)
        }

        sendEvent(mapOf("type" to "listening_status", "active" to true, "mode" to currentMode))
        if (diagnostic) {
            sendEvent(mapOf("type" to "diagnostic_status", "message" to "Diagnostic: listening for the 1700 Hz wake tone."))
        }
        return true
    }

    fun stopListening() {
        if (!isListening) return
        isListening = false
        try {
            listenerThread?.interrupt()
            listenerThread = null
        } catch (_: Exception) {}
        try { activeRecorder?.stop() } catch (_: Exception) {}
        abandonAudioFocus()
        sendEvent(mapOf("type" to "listening_status", "active" to false))
    }

    @Synchronized
    fun transmitAudio(payload: String, mode: String? = null): Boolean {
        val activeMode = mode ?: currentMode
        if (isTransmitting) return false
        isTransmitting = true

        thread(start = true, name = "AcousticTransmitter") {
            requestAudioFocus()
            sendEvent(mapOf("type" to "transmission_started", "payload" to payload, "mode" to activeMode))

            try {
                val syncFreq = if (activeMode == "ultrasonic") ULTRASONIC_SYNC_FREQ else AUDIBLE_SYNC_FREQ
                val bit0Freq = if (activeMode == "ultrasonic") ULTRASONIC_BIT0_FREQ else AUDIBLE_BIT0_FREQ
                val bit1Freq = if (activeMode == "ultrasonic") ULTRASONIC_BIT1_FREQ else AUDIBLE_BIT1_FREQ

                val pcmData = generateFskPcm(payload, syncFreq, bit0Freq, bit1Freq)
                playPcmAudio(pcmData)

                sendEvent(mapOf("type" to "transmission_completed", "payload" to payload, "mode" to activeMode))
            } catch (e: Exception) {
                sendEvent(mapOf("type" to "error", "message" to "TRANSMIT_ERROR: ${e.message}"))
            } finally {
                isTransmitting = false
                abandonAudioFocus()
            }
        }
        return true
    }

    @Synchronized
    fun transmitDiagnosticPing(): Boolean {
        if (isTransmitting) return false
        isTransmitting = true
        thread(start = true, name = "AcousticDiagnosticTransmitter") {
            requestAudioFocus()
            sendEvent(mapOf("type" to "diagnostic_status", "message" to "Diagnostic: transmitting PING."))
            try {
                playPcmAudio(generateDiagnosticPcm())
                sendEvent(mapOf("type" to "diagnostic_status", "message" to "Diagnostic: PING playback finished; check the receiver."))
            } catch (e: Exception) {
                sendEvent(mapOf("type" to "diagnostic_error", "message" to "Diagnostic: transmit failed: ${e.message}"))
            } finally {
                isTransmitting = false
                abandonAudioFocus()
            }
        }
        return true
    }

    private fun generateDiagnosticPcm(): ShortArray {
        val payload = "PING".toByteArray(Charsets.US_ASCII)
        val checksum = payload.fold(0) { sum, value -> (sum + (value.toInt() and 0xFF)) and 0xFF }
        val frame = byteArrayOf(0xA5.toByte(), 0x5A, payload.size.toByte()) + payload + byteArrayOf(checksum.toByte())
        val bits = ArrayList<Boolean>(frame.size * 8)
        for (byte in frame) {
            val value = byte.toInt() and 0xFF
            for (bitIndex in 7 downTo 0) bits.add(((value shr bitIndex) and 1) == 1)
        }

        val wakeSamples = SAMPLE_RATE * DIAGNOSTIC_WAKE_MS / 1000
        val guardSamples = SAMPLE_RATE * DIAGNOSTIC_GUARD_MS / 1000
        val samplesPerBit = SAMPLE_RATE * DIAGNOSTIC_BIT_MS / 1000
        val pcm = ShortArray(wakeSamples + guardSamples + bits.size * samplesPerBit)
        var sampleIndex = 0
        for (i in 0 until wakeSamples) {
            pcm[sampleIndex++] = (sin(2.0 * PI * DIAGNOSTIC_WAKE_FREQ * i / SAMPLE_RATE) * 26000).toInt().toShort()
        }
        sampleIndex += guardSamples // The zero-filled portion is the guard gap.
        for (bit in bits) {
            val frequency = if (bit) DIAGNOSTIC_BIT1_FREQ else DIAGNOSTIC_BIT0_FREQ
            for (i in 0 until samplesPerBit) {
                pcm[sampleIndex++] = (sin(2.0 * PI * frequency * i / SAMPLE_RATE) * 26000).toInt().toShort()
            }
        }
        return pcm
    }

    private fun generateFskPcm(
        payload: String,
        syncFreq: Double,
        bit0Freq: Double,
        bit1Freq: Double
    ): ShortArray {
        val samplesPerBit = (SAMPLE_RATE * BIT_DURATION_MS) / 1000
        val samplesPerSync = (SAMPLE_RATE * SYNC_DURATION_MS) / 1000

        val payloadBytes = payload.toByteArray(Charsets.UTF_8)
        require(payloadBytes.size in 1..MAX_FRAME_PAYLOAD_BYTES) {
            "P2P payload must be between 1 and $MAX_FRAME_PAYLOAD_BYTES bytes"
        }
        val frameWithoutChecksum = ByteArray(FRAME_HEADER_BYTES + payloadBytes.size)
        frameWithoutChecksum[0] = FRAME_MAGIC_0.toByte()
        frameWithoutChecksum[1] = FRAME_MAGIC_1.toByte()
        frameWithoutChecksum[2] = ((payloadBytes.size shr 8) and 0xFF).toByte()
        frameWithoutChecksum[3] = (payloadBytes.size and 0xFF).toByte()
        payloadBytes.copyInto(frameWithoutChecksum, FRAME_HEADER_BYTES)
        val frameChecksum = crc16(frameWithoutChecksum, 0, frameWithoutChecksum.size)
        val framedBytes = frameWithoutChecksum + byteArrayOf(
            ((frameChecksum shr 8) and 0xFF).toByte(),
            (frameChecksum and 0xFF).toByte()
        )
        val bits = ArrayList<Boolean>()

        // Framing preamble: 10
        bits.add(true)
        bits.add(false)

        for (b in framedBytes) {
            val valInt = b.toInt() and 0xFF
            for (bitIdx in 7 downTo 0) {
                bits.add(((valInt shr bitIdx) and 1) == 1)
            }
        }

        val totalSamples = samplesPerSync + (bits.size * samplesPerBit)
        val pcm = ShortArray(totalSamples)
        var sampleIdx = 0

        // 1. Sync Tone (200ms)
        for (i in 0 until samplesPerSync) {
            val angle = 2.0 * PI * syncFreq * i / SAMPLE_RATE
            pcm[sampleIdx++] = (sin(angle) * 32000).toInt().toShort()
        }

        // 2. Data Bits
        for (bit in bits) {
            val freq = if (bit) bit1Freq else bit0Freq
            for (i in 0 until samplesPerBit) {
                val angle = 2.0 * PI * freq * i / SAMPLE_RATE
                pcm[sampleIdx++] = (sin(angle) * 32000).toInt().toShort()
            }
        }

        return pcm
    }

    private fun playPcmAudio(pcmData: ShortArray) {
        val minBufferSize = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        val audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(maxOf(minBufferSize, pcmData.size * 2))
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioTrack.setVolume(1.0f)
        }

        audioTrack.write(pcmData, 0, pcmData.size)
        audioTrack.play()

        val playTimeMs = (pcmData.size.toDouble() / SAMPLE_RATE * 1000).toLong()
        Thread.sleep(playTimeMs + 60)

        audioTrack.stop()
        audioTrack.release()
    }

    private fun createAudioRecord(): AudioRecord? {
        val minBufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufferSize <= 0) return null

        val sources = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            arrayOf(
                MediaRecorder.AudioSource.UNPROCESSED,
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                MediaRecorder.AudioSource.MIC
            )
        } else {
            arrayOf(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                MediaRecorder.AudioSource.MIC
            )
        }

        for (source in sources) {
            try {
                val rec = AudioRecord(
                    source,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    minBufferSize * 2
                )
                if (rec.state == AudioRecord.STATE_INITIALIZED) {
                    return rec
                }
                rec.release()
            } catch (_: Exception) {}
        }
        return null
    }

    private fun runAudioReceiverLoop(audioRecord: AudioRecord) {
        val samplesPerWindow = (SAMPLE_RATE * ANALYSIS_WINDOW_MS) / 1000
        val samplesPerBit = (SAMPLE_RATE * BIT_DURATION_MS) / 1000
        val buffer = ShortArray(samplesPerWindow)

        try {
            if (diagnosticListening) {
                runDiagnosticReceiverLoop(audioRecord, samplesPerWindow, buffer)
                return
            }
            val syncFreq = if (currentMode == "ultrasonic") ULTRASONIC_SYNC_FREQ else AUDIBLE_SYNC_FREQ
            val bit0Freq = if (currentMode == "ultrasonic") ULTRASONIC_BIT0_FREQ else AUDIBLE_BIT0_FREQ
            val bit1Freq = if (currentMode == "ultrasonic") ULTRASONIC_BIT1_FREQ else AUDIBLE_BIT1_FREQ

            var receiverState = STATE_SEARCHING_SYNC
            val bitBuffer = StringBuilder()
            var silenceCount = 0
            var syncRunLength = 0
            var samplePosition = 0L
            var dataStartSample: Long? = null
            var activeSymbolIndex = -1
            var zeroVotes = 0
            var oneVotes = 0
            var weakSymbolCount = 0
            var announcedFrameLength: Int? = null

            fun resetFrameSearch() {
                receiverState = STATE_SEARCHING_SYNC
                bitBuffer.clear()
                silenceCount = 0
                syncRunLength = 0
                dataStartSample = null
                activeSymbolIndex = -1
                zeroVotes = 0
                oneVotes = 0
                weakSymbolCount = 0
                announcedFrameLength = null
            }

            // A 30 ms symbol spans three 10 ms analysis windows. Vote across
            // every window in the symbol instead of dropping a weak decision;
            // dropping even one bit shifts every following byte in the frame.
            fun finishSymbol() {
                if (activeSymbolIndex < 0) return
                if (zeroVotes == oneVotes) weakSymbolCount++
                bitBuffer.append(if (oneVotes > zeroVotes) '1' else '0')
                zeroVotes = 0
                oneVotes = 0
            }

            // Frame layout after the two-bit preamble: magic(2), length(2),
            // payload, CRC16(2). A valid frame ends at its declared length,
            // so background noise cannot keep the receiver waiting for silence.
            fun completeFrameIfReady(): Boolean {
                if (bitBuffer.length < 2 + FRAME_HEADER_BYTES * 8) return false
                if (!bitBuffer.toString().startsWith("10")) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: invalid preamble."))
                    resetFrameSearch()
                    return true
                }

                val headerBits = bitBuffer.substring(2, 2 + FRAME_HEADER_BYTES * 8)
                val headerBytes = diagnosticBytes(headerBits)
                if (headerBytes == null ||
                    (headerBytes[0].toInt() and 0xFF) != FRAME_MAGIC_0 ||
                    (headerBytes[1].toInt() and 0xFF) != FRAME_MAGIC_1) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: invalid length-frame header."))
                    resetFrameSearch()
                    return true
                }

                val payloadLength = ((headerBytes[2].toInt() and 0xFF) shl 8) or
                    (headerBytes[3].toInt() and 0xFF)
                if (payloadLength !in 1..MAX_FRAME_PAYLOAD_BYTES) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: invalid payload length $payloadLength."))
                    resetFrameSearch()
                    return true
                }

                if (announcedFrameLength != payloadLength) {
                    announcedFrameLength = payloadLength
                    sendEvent(mapOf("type" to "frame_receiving", "payloadBytes" to payloadLength))
                }

                val expectedBits = 2 + (FRAME_HEADER_BYTES + payloadLength + FRAME_CHECKSUM_BYTES) * 8
                if (bitBuffer.length < expectedBits) return false
                if (bitBuffer.length > expectedBits) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: received excess bits."))
                    resetFrameSearch()
                    return true
                }

                val frameBytes = diagnosticBytes(bitBuffer.substring(2))
                val checksumOffset = FRAME_HEADER_BYTES + payloadLength
                if (frameBytes == null || frameBytes.size != checksumOffset + FRAME_CHECKSUM_BYTES) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: incomplete framed payload."))
                    resetFrameSearch()
                    return true
                }

                val receivedChecksum = ((frameBytes[checksumOffset].toInt() and 0xFF) shl 8) or
                    (frameBytes[checksumOffset + 1].toInt() and 0xFF)
                val expectedChecksum = crc16(frameBytes, 0, checksumOffset)
                if (receivedChecksum != expectedChecksum) {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: acoustic CRC16 mismatch ($weakSymbolCount weak symbols)."))
                    resetFrameSearch()
                    return true
                }

                val payload = String(frameBytes, FRAME_HEADER_BYTES, payloadLength, Charsets.UTF_8)
                if (payload.startsWith("CP1|")) {
                    sendEvent(mapOf("type" to "packet_received", "payload" to payload, "mode" to currentMode))
                } else {
                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: payload is not a CampusPay CP1 message."))
                }
                resetFrameSearch()
                return true
            }

            while (isListening && !Thread.currentThread().isInterrupted) {
                // AudioRecord is allowed to return fewer samples than requested.
                // Fill one analysis window instead of discarding a partial read,
                // which would shift every later bit boundary.
                var filled = 0
                while (filled < samplesPerWindow && isListening) {
                    val readCount = audioRecord.read(buffer, filled, samplesPerWindow - filled)
                    if (readCount < 0) {
                        if (isListening) {
                            sendEvent(mapOf("type" to "error", "message" to "MIC_READ_FAILED: $readCount"))
                            isListening = false
                            sendEvent(mapOf("type" to "listening_status", "active" to false))
                        }
                        break
                    }
                    if (readCount > 0) filled += readCount
                }
                if (filled < samplesPerWindow) break

                val windowStart = samplePosition
                val windowCenter = windowStart + samplesPerWindow / 2
                samplePosition += samplesPerWindow
                val syncPower = calculateGoertzelPower(buffer, samplesPerWindow, syncFreq)
                val bit0Power = calculateGoertzelPower(buffer, samplesPerWindow, bit0Freq)
                val bit1Power = calculateGoertzelPower(buffer, samplesPerWindow, bit1Freq)

                val minPowerThreshold = 5e3
                val syncDominant = syncPower > minPowerThreshold && syncPower > (bit0Power + bit1Power) * 1.2
                val dataPower = maxOf(bit0Power, bit1Power)
                val dataTonePresent = dataPower > minPowerThreshold && dataPower > syncPower * 1.1

                when (receiverState) {
                    STATE_SEARCHING_SYNC -> {
                        syncRunLength = if (syncDominant) syncRunLength + 1 else 0
                        if (syncRunLength >= 3) {
                            receiverState = STATE_IN_SYNC
                            bitBuffer.clear()
                            silenceCount = 0
                            weakSymbolCount = 0
                            sendEvent(mapOf("type" to "sync_detected", "mode" to currentMode))
                        }
                    }

                    STATE_IN_SYNC -> {
                        if (!syncDominant && dataTonePresent) {
                            // The first data window anchors a 30 ms symbol grid.
                            // Its 10 ms windows are majority-voted below, which
                            // tolerates a partially mixed transition window.
                            receiverState = STATE_RECEIVING_BITS
                            dataStartSample = windowStart
                            activeSymbolIndex = 0
                            zeroVotes = 0
                            oneVotes = 0
                            syncRunLength = 0
                        }
                    }

                    STATE_RECEIVING_BITS -> {
                        if (dataTonePresent) {
                            silenceCount = 0
                            val startSample = dataStartSample
                            if (startSample != null) {
                                val symbolIndex = ((windowCenter - startSample) / samplesPerBit).toInt()
                                var frameCompleted = false
                                while (activeSymbolIndex < symbolIndex) {
                                    finishSymbol()
                                    activeSymbolIndex++
                                    if (completeFrameIfReady()) {
                                        frameCompleted = true
                                        break
                                    }
                                }
                                if (frameCompleted) continue
                                if (activeSymbolIndex == symbolIndex) {
                                    if (bit1Power > bit0Power) {
                                        oneVotes++
                                    } else {
                                        zeroVotes++
                                    }
                                }
                            }
                        } else {
                            silenceCount++
                            if (silenceCount >= 5) {
                                finishSymbol()
                                if (!completeFrameIfReady() && bitBuffer.isNotEmpty()) {
                                    sendEvent(mapOf("type" to "decode_error", "message" to "Frame decode failed: truncated length-framed packet (${bitBuffer.length} bits; $weakSymbolCount weak symbols)."))
                                    resetFrameSearch()
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            sendEvent(mapOf("type" to "error", "message" to "RECORD_LOOP_EX: ${e.message}"))
        } finally {
            try {
                if (audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING) audioRecord.stop()
                audioRecord.release()
            } catch (_: Exception) {}
            if (activeRecorder === audioRecord) activeRecorder = null
        }
    }

    /** Receives the isolated PING frame; this path never emits P2P wallet events. */
    private fun runDiagnosticReceiverLoop(audioRecord: AudioRecord, windowSize: Int, buffer: ShortArray) {
        val samplesPerBit = SAMPLE_RATE * DIAGNOSTIC_BIT_MS / 1000
        val wakeSamples = SAMPLE_RATE * (DIAGNOSTIC_WAKE_MS + DIAGNOSTIC_GUARD_MS) / 1000
        var samplePosition = 0L
        var wakeRunLength = 0
        var wakeRunStart = 0L
        var dataStartSample: Long? = null
        var activeSymbolIndex = -1
        var zeroVotes = 0
        var oneVotes = 0
        var expectedBitCount: Int? = null
        val bits = StringBuilder()

        fun resetToWakeSearch() {
            wakeRunLength = 0
            dataStartSample = null
            activeSymbolIndex = -1
            zeroVotes = 0
            oneVotes = 0
            expectedBitCount = null
            bits.clear()
        }

        fun completeSymbol(): Boolean {
            if (activeSymbolIndex < 0) return false
            bits.append(if (oneVotes > zeroVotes) '1' else '0')
            zeroVotes = 0
            oneVotes = 0

            if (bits.length == 24) {
                val header = diagnosticBytes(bits.toString()) ?: return false
                val syncOk = (header[0].toInt() and 0xFF) == 0xA5 && (header[1].toInt() and 0xFF) == 0x5A
                val payloadLength = header[2].toInt() and 0xFF
                if (!syncOk || payloadLength !in 1..60) {
                    sendEvent(mapOf("type" to "diagnostic_error", "message" to "Diagnostic: invalid PING frame header."))
                    resetToWakeSearch()
                    return true
                }
                expectedBitCount = (payloadLength + 4) * 8
            }

            val targetBitCount = expectedBitCount
            if (targetBitCount != null && bits.length == targetBitCount) {
                val frame = diagnosticBytes(bits.toString())
                if (frame == null) {
                    sendEvent(mapOf("type" to "diagnostic_error", "message" to "Diagnostic: frame bits were incomplete."))
                } else {
                    val length = frame[2].toInt() and 0xFF
                    val payloadBytes = frame.copyOfRange(3, 3 + length)
                    val receivedChecksum = frame.last().toInt() and 0xFF
                    val expectedChecksum = payloadBytes.fold(0) { sum, value -> (sum + (value.toInt() and 0xFF)) and 0xFF }
                    if (receivedChecksum == expectedChecksum) {
                        sendEvent(mapOf("type" to "diagnostic_packet", "payload" to String(payloadBytes, Charsets.US_ASCII)))
                    } else {
                        sendEvent(mapOf("type" to "diagnostic_error", "message" to "Diagnostic: PING checksum failed."))
                    }
                }
                resetToWakeSearch()
                return true
            }
            return false
        }

        while (isListening && !Thread.currentThread().isInterrupted) {
            var filled = 0
            while (filled < windowSize && isListening) {
                val count = audioRecord.read(buffer, filled, windowSize - filled)
                if (count < 0) {
                    sendEvent(mapOf("type" to "diagnostic_error", "message" to "Diagnostic: microphone read failed ($count)."))
                    return
                }
                if (count > 0) filled += count
            }
            if (filled < windowSize) return

            val windowStart = samplePosition
            val windowCenter = windowStart + windowSize / 2
            samplePosition += windowSize
            val wakePower = calculateGoertzelPower(buffer, windowSize, DIAGNOSTIC_WAKE_FREQ)
            val bit0Power = calculateGoertzelPower(buffer, windowSize, DIAGNOSTIC_BIT0_FREQ)
            val bit1Power = calculateGoertzelPower(buffer, windowSize, DIAGNOSTIC_BIT1_FREQ)
            val wakeDominant = wakePower > DIAGNOSTIC_MIN_TONE_POWER && wakePower > (bit0Power + bit1Power) * 1.2

            if (dataStartSample == null) {
                wakeRunLength = if (wakeDominant) {
                    if (wakeRunLength == 0) wakeRunStart = windowStart
                    wakeRunLength + 1
                } else {
                    0
                }
                if (wakeRunLength >= 3) {
                    dataStartSample = wakeRunStart + wakeSamples
                    wakeRunLength = 0
                    sendEvent(mapOf("type" to "diagnostic_status", "message" to "Diagnostic: wake tone detected; waiting for PING data."))
                }
                continue
            }

            val start = dataStartSample ?: continue
            if (windowCenter < start) continue

            val symbolIndex = ((windowCenter - start) / samplesPerBit).toInt()
            while (activeSymbolIndex < symbolIndex) {
                if (completeSymbol()) break
                activeSymbolIndex++
            }
            if (dataStartSample == null) continue

            val strongest = maxOf(bit0Power, bit1Power)
            val weaker = minOf(bit0Power, bit1Power)
            if (strongest > DIAGNOSTIC_MIN_TONE_POWER && strongest > weaker * 1.2) {
                if (bit1Power > bit0Power) oneVotes++ else zeroVotes++
            }
        }
    }

    private fun diagnosticBytes(bitString: String): ByteArray? {
        if (bitString.length % 8 != 0) return null
        return try {
            ByteArray(bitString.length / 8) { byteIndex ->
                bitString.substring(byteIndex * 8, byteIndex * 8 + 8).toInt(2).toByte()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun crc16(bytes: ByteArray, offset: Int, length: Int): Int {
        var crc = 0xFFFF
        for (index in offset until offset + length) {
            crc = crc xor (bytes[index].toInt() and 0xFF)
            repeat(8) {
                crc = if ((crc and 1) != 0) (crc ushr 1) xor 0xA001 else crc ushr 1
            }
        }
        return crc and 0xFFFF
    }

    private fun calculateGoertzelPower(samples: ShortArray, numSamples: Int, targetFreq: Double): Double {
        val k = (0.5 + (numSamples * targetFreq / SAMPLE_RATE)).toInt()
        val omega = (2.0 * PI * k) / numSamples
        val cosine = cos(omega)
        val coeff = 2.0 * cosine

        var q0 = 0.0
        var q1 = 0.0
        var q2 = 0.0

        for (i in 0 until numSamples) {
            q0 = coeff * q1 - q2 + samples[i]
            q2 = q1
            q1 = q0
        }

        return q1 * q1 + q2 * q2 - q1 * q2 * coeff
    }

    private fun requestAudioFocus() {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .build()
            audioManager.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        }
    }

    private fun abandonAudioFocus() {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private fun sendEvent(data: Map<String, Any>) {
        mainHandler.post {
            eventSink?.success(data)
        }
    }
}
