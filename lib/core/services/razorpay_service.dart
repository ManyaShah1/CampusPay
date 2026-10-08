import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Service managing Razorpay checkout lifecycle for Campus Wallet top-ups.
class RazorpayService {
  late final Razorpay _razorpay;
  String keyId;

  void Function(PaymentSuccessResponse response, double amount)? onSuccess;
  void Function(PaymentFailureResponse response)? onFailure;
  void Function(ExternalWalletResponse response)? onExternalWallet;

  double _pendingAmount = 0.0;

  RazorpayService({
    this.keyId = 'rzp_test_1DP5mmOlF5G5ag', // Default test key ID
  }) {
    _initRazorpay();
  }

  void updateKeyId(String newKeyId) {
    keyId = newKeyId;
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

  /// Opens the Razorpay checkout overlay.
  /// [amount] is in Indian Rupees (INR). Converted to paise internally.
  void openCheckout({
    required double amount,
    String studentName = 'Manya Shah',
    String studentEmail = 'manya.shah@dbit.ac.in',
    String studentContact = '9876543210',
    String? orderId,
  }) {
    _pendingAmount = amount;
    final int amountInPaise = (amount * 100).round();

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

    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
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
