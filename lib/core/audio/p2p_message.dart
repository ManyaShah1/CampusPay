import 'dart:convert';

/// Versioned P2P Sound-Wave Protocol Message
class P2pMessage {
  final int version; // e.g. 1
  final String type; // 'REQ', 'ACK', 'NAK'
  final String txnId; // Transfer ID e.g. 'P2P-8F3A21'
  final String senderId; // Sender identifier/name
  final String recipientId; // Recipient identifier/name
  final int amountPaise; // Amount in paise (e.g. ₹150.00 = 15000 paise)
  final int timestamp; // Timestamp in epoch milliseconds
  final String nonce; // Replay prevention UUID nonce
  final String signature; // ECDSA / HMAC authentication signature
  final String status; // 'OK', 'REPLAY_ATTACK_DETECTED', 'INVALID_SIGNATURE', etc.
  final int crc16; // 16-bit CRC checksum for audio frame integrity

  double get amountInRupees => amountPaise / 100.0;

  P2pMessage({
    this.version = 1,
    required this.type,
    required this.txnId,
    required this.senderId,
    required this.recipientId,
    required this.amountPaise,
    required this.timestamp,
    required this.nonce,
    required this.signature,
    this.status = 'OK',
    int? crc16,
  }) : crc16 = crc16 ?? _computeChecksum(version, type, txnId, senderId, recipientId, amountPaise, timestamp, nonce, signature, status);

  /// Compute 16-bit CRC checksum (CRC-16-IBM) over message fields
  static int _computeChecksum(
    int version,
    String type,
    String txnId,
    String senderId,
    String recipientId,
    int amountPaise,
    int timestamp,
    String nonce,
    String signature,
    String status,
  ) {
    final body = 'CP$version|$type|$txnId|$senderId|$recipientId|$amountPaise|$timestamp|$nonce|$signature|$status';
    final bytes = utf8.encode(body);
    int crc = 0xFFFF;
    for (var b in bytes) {
      crc ^= (b & 0xFF);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  /// Serialize message into sound-wave transmission frame string
  String serialize() {
    final body = 'CP$version|$type|$txnId|$senderId|$recipientId|$amountPaise|$timestamp|$nonce|$signature|$status';
    final crcHex = crc16.toRadixString(16).padLeft(4, '0').toUpperCase();
    return '$body|$crcHex';
  }

  /// Deserialize sound-wave frame string into P2pMessage, verifying CRC checksum
  factory P2pMessage.deserialize(String rawFrame) {
    final trimmed = rawFrame.trim();
    if (!trimmed.startsWith('CP1|') && !trimmed.startsWith('CP')) {
      throw FormatException('INVALID_PROTOCOL_PREFIX: Frame must start with CP version header');
    }

    final parts = trimmed.split('|');
    if (parts.length < 11) {
      throw FormatException('MALFORMED_FRAME_LENGTH: Expected 11 frame fields, got ${parts.length}');
    }

    final header = parts[0];
    final version = int.tryParse(header.replaceAll('CP', '')) ?? 1;
    final type = parts[1];
    final txnId = parts[2];
    final senderId = parts[3];
    final recipientId = parts[4];
    final amountPaise = int.tryParse(parts[5]) ?? 0;
    final timestamp = int.tryParse(parts[6]) ?? DateTime.now().millisecondsSinceEpoch;
    final nonce = parts[7];
    final signature = parts[8];
    final status = parts[9];
    final crcHexReceived = parts[10];

    final expectedCrc = _computeChecksum(
      version,
      type,
      txnId,
      senderId,
      recipientId,
      amountPaise,
      timestamp,
      nonce,
      signature,
      status,
    );

    final receivedCrc = int.tryParse(crcHexReceived, radix: 16) ?? -1;
    if (expectedCrc != receivedCrc) {
      throw FormatException(
        'CRC16_CHECKSUM_MISMATCH: Frame corrupted during sound-wave airgap transmission (expected 0x${expectedCrc.toRadixString(16)}, got 0x$crcHexReceived)',
      );
    }

    return P2pMessage(
      version: version,
      type: type,
      txnId: txnId,
      senderId: senderId,
      recipientId: recipientId,
      amountPaise: amountPaise,
      timestamp: timestamp,
      nonce: nonce,
      signature: signature,
      status: status,
      crc16: expectedCrc,
    );
  }
}
