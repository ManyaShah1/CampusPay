import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/audio/acoustic_carrier.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/token_repository.dart';
import '../../data/repositories/wallet_repository.dart';

enum PaymentStep {
  idle,
  qrScanned,
  signingPayload,
  transmittingDualWaves,
  waitingAcousticAck,
  completed,
  failed,
}

class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final TokenRepository _tokenRepo = TokenRepository();
  final WalletRepository _walletRepo = WalletRepository();
  final AcousticCarrier _acoustic = AcousticCarrier();

  StreamSubscription? _ackSubscription;

  PaymentStep _currentStep = PaymentStep.idle;
  String _merchantId = 'MCH-CANTEEN-01';
  String _merchantName = 'DBIT Main Canteen';
  double _amount = 0.0;
  String? _errorMessage;
  PaymentExecutionResult? _lastResult;

  PaymentStep get currentStep => _currentStep;
  String get merchantId => _merchantId;
  String get merchantName => _merchantName;
  double get amount => _amount;
  String? get errorMessage => _errorMessage;
  PaymentExecutionResult? get lastResult => _lastResult;

  PaymentViewModel() {
    _initAckListener();
  }

  void _initAckListener() {
    _ackSubscription = _acoustic.onAcousticAckReceived.listen((ack) {
      if (_currentStep == PaymentStep.waitingAcousticAck && ack.isSuccess) {
        debugPrint('[PaymentVM] Acoustic ACK received successfully for Nonce: ${ack.nonce}');
        _currentStep = PaymentStep.completed;
        notifyListeners();
      }
    });
  }

  void selectMerchant({required String id, required String name}) {
    _merchantId = id;
    _merchantName = name;
    _currentStep = PaymentStep.qrScanned;
    notifyListeners();
  }

  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  Future<bool> initiateOfflinePayment() async {
    _errorMessage = null;

    // 1. Balance verification
    if (!_walletRepo.canAfford(_amount)) {
      _errorMessage = 'Insufficient campus wallet balance';
      _currentStep = PaymentStep.failed;
      notifyListeners();
      return false;
    }

    // 2. Token availability
    final token = _tokenRepo.getAvailableToken();
    if (token == null) {
      _errorMessage = 'No active offline tokens available. Please connect to Wi-Fi to refresh.';
      _currentStep = PaymentStep.failed;
      notifyListeners();
      return false;
    }

    if (_amount > token.maxAmount) {
      _errorMessage = 'Amount exceeds offline single-transaction limit of ₹${token.maxAmount}';
      _currentStep = PaymentStep.failed;
      notifyListeners();
      return false;
    }

    try {
      // Step 3: Amount + Payload Signing
      _currentStep = PaymentStep.signingPayload;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 4: Dual Transmission (Acoustic + BLE)
      _currentStep = PaymentStep.transmittingDualWaves;
      notifyListeners();

      final result = await _paymentRepo.executeOfflinePayment(
        merchantId: _merchantId,
        merchantName: _merchantName,
        amount: _amount,
        token: token,
      );

      _lastResult = result;

      // Step 5: Waiting for Acoustic ACK from SoundBox
      _currentStep = PaymentStep.waitingAcousticAck;
      notifyListeners();

      // Acoustic ACK fallback timer (3 seconds BLE fallback as per spec)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (_currentStep == PaymentStep.waitingAcousticAck) {
          _currentStep = PaymentStep.completed;
          notifyListeners();
        }
      });

      return true;
    } catch (e) {
      _errorMessage = 'Payment failed: ${e.toString()}';
      _currentStep = PaymentStep.failed;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _currentStep = PaymentStep.idle;
    _amount = 0.0;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ackSubscription?.cancel();
    super.dispose();
  }
}
