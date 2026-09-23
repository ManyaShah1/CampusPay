import '../database/local_ledger_db.dart';
import '../models/transaction_record.dart';

/// Repository managing balance, top-ups, and local ledger debits
class WalletRepository {
  final LocalLedgerDb _db = LocalLedgerDb();

  double getBalance() {
    return _db.getDecryptedBalance();
  }

  void topUpWallet(double amount) {
    final current = _db.getDecryptedBalance();
    _db.updateBalance(current + amount);
  }

  bool canAfford(double amount) {
    return _db.getDecryptedBalance() >= amount;
  }

  void deductBalance(double amount) {
    final current = _db.getDecryptedBalance();
    if (current >= amount) {
      _db.updateBalance(current - amount);
    }
  }

  List<TransactionRecord> getTransactions() {
    return _db.getStudentTransactions();
  }

  int reconcileWithServer() {
    return _db.reconcileAllTransactions();
  }
}
