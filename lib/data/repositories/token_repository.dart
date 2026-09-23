import '../database/local_ledger_db.dart';
import '../models/offline_token.dart';

/// Repository managing pre-authorized offline tokens
class TokenRepository {
  final LocalLedgerDb _db = LocalLedgerDb();

  List<OfflineToken> getAllTokens() {
    return _db.getTokens();
  }

  OfflineToken? getAvailableToken() {
    return _db.getAvailableToken();
  }

  void markTokenUsed(String tokenId) {
    _db.markTokenUsed(tokenId);
  }

  void replenishTokens() {
    _db.replenishTokens();
  }

  int get activeTokenCount {
    return _db.getTokens().where((t) => !t.isUsed && !t.isExpired).length;
  }
}
