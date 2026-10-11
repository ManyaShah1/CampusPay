import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Service managing Razorpay checkout lifecycle for Campus Wallet top-ups.
class RazorpayService {
  late final Razorpay _razorpay;
  String keyId;
  String keySecret;

  void Function(PaymentSuccessResponse response, double amount)? onSuccess;
  void Function(PaymentFailureResponse response)? onFailure;
  void Function(ExternalWalletResponse response)? onExternalWallet;

  double _pendingAmount = 0.0;

  static String _safeGetEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key] ?? '';
      }
    } catch (_) {}
    return '';
  }

  RazorpayService({
    String? keyId,
    String? keySecret,
  })  : keyId = keyId ?? _safeGetEnv('RAZORPAY_KEY_ID'),
        keySecret = keySecret ?? _safeGetEnv('RAZORPAY_KEY_SECRET') {
    _initRazorpay();
  }

  void updateCredentials({required String newKeyId, required String newKeySecret}) {
    keyId = newKeyId;
    keySecret = newKeySecret;
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint(
      '[RazorpayService] Payment Successful: ${response.paymentId}, order: ${response.orderId}',
    );
    onSuccess?.call(response, _pendingAmount);
    _pendingAmount = 0.0;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      '[RazorpayService] Payment Error: ${response.code} - ${response.message}',
    );
    onFailure?.call(response);
    _pendingAmount = 0.0;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint(
      '[RazorpayService] External Wallet Selected: ${response.walletName}',
    );
    onExternalWallet?.call(response);
  }

  /// Automatically creates a real server-side order with Razorpay Orders API
  Future<String?> createOrder(double amount) async {
    final missingCredentials = <String>[
      if (keyId.trim().isEmpty) 'RAZORPAY_KEY_ID',
      if (keySecret.trim().isEmpty) 'RAZORPAY_KEY_SECRET',
    ];
    if (missingCredentials.isNotEmpty) {
      debugPrint(
        '[RazorpayService] Order creation unavailable. Configure ${missingCredentials.join(' and ')}.',
      );
      return null;
    }

    try {
      final amountInPaise = (amount * 100).round();
      final authHeader =
          'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': 'INR',
          'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data['id'] as String?;
        debugPrint('[RazorpayService] Order created successfully: $orderId');
        return orderId;
      } else {
        debugPrint(
          '[RazorpayService] Order creation failed (${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[RazorpayService] Order creation error: $e');
      return null;
    }
  }

  /// Opens the Razorpay checkout overlay.
  /// [amount] is in Indian Rupees (INR).
  Future<void> openCheckout({
    required double amount,
    String studentName = 'Manya Shah',
    String studentEmail = 'manya.shah@dbit.ac.in',
    String studentContact = '9876543210',
    String? orderId,
  }) async {
    if (keyId.trim().isEmpty) {
      throw StateError(
        'Razorpay is not configured: set RAZORPAY_KEY_ID before checkout.',
      );
    }
    if ((orderId == null || orderId.isEmpty) && keySecret.trim().isEmpty) {
      throw StateError(
        'Razorpay order creation is not configured: set RAZORPAY_KEY_SECRET.',
      );
    }

    _pendingAmount = amount;
    final int amountInPaise = (amount * 100).round();

    // Auto-create official Razorpay order if not supplied
    String? resolvedOrderId = orderId;
    if (resolvedOrderId == null || resolvedOrderId.isEmpty) {
      resolvedOrderId = await createOrder(amount);
    }

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountInPaise,
      'name': 'CampusPay DBIT',
      'description': 'Campus Wallet Top-up (₹${amount.toStringAsFixed(0)})',
      'currency': 'INR',
      'prefill': {
        'contact': studentContact,
        'email': studentEmail,
        'name': studentName,
      },
      'theme': {
        'color': '#FFFF00', // Neon Electric Yellow accent matching CampusPay theme
      },
      'send_sms_hash': true,
      'external': {
        'wallets': ['paytm'],
      },
    };

    if (resolvedOrderId != null && resolvedOrderId.isNotEmpty) {
      options['order_id'] = resolvedOrderId;
    }

    if (kIsWeb) {
      debugPrint(
        '[RazorpayService] Running on Web. Simulating payment so testing works seamlessly.',
      );
      // Simulate payment on web browser so testing wallet top-up works seamlessly
      Future.delayed(const Duration(milliseconds: 1200), () {
        final mockResponse = PaymentSuccessResponse(
          'pay_test_web_${DateTime.now().millisecondsSinceEpoch}',
          resolvedOrderId ?? 'order_test_mock',
          'sig_mock_web',
          const {},
        );
        _handlePaymentSuccess(mockResponse);
      });
      return;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('[RazorpayService] Failed to open Razorpay checkout: $e');
      rethrow;
    }
  }

  /// Cleans up event listeners and native instances.
  void dispose() {
    _razorpay.clear();
  }
}
