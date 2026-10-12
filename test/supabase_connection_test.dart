import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Verify Supabase connection and tables with publishable key', () async {
    const url = 'https://gdusxtvciikdhhshavlt.supabase.co';
    const anonKey = 'sb_publishable_23N5UzQB3B11k1fe9M6pdw_jh_kRD0T';

    final client = SupabaseClient(url, anonKey);

    // 1. Query profiles table
    final profiles = await client.from('profiles').select();
    expect(profiles, isA<List>());

    // 2. Query wallets table
    final wallets = await client.from('wallets').select();
    expect(wallets, isA<List>());

    // 3. Query transactions table
    final transactions = await client.from('transactions').select();
    expect(transactions, isA<List>());

    // 4. Query offline_tokens table
    final tokens = await client.from('offline_tokens').select();
    expect(tokens, isA<List>());
  });
}
