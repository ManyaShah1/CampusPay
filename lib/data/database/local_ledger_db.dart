import 'package:uuid/uuid.dart';
import '../../core/crypto/aes_vault.dart';
import '../../core/crypto/ecdsa_service.dart';
import '../models/offline_token.dart';
import '../models/transaction_record.dart';

/// In-memory and persistent reactive Local Ledger for offline operations
class LocalLedgerDb {
  static final LocalLedgerDb _instance = LocalLedgerDb._internal();
  factory LocalLedgerDb() => _instance;

  final AesVault _vault = AesVault();
  final EcdsaService _ecdsa = EcdsaService();

  // Local state
  late String _encryptedBalance;
  final List<OfflineToken> _tokens = [];
  final List<TransactionRecord> _studentTransactions = [];
  final List<TransactionRecord> _soundboxTransactions = [];

  LocalLedgerDb._internal() {
    _initializeInitialState();
  }

  void _initializeInitialState() {
    // Initial student wallet balance: ₹0.00 encrypted with AES-256
    _encryptedBalance = _vault.encrypt('0.00');

    // Generate batch of 10 pre-authorized ECDSA tokens (48hr validity)
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry48h = now + (48 * 60 * 60 * 1000);

    for (int i = 1; i <= 10; i++) {
      final tokenId = 'TK-DBIT-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      final sig = _ecdsa.signTokenByServer(
        tokenId: tokenId,
        walletId: 'WLT-STUDENT-7042',
        maxAmount: 500.0,
        expiry: expiry48h,
      );

      _tokens.add(
        OfflineToken(
          tokenId: tokenId,
          walletId: 'WLT-STUDENT-7042',
          maxAmount: 500.0,
          expiryTimestamp: expiry48h,
          serverSignature: sig,
          isUsed: i > 8, // Tokens 9 & 10 marked previously used for realism
          usedAtTimestamp: i > 8 ? (now - 3600000 * (i - 7)) : null,
          status: i > 8 ? TokenStatus.used : TokenStatus.active,
        ),
      );
    }

    // Seed prior student debit transactions
    _studentTransactions.addAll([
      TransactionRecord(
        txnId: 'TXN-08912',
        tokenId: _tokens[8].tokenId,
        merchantId: 'MCH-CANTEEN-01',
        merchantName: 'DBIT Main Canteen',
        amount: 80.0,
        timestamp: now - 7200000,
        channel: PaymentChannel.ultrasonicFsk,
        status: TxnStatus.verified,
        syncStatus: SyncStatus.reconciled,
        nonce: const Uuid().v4(),
      ),
      TransactionRecord(
        txnId: 'TXN-08734',
        tokenId: _tokens[9].tokenId,
        merchantId: 'MCH-XEROX-02',
        merchantName: 'Campus Stationery & Xerox',
        amount: 35.0,
        timestamp: now - 18000000,
        channel: PaymentChannel.bleAdvert,
        status: TxnStatus.verified,
        syncStatus: SyncStatus.reconciled,
        nonce: const Uuid().v4(),
      ),
    ]);

    // Seed prior SoundBox credit transactions for DBIT Main Canteen
    _soundboxTransactions.add(
      TransactionRecord(
        txnId: 'TXN-08912',
        tokenId: _tokens[8].tokenId,
        merchantId: 'MCH-CANTEEN-01',
        merchantName: 'Aarav Sharma (TE-IT)',
        amount: 80.0,
        timestamp: now - 7200000,
        channel: PaymentChannel.ultrasonicFsk,
        status: TxnStatus.verified,
        syncStatus: SyncStatus.reconciled,
        nonce: _studentTransactions.first.nonce,
        isDebit: false,
      ),
    );
  }

  // Wallet operations
  double getDecryptedBalance() {
    try {
      final str = _vault.decrypt(_encryptedBalance);
      return double.tryParse(str) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  void updateBalance(double newBalance) {
    _encryptedBalance = _vault.encrypt(newBalance.toStringAsFixed(2));
  }

  // Token operations
  List<OfflineToken> getTokens() => List.unmodifiable(_tokens);

  OfflineToken? getAvailableToken() {
    return _tokens.cast<OfflineToken?>().firstWhere(
      (t) => t != null && !t.isUsed && !t.isExpired,
      orElse: () => null,
    );
  }

  void markTokenUsed(String tokenId) {
    final idx = _tokens.indexWhere((t) => t.tokenId == tokenId);
    if (idx != -1) {
      _tokens[idx].isUsed = true;
      _tokens[idx].usedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
      _tokens[idx].status = TokenStatus.used;
    }
  }

  void replenishTokens() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry48h = now + (48 * 60 * 60 * 1000);
    _tokens.clear();
    for (int i = 1; i <= 10; i++) {
      final tokenId = 'TK-DBIT-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      final sig = _ecdsa.signTokenByServer(
        tokenId: tokenId,
        walletId: 'WLT-STUDENT-7042',
        maxAmount: 500.0,
        expiry: expiry48h,
      );
      _tokens.add(
        OfflineToken(
          tokenId: tokenId,
          walletId: 'WLT-STUDENT-7042',
          maxAmount: 500.0,
          expiryTimestamp: expiry48h,
          serverSignature: sig,
        ),
      );
    }
  }

  // Ledger operations
  List<TransactionRecord> getStudentTransactions() => List.unmodifiable(_studentTransactions);
  List<TransactionRecord> getSoundboxTransactions() => List.unmodifiable(_soundboxTransactions);

  void recordStudentDebit(TransactionRecord txn) {
    _studentTransactions.insert(0, txn);
  }

  void recordSoundboxCredit(TransactionRecord txn) {
    _soundboxTransactions.insert(0, txn);
  }

  /// Mark all unsynced transactions as RECONCILED with server
  int reconcileAllTransactions() {
    int reconciledCount = 0;
    for (int i = 0; i < _studentTransactions.length; i++) {
      if (_studentTransactions[i].syncStatus == SyncStatus.offlineUnsynced) {
        _studentTransactions[i] = TransactionRecord(
          txnId: _studentTransactions[i].txnId,
          tokenId: _studentTransactions[i].tokenId,
          merchantId: _studentTransactions[i].merchantId,
          merchantName: _studentTransactions[i].merchantName,
          amount: _studentTransactions[i].amount,
          timestamp: _studentTransactions[i].timestamp,
          channel: _studentTransactions[i].channel,
          status: TxnStatus.settled,
          syncStatus: SyncStatus.reconciled,
          nonce: _studentTransactions[i].nonce,
          isDebit: true,
        );
        reconciledCount++;
      }
    }
    return reconciledCount;
  }
}
