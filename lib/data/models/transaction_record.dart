enum PaymentChannel {
  ultrasonicFsk,
  bleAdvert,
  ussdSilent,
  onlineUpi,
  p2pAcoustic,
}

enum TxnStatus {
  pending,
  verified,
  settled,
  failed,
}

enum SyncStatus {
  offlineUnsynced,
  reconciled,
}

/// Local ledger transaction record
class TransactionRecord {
  final String txnId;
  final String tokenId;
  final String merchantId;
  final String merchantName;
  final double amount;
  final int timestamp;
  final PaymentChannel channel;
  final TxnStatus status;
  final SyncStatus syncStatus;
  final String nonce;
  final bool isDebit; // true for student debit, false for merchant/soundbox credit

  TransactionRecord({
    required this.txnId,
    required this.tokenId,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.timestamp,
    required this.channel,
    required this.status,
    required this.syncStatus,
    required this.nonce,
    this.isDebit = true,
  });

  String get channelDisplayName {
    switch (channel) {
      case PaymentChannel.ultrasonicFsk:
        return '18–22kHz Ultrasonic FSK';
      case PaymentChannel.bleAdvert:
        return 'BLE Broadcast (Fallback)';
      case PaymentChannel.ussdSilent:
        return 'Silent *99# USSD';
      case PaymentChannel.onlineUpi:
        return 'Online UPI (Razorpay)';
      case PaymentChannel.p2pAcoustic:
        return 'P2P Acoustic ACK';
    }
  }

  Map<String, dynamic> toJson() => {
    'txn_id': txnId,
    'token_id': tokenId,
    'merchant_id': merchantId,
    'merchant_name': merchantName,
    'amount': amount,
    'timestamp': timestamp,
    'channel': channel.name,
    'status': status.name,
    'sync_status': syncStatus.name,
    'nonce': nonce,
    'is_debit': isDebit,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) => TransactionRecord(
    txnId: json['txn_id'] as String,
    tokenId: json['token_id'] as String,
    merchantId: json['merchant_id'] as String,
    merchantName: json['merchant_name'] as String,
    amount: (json['amount'] as num).toDouble(),
    timestamp: json['timestamp'] as int,
    channel: PaymentChannel.values.firstWhere(
      (e) => e.name == json['channel'],
      orElse: () => PaymentChannel.ultrasonicFsk,
    ),
    status: TxnStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TxnStatus.verified,
    ),
    syncStatus: SyncStatus.values.firstWhere(
      (e) => e.name == json['sync_status'],
      orElse: () => SyncStatus.offlineUnsynced,
    ),
    nonce: json['nonce'] as String,
    isDebit: json['is_debit'] as bool? ?? true,
  );
}
