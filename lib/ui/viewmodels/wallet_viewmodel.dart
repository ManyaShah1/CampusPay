import 'package:flutter/foundation.dart';
import '../../data/models/campus_coins.dart';
import '../../data/models/offline_token.dart';
import '../../data/models/transaction_record.dart';
import '../../data/repositories/token_repository.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletViewModel extends ChangeNotifier {
  final WalletRepository _walletRepo = WalletRepository();
  final TokenRepository _tokenRepo = TokenRepository();

  double _balance = 0.0;
  List<TransactionRecord> _transactions = [];
  List<OfflineToken> _tokens = [];
  CampusCoinsState _coinsState = CampusCoinsState(
    totalCoins: 240,
    streakDays: 4,
    shopsVisitedToday: 2,
    history: [
      CoinActivity(title: 'Canteen Lunch', coinsDelta: 16, timestamp: DateTime.now().millisecondsSinceEpoch - 7200000),
      CoinActivity(title: 'Stationery Xerox', coinsDelta: 6, timestamp: DateTime.now().millisecondsSinceEpoch - 18000000),
      CoinActivity(title: '3-Shop Daily Bonus', coinsDelta: 20, timestamp: DateTime.now().millisecondsSinceEpoch - 86400000, isBonus: true),
    ],
  );

  bool _isOnline = true;
  bool _isSyncing = false;

  double get balance => _balance;
  List<TransactionRecord> get transactions => _transactions;
  List<OfflineToken> get tokens => _tokens;
  CampusCoinsState get coinsState => _coinsState;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  int get availableTokenCount => _tokens.where((t) => !t.isUsed && !t.isExpired).length;
  int get unspentTokenCount => availableTokenCount;

  WalletViewModel() {
    refresh();
  }

  void refresh() {
    _balance = _walletRepo.getBalance();
    _transactions = _walletRepo.getTransactions();
    _tokens = _tokenRepo.getAllTokens();
    notifyListeners();
  }

  void toggleNetworkStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void topUpWallet(double amount) {
    _walletRepo.topUpWallet(amount);
    refresh();
  }

  void addFunds(double amount) => topUpWallet(amount);

  void deductOffline(double amount, {String merchant = 'Campus Café'}) {
    _balance = (_balance - amount).clamp(0.0, double.infinity);
    awardCoins((amount * 0.1).toInt(), merchant);
    refresh();
  }

  void redeemPerk(int coinsCost, String perkName) {
    if (_coinsState.totalCoins >= coinsCost) {
      _coinsState = _coinsState.copyWith(
        totalCoins: _coinsState.totalCoins - coinsCost,
        history: List<CoinActivity>.from(_coinsState.history)
          ..insert(0, CoinActivity(
            title: 'Redeemed: $perkName',
            coinsDelta: -coinsCost,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          )),
      );
      notifyListeners();
    }
  }

  void awardCoins(int delta, String reason) {
    final updatedList = List<CoinActivity>.from(_coinsState.history)
      ..insert(0, CoinActivity(
        title: reason,
        coinsDelta: delta,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));

    _coinsState = _coinsState.copyWith(
      totalCoins: _coinsState.totalCoins + delta,
      history: updatedList,
    );
    notifyListeners();
  }

  Future<int> syncLedger() async {
    _isSyncing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));
    final count = _walletRepo.reconcileWithServer();

    _isSyncing = false;
    refresh();
    return count;
  }

  void replenishTokens() {
    _tokenRepo.replenishTokens();
    refresh();
  }
}
