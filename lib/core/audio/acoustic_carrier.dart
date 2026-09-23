import 'dart:async';
import 'package:flutter/foundation.dart';

/// Acoustic ultrasonic FSK carrier & acoustic ACK transmission protocol
class AcousticCarrier {
  static final AcousticCarrier _instance = AcousticCarrier._internal();
  factory AcousticCarrier() => _instance;

  AcousticCarrier._internal();

  // Broadcast stream for SoundBox receivers listening to ultrasonic bursts
  final _soundWaveController = StreamController<AcousticPacket>.broadcast();
  Stream<AcousticPacket> get onUltrasonicPacketReceived => _soundWaveController.stream;

  // Broadcast stream for Student Phones listening to acoustic ACKs
  final _acousticAckController = StreamController<AcousticAck>.broadcast();
  Stream<AcousticAck> get onAcousticAckReceived => _acousticAckController.stream;

  /// Emits an 18–22kHz FSK acoustic burst carrying serialized payment payload
  Future<void> emitUltrasonicBurst({
    required String rawPayload,
    required String nonce,
    required double amount,
  }) async {
    debugPrint('[AcousticCarrier] Emitting 18-22kHz FSK burst: Nonce $nonce, ₹$amount');

    // Simulate ultrasonic carrier airgap propagation (approx 150-250ms)
    await Future.delayed(const Duration(milliseconds: 200));

    final packet = AcousticPacket(
      frequencyKhz: 20.5, // Center frequency
      rawPayload: rawPayload,
      nonce: nonce,
      amount: amount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _soundWaveController.add(packet);
  }

  /// Vendor SoundBox emits high-frequency Acoustic ACK back to student device
  Future<void> emitAcousticAck({
    required String nonce,
    required bool isSuccess,
  }) async {
    debugPrint('[AcousticCarrier] SoundBox broadcasting Acoustic ACK tone: Nonce $nonce, Success: $isSuccess');

    await Future.delayed(const Duration(milliseconds: 100));

    _acousticAckController.add(AcousticAck(
      nonce: nonce,
      isSuccess: isSuccess,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
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
