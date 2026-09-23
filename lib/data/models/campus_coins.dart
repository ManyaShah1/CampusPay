/// CampusCoins loyalty logic and gamification system
class CampusCoinsState {
  final int totalCoins;
  final int streakDays;
  final int shopsVisitedToday;
  final List<CoinActivity> history;

  CampusCoinsState({
    required this.totalCoins,
    required this.streakDays,
    required this.shopsVisitedToday,
    required this.history,
  });

  /// Rupee value of current coin balance: 10 coins = ₹1 discount
  double get rupeeEquivalent => totalCoins / 10.0;

  CampusCoinsState copyWith({
    int? totalCoins,
    int? streakDays,
    int? shopsVisitedToday,
    List<CoinActivity>? history,
  }) {
    return CampusCoinsState(
      totalCoins: totalCoins ?? this.totalCoins,
      streakDays: streakDays ?? this.streakDays,
      shopsVisitedToday: shopsVisitedToday ?? this.shopsVisitedToday,
      history: history ?? this.history,
    );
  }
}

class CoinActivity {
  final String title;
  final int coinsDelta;
  final int timestamp;
  final bool isBonus;

  CoinActivity({
    required this.title,
    required this.coinsDelta,
    required this.timestamp,
    this.isBonus = false,
  });
}
