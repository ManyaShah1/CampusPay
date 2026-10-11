import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for loading environment variables from `.env` asset file
class EnvService {
  static String razorpayKeyId = 'rzp_test_TlXNu2KYBa3OOl';
  static String razorpayKeySecret = 'zL3Jn5drnq9xyl2q3PER39Ll';

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
          }
        }
      }
      debugPrint('[EnvService] Loaded Razorpay Key ID: $razorpayKeyId');
    } catch (e) {
      debugPrint('[EnvService] .env asset load fallback: $e');
    }
  }
}
