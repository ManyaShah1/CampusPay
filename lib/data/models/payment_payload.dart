
import 'dart:convert';

/// Shared payment payload for CampusPay BLE.
/// Timestamps use milliseconds since the Unix epoch.
class PaymentPayload {
  final String tokenId;
  final String walletId;
  final String serverSignature;
  final String payerSignature;
  final String nonce;
  final String merchantId;
  final String merchantName;
  final double amount;
  final double maxAmount;
  final int expiryTimestamp;
  final int timestamp;

  PaymentPayload({
    required this.tokenId,
    required this.walletId,
    required this.serverSignature,
    required this.payerSignature,
    required this.nonce,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.maxAmount,
    required this.expiryTimestamp,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'token_id': tokenId,
        'wallet_id': walletId,
        'server_signature': serverSignature,
        'payment_signature': payerSignature,
        'nonce': nonce,
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'amount': amount,
        'max_amount': maxAmount,
        'expiry_timestamp': expiryTimestamp,
        'timestamp': timestamp,
      };

  String serialize() => jsonEncode(toMap());

  factory PaymentPayload.fromMap(Map<String, dynamic> map) {
    return PaymentPayload(
      tokenId: map['token_id'] as String,
      walletId: map['wallet_id'] as String,
      serverSignature: map['server_signature'] as String,
      payerSignature: map['payment_signature'] as String,
      nonce: map['nonce'] as String,
      merchantId: map['merchant_id'] as String,
      merchantName: map['merchant_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      maxAmount: (map['max_amount'] as num).toDouble(),
      expiryTimestamp: (map['expiry_timestamp'] as num).toInt(),
      timestamp: (map['timestamp'] as num).toInt(),
    );
  }

  factory PaymentPayload.deserialize(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map) {
      throw const FormatException(
        'Payment payload must be a JSON object.',
      );
    }

    return PaymentPayload.fromMap(
      Map<String, dynamic>.from(decoded),
    );
  }
}
