enum TokenStatus { active, used, expired, settled }

/// Pre-authorized offline ECDSA cryptographic token
class OfflineToken {
  final String tokenId;
  final String walletId;
  final double maxAmount;
  final int expiryTimestamp; // 48-hour epoch
  final String serverSignature;
  bool isUsed;
  int? usedAtTimestamp;
  TokenStatus status;

  OfflineToken({
    required this.tokenId,
    required this.walletId,
    required this.maxAmount,
    required this.expiryTimestamp,
    required this.serverSignature,
    this.isUsed = false,
    this.usedAtTimestamp,
    this.status = TokenStatus.active,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiryTimestamp;

  int get remainingSeconds {
    final diff = expiryTimestamp - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? (diff / 1000).round() : 0;
  }

  String get remainingTimeFormatted {
    final sec = remainingSeconds;
    if (sec <= 0) return 'EXPIRED';
    final hours = sec ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    return '${hours}h ${minutes}m left';
  }

  Map<String, dynamic> toJson() => {
    'token_id': tokenId,
    'wallet_id': walletId,
    'max_amount': maxAmount,
    'expiry_timestamp': expiryTimestamp,
    'server_signature': serverSignature,
    'is_used': isUsed,
    'used_at_timestamp': usedAtTimestamp,
    'status': status.name,
  };

  factory OfflineToken.fromJson(Map<String, dynamic> json) => OfflineToken(
    tokenId: json['token_id'] as String,
    walletId: json['wallet_id'] as String,
    maxAmount: (json['max_amount'] as num).toDouble(),
    expiryTimestamp: json['expiry_timestamp'] as int,
    serverSignature: json['server_signature'] as String,
    isUsed: json['is_used'] as bool? ?? false,
    usedAtTimestamp: json['used_at_timestamp'] as int?,
    status: TokenStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TokenStatus.active,
    ),
  );
}
