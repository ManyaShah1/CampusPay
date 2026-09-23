import 'dart:convert';

/// Cryptographic signed payment payload transmitted via airgap carriers
class PaymentPayload {
  final String tokenId;
  final String merchantId;
  final double amount;
  final int timestamp;
  final String nonce;
  final String payerSignature;
  final String payerName;
  final int tokenExpiry;

  PaymentPayload({
    required this.tokenId,
    required this.merchantId,
    required this.amount,
    required this.timestamp,
    required this.nonce,
    required this.payerSignature,
    required this.payerName,
    required this.tokenExpiry,
  });

  Map<String, dynamic> toMap() => {
    'token_id': tokenId,
    'merchant_id': merchantId,
    'amount': amount,
    'timestamp': timestamp,
    'nonce': nonce,
    'payer_signature': payerSignature,
    'payer_name': payerName,
    'token_expiry': tokenExpiry,
  };

  String serialize() => jsonEncode(toMap());

  factory PaymentPayload.fromMap(Map<String, dynamic> map) => PaymentPayload(
    tokenId: map['token_id'] as String,
    merchantId: map['merchant_id'] as String,
    amount: (map['amount'] as num).toDouble(),
    timestamp: map['timestamp'] as int,
    nonce: map['nonce'] as String,
    payerSignature: map['payer_signature'] as String,
    payerName: map['payer_name'] as String? ?? 'DBIT Student',
    tokenExpiry: map['token_expiry'] as int? ?? (DateTime.now().millisecondsSinceEpoch + 172800000),
  );

  factory PaymentPayload.deserialize(String jsonString) =>
      PaymentPayload.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
}
