import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for loading environment variables from `.env` asset file
class EnvService {
  static String razorpayKeyId = '';
  static String razorpayKeySecret = '';
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  /// Load `.env` from app assets or fallback
  static Future<void> load() async {
    try {
      final content = await rootBundle.loadString('.env');
      final lines = content.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx != -1) {
          final key = line.substring(0, idx).trim();
          final val = line.substring(idx + 1).trim();
          if (key == 'RAZORPAY_KEY_ID' && val.isNotEmpty) {
            razorpayKeyId = val;
          } else if (key == 'RAZORPAY_KEY_SECRET' && val.isNotEmpty) {
            razorpayKeySecret = val;
          } else if (key == 'SUPABASE_URL' && val.isNotEmpty) {
            supabaseUrl = val;
          } else if (key == 'SUPABASE_ANON_KEY' && val.isNotEmpty) {
            supabaseAnonKey = val;
          }
        }
      }
      debugPrint('[EnvService] Loaded Razorpay Key ID: $razorpayKeyId');
      debugPrint('[EnvService] Loaded Supabase URL: $supabaseUrl');
    } catch (e) {
      debugPrint('[EnvService] .env asset load fallback: $e');
    }
  }
}
