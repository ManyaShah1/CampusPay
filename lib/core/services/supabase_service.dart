import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/offline_token.dart';
import '../../data/models/transaction_record.dart';

/// Central Supabase service handling Auth, Cloud Ledger, and Realtime sync
class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isConfigured => client != null;

  static User? get currentUser => client?.auth.currentUser;

  static Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  // ── Authentication ──────────────────────────────────────────────────────────

  /// Sign up a student with email, password, student ID and full name
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase client is not initialized.');

    return await c.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'student_id': studentId,
      },
    );
  }

  /// Sign in existing student
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase client is not initialized.');

    return await c.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out current student
  static Future<void> signOut() async {
    await client?.auth.signOut();
  }

  // ── Wallet Operations ───────────────────────────────────────────────────────

  /// Fetch cloud wallet balance and coin balance
  static Future<Map<String, dynamic>?> getWallet() async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return null;

    try {
      final data = await c
          .from('wallets')
          .select()
          .eq('student_id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[SupabaseService] getWallet error: $e');
      return null;
    }
  }

  /// Update wallet balance after online transaction or Razorpay top-up
  static Future<bool> updateWalletBalance({
    required double newBalance,
    int? newCoinBalance,
  }) async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return false;

    try {
      final updateData = <String, dynamic>{
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newCoinBalance != null) {
        updateData['coin_balance'] = newCoinBalance;
      }

      await c.from('wallets').update(updateData).eq('student_id', user.id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] updateWalletBalance error: $e');
      return false;
    }
  }

  // ── Central Transactions Ledger Sync ───────────────────────────────────────

  /// Push a local transaction record to the central PostgreSQL ledger
  static Future<bool> syncTransaction(TransactionRecord txn) async {
    final c = client;
    if (c == null) return false;

    try {
      final wallet = await getWallet();
      final walletId = wallet?['id'];

      await c.from('transactions').upsert({
        'txn_id': txn.txnId,
        'wallet_id': ?walletId,
        'token_id': txn.tokenId,
        'merchant_id': txn.merchantId,
        'merchant_name': txn.merchantName,
        'amount': txn.amount,
        'channel': txn.channel.name,
        'sync_status': txn.syncStatus.name,
        'nonce': txn.nonce,
        'created_at': DateTime.fromMillisecondsSinceEpoch(txn.timestamp).toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] syncTransaction error: $e');
      return false;
    }
  }

  /// Fetch cloud transaction ledger history
  static Future<List<Map<String, dynamic>>> fetchTransactionHistory() async {
    final c = client;
    final user = currentUser;
    if (c == null || user == null) return [];

    try {
      final wallet = await getWallet();
      if (wallet == null) return [];

      final data = await c
          .from('transactions')
          .select()
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[SupabaseService] fetchTransactionHistory error: $e');
      return [];
    }
  }

  // ── Offline Tokens Sync ─────────────────────────────────────────────────────

  /// Sync local pre-authorized offline token batch with Supabase
  static Future<void> syncOfflineTokens(List<OfflineToken> tokens) async {
    final c = client;
    if (c == null) return;

    try {
      final wallet = await getWallet();
      if (wallet == null) return;

      final rows = tokens.map((t) => {
        'token_id': t.tokenId,
        'wallet_id': wallet['id'],
        'max_amount': t.maxAmount,
        'expiry_timestamp': t.expiryTimestamp,
        'server_signature': t.serverSignature,
        'is_used': t.isUsed,
        'used_at': t.usedAtTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(t.usedAtTimestamp!).toIso8601String()
            : null,
      }).toList();

      await c.from('offline_tokens').upsert(rows);
    } catch (e) {
      debugPrint('[SupabaseService] syncOfflineTokens error: $e');
    }
  }

  // ── Realtime Soundbox Subscription ──────────────────────────────────────────

  /// Listen for instant incoming transactions on a SoundBox merchant terminal
  static RealtimeChannel? subscribeToMerchantCredits({
    required String merchantId,
    required void Function(Map<String, dynamic> record) onCreditReceived,
  }) {
    final c = client;
    if (c == null) return null;

    try {
      final channel = c.channel('public:transactions:$merchantId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'merchant_id',
          value: merchantId,
        ),
        callback: (payload) {
          onCreditReceived(payload.newRecord);
        },
      ).subscribe();

      return channel;
    } catch (e) {
      debugPrint('[SupabaseService] subscribeToMerchantCredits error: $e');
      return null;
    }
  }
}
