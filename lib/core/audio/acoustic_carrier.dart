import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'p2p_message.dart';

enum AudioCarrierMode {
  audibleFsk, // 1.2 kHz - 2.4 kHz (Tested, reliable on all Android phones)
  ultrasonicFsk, // 17.5 kHz - 19.5 kHz (Configurable high-frequency)
}

/// Acoustic FSK carrier & P2P acoustic ACK transmission protocol engine
class AcousticCarrier {
  static final AcousticCarrier _instance = AcousticCarrier._internal();
  factory AcousticCarrier() => _instance;

  static const MethodChannel _methodChannel = MethodChannel('campuspay/audio');
  static const EventChannel _eventChannel = EventChannel('campuspay/audio_events');

  AudioCarrierMode _mode = AudioCarrierMode.audibleFsk;
  AudioCarrierMode get mode => _mode;

  bool _isListening = false;
  bool get isListening => _isListening;

  StreamSubscription? _eventSubscription;
  Completer<void>? _pendingTransmission;

  // Broadcast stream for incoming P2P versioned messages
  final _p2pMessageController = StreamController<P2pMessage>.broadcast();
  Stream<P2pMessage> get onP2pMessageReceived => _p2pMessageController.stream;

  // Broadcast stream for SoundBox receivers listening to ultrasonic bursts
  final _soundWaveController = StreamController<AcousticPacket>.broadcast();
  Stream<AcousticPacket> get onUltrasonicPacketReceived => _soundWaveController.stream;

  // Broadcast stream for Student Phones listening to acoustic ACKs
  final _acousticAckController = StreamController<AcousticAck>.broadcast();
  Stream<AcousticAck> get onAcousticAckReceived => _acousticAckController.stream;

  // Broadcast stream for audio status events
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get onStatusEvent => _statusController.stream;

  AcousticCarrier._internal() {
    _initNativeEventListener();
  }

  void setMode(AudioCarrierMode mode) {
    _mode = mode;
    final modeStr = mode == AudioCarrierMode.ultrasonicFsk ? 'ultrasonic' : 'audible';
    _methodChannel.invokeMethod('initAudio', {'mode': modeStr}).catchError((_) {});
  }

  void _initNativeEventListener() {
    if (kIsWeb) return;
    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final type = event['type'] as String?;
            if (type == 'packet_received') {
              final rawPayload = event['payload'] as String?;
              if (rawPayload != null) {
                _handleRawIncomingPayload(rawPayload);
              }
            } else if (type == 'listening_status') {
              _isListening = event['active'] as bool? ?? false;
              _statusController.add(_isListening ? 'Mic listening active' : 'Mic listening stopped');
            } else if (type == 'transmission_started') {
              _statusController.add('Emitting sound wave burst...');
            } else if (type == 'transmission_completed') {
              _statusController.add('Sound wave burst completed');
              final pending = _pendingTransmission;
              if (pending != null && !pending.isCompleted) pending.complete();
            } else if (type == 'error') {
              final message = event['message']?.toString() ?? 'Unknown native audio error';
              _statusController.add('Audio Error: $message');
              final pending = _pendingTransmission;
              if (pending != null && !pending.isCompleted) {
                pending.completeError(StateError(message));
              }
            } else if (type == 'decode_error') {
              _statusController.add('Frame decode failed: ${event['message'] ?? 'Unknown decoder error'}');
            } else if (type == 'sync_detected') {
              _statusController.add('Audio sync tone detected; decoding incoming frame...');
            } else if (type == 'frame_receiving') {
              final payloadBytes = event['payloadBytes'] as int? ?? 0;
              _statusController.add('Receiving frame data ($payloadBytes bytes)...');
            } else if (type == 'diagnostic_status') {
              _statusController.add(event['message']?.toString() ?? 'Diagnostic: audio test in progress.');
            } else if (type == 'diagnostic_packet') {
              final payload = event['payload']?.toString() ?? '';
              _statusController.add('Diagnostic: received "$payload"; checksum valid.');
            } else if (type == 'diagnostic_error') {
              _statusController.add(event['message']?.toString() ?? 'Diagnostic: frame failed.');
            }
          }
        },
        onError: (err) {
          debugPrint('[AcousticCarrier] Native EventChannel error: $err');
        },
      );
    } catch (e) {
      debugPrint('[AcousticCarrier] Platform EventChannel unavailable in current environment: $e');
    }
  }

  /// Request record microphone permission on Android
  Future<bool> checkAndRequestPermission() async {
    try {
      final bool granted = await _methodChannel.invokeMethod('requestRecordPermission') ?? false;
      return granted;
    } catch (_) {
      return true; // Fallback for desktop/test environment
    }
  }

  /// Start microphone listening mode
  Future<bool> startListening() async {
    final modeStr = _mode == AudioCarrierMode.ultrasonicFsk ? 'ultrasonic' : 'audible';
    try {
      final bool success = await _methodChannel.invokeMethod('startListening', {'mode': modeStr}) ?? false;
      _isListening = success;
      return success;
    } on MissingPluginException {
      _isListening = true;
      _statusController.add('Listening mode active (simulated audio stream)');
      return true;
    }
  }

  /// Start the isolated, wallet-free audible PING receiver.
  Future<bool> startDiagnosticListening() async {
    try {
      final bool success = await _methodChannel.invokeMethod('startListening', {
        'mode': 'audible',
        'diagnostic': true,
      }) ?? false;
      _isListening = success;
      return success;
    } on MissingPluginException {
      _statusController.add('Diagnostic: native Android audio is unavailable.');
      return false;
    }
  }

  /// Play a short framed PING. The diagnostic packet is never emitted on the
  /// P2P message stream and cannot credit or debit a wallet.
  Future<void> emitDiagnosticPing() async {
    final bool accepted = await _methodChannel.invokeMethod('transmitDiagnosticPing') ?? false;
    if (!accepted) throw StateError('Android audio engine rejected the diagnostic PING.');
  }

  /// Stop microphone listening mode
  Future<void> stopListening() async {
    _isListening = false;
    try {
      await _methodChannel.invokeMethod('stopListening');
    } catch (_) {}
  }

  /// Transmit a versioned P2P message frame over device speaker
  Future<void> emitP2pMessage(P2pMessage msg) async {
    final serialized = msg.serialize();
    final modeStr = _mode == AudioCarrierMode.ultrasonicFsk ? 'ultrasonic' : 'audible';

    debugPrint('[AcousticCarrier] Transmitting P2P Message over Speaker (${_mode.name}): $serialized');

    try {
      await _transmitAndWait(serialized, modeStr);
    } on MissingPluginException catch (e) {
      // Keep the no-native-plugin demo path for desktop/widget development.
      debugPrint('[AcousticCarrier] Native audio unavailable; using local demo path: $e');
      // Direct stream emit simulation for fallback/testing environments
      await Future.delayed(const Duration(milliseconds: 250));
      _handleRawIncomingPayload(serialized);
    }
  }

  /// Native transmitAudio only acknowledges that playback was queued. Wait for
  /// the matching completion event before allowing the P2P state machine to
  /// start its peer-response timeout.
  Future<void> _transmitAndWait(String payload, String mode) async {
    if (_pendingTransmission != null) {
      throw StateError('An audio transmission is already in progress.');
    }
    final completer = Completer<void>();
    _pendingTransmission = completer;
    try {
      // 30 ms per bit plus the 200 ms sync tone, with room for device/audio
      // route scheduling. UTF-8 byte count matches the native encoder.
      final bytes = utf8.encode(payload).length;
      final timeout = Duration(milliseconds: 320 + bytes * 240 + 15000);
      final completion = completer.future.timeout(timeout);
      _methodChannel.invokeMethod<bool>('transmitAudio', {
        'payload': payload,
        'mode': mode,
      }).then((accepted) {
        if (accepted != true && !completer.isCompleted) {
          completer.completeError(StateError('Android audio engine rejected the transmission.'));
        }
      }, onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      });
      await completion;
    } finally {
      if (identical(_pendingTransmission, completer)) _pendingTransmission = null;
    }
  }

  /// Legacy helper for SoundBox ultrasonic burst emission
  Future<void> emitUltrasonicBurst({
    required String rawPayload,
    required String nonce,
    required double amount,
  }) async {
    debugPrint('[AcousticCarrier] Emitting 18-22kHz FSK burst: Nonce $nonce, ₹$amount');

    try {
      await _methodChannel.invokeMethod('transmitAudio', {
        'payload': rawPayload,
        'mode': 'ultrasonic',
      });
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 200));

    final packet = AcousticPacket(
      frequencyKhz: 20.5,
      rawPayload: rawPayload,
      nonce: nonce,
      amount: amount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _soundWaveController.add(packet);
  }

  /// Vendor SoundBox / Peer emits Acoustic ACK back
  Future<void> emitAcousticAck({
    required String nonce,
    required bool isSuccess,
    String? txnId,
  }) async {
    debugPrint('[AcousticCarrier] Broadcasting Acoustic ACK tone: Nonce $nonce, Success: $isSuccess');

    final ackMsg = P2pMessage(
      type: isSuccess ? 'ACK' : 'NAK',
      txnId: txnId ?? 'ACK-$nonce',
      senderId: 'RECEIVER',
      recipientId: 'SENDER',
      amountPaise: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      nonce: nonce,
      signature: 'ACK-SIG',
      status: isSuccess ? 'OK' : 'REJECTED',
    );

    try {
      await _transmitAndWait(
        ackMsg.serialize(),
        _mode == AudioCarrierMode.ultrasonicFsk ? 'ultrasonic' : 'audible',
      );
    } on MissingPluginException {
      await Future.delayed(const Duration(milliseconds: 150));
      _acousticAckController.add(AcousticAck(
        nonce: nonce,
        isSuccess: isSuccess,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      _p2pMessageController.add(ackMsg);
    }
  }

  void _handleRawIncomingPayload(String rawPayload) {
    try {
      if (rawPayload.startsWith('CP1|') || rawPayload.startsWith('CP')) {
        final p2pMsg = P2pMessage.deserialize(rawPayload);
        _p2pMessageController.add(p2pMsg);

        if (p2pMsg.type == 'REQ') {
          _soundWaveController.add(AcousticPacket(
            frequencyKhz: _mode == AudioCarrierMode.ultrasonicFsk ? 20.5 : 2.0,
            rawPayload: p2pMsg.serialize(),
            nonce: p2pMsg.nonce,
            amount: p2pMsg.amountInRupees,
            timestamp: p2pMsg.timestamp,
          ));
        } else if (p2pMsg.type == 'ACK' || p2pMsg.type == 'NAK') {
          _acousticAckController.add(AcousticAck(
            nonce: p2pMsg.nonce,
            isSuccess: p2pMsg.type == 'ACK' && p2pMsg.status == 'OK',
            timestamp: p2pMsg.timestamp,
          ));
        }
      }
    } catch (e) {
      debugPrint('[AcousticCarrier] Corrupted frame received: $e');
      _statusController.add('Received frame rejected: $e');
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
  }
}

class AcousticPacket {
  final double frequencyKhz;
  final String rawPayload;
  final String nonce;
  final double amount;
  final int timestamp;

  AcousticPacket({
    required this.frequencyKhz,
    required this.rawPayload,
    required this.nonce,
    required this.amount,
    required this.timestamp,
  });
}

class AcousticAck {
  final String nonce;
  final bool isSuccess;
  final int timestamp;

  AcousticAck({
    required this.nonce,
    required this.isSuccess,
    required this.timestamp,
  });
}
