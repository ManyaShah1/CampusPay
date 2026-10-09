import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/ble/ble_p2p_transport.dart';
import '../../core/crypto/ecdsa_service.dart';
import '../../data/database/local_ledger_db.dart';
import '../../data/models/offline_token.dart';
import '../../data/models/transaction_record.dart';
import '../../data/repositories/token_repository.dart';

enum P2pState {
  idle,
  transmittingPayload,
  waitingPeerAck,
  committedSuccess,
  failed,
}

class P2pViewModel extends ChangeNotifier {
  final EcdsaService _ecdsa = EcdsaService();
  final LocalLedgerDb _db = LocalLedgerDb();
  final TokenRepository _tokenRepo = TokenRepository();
  final BleP2pTransport _bleTransport = BleP2pTransport();

  P2pState _state = P2pState.idle;
  double _amount = 150.0;
  String _peerName = 'Rohan Verma (SE-COMPS)';
  String? _statusMessage;
  TransactionRecord? _committedTransaction;

  P2pState get state => _state;
  double get amount => _amount;
  String get peerName => _peerName;
  String? get statusMessage => _statusMessage;
  TransactionRecord? get committedTransaction =>
      _committedTransaction;

  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void setPeerName(String name) {
    _peerName = name;
    notifyListeners();
  }

  Future<bool> sendP2pTransfer() async {
    try {
      if (_amount <= 0) {
        _state = P2pState.failed;
        _statusMessage = 'Enter a valid payment amount.';
        notifyListeners();
        return false;
      }

      // ------------------------------------------------------------
      // GET AN AVAILABLE OFFLINE TOKEN
      // ------------------------------------------------------------

      final OfflineToken? token =
          _tokenRepo.getAvailableToken();

      if (token == null) {
        _state = P2pState.failed;
        _statusMessage =
            'No valid offline payment token available.';
        notifyListeners();
        return false;
      }

      if (token.isExpired) {
        _state = P2pState.failed;
        _statusMessage =
            'Your offline payment token has expired.';
        notifyListeners();
        return false;
      }

      if (_amount > token.maxAmount) {
        _state = P2pState.failed;
        _statusMessage =
            'Amount exceeds the offline token limit of '
            '₹${token.maxAmount.toStringAsFixed(2)}.';
        notifyListeners();
        return false;
      }

      // ------------------------------------------------------------
      // CREATE SIGNED PAYMENT PAYLOAD
      // ------------------------------------------------------------

      final nonce = _ecdsa.generateNonce();
      final now = DateTime.now().millisecondsSinceEpoch;

      const merchantId = 'STU-ROHAN-4211';

      final paymentSignature =
          _ecdsa.signPayload(
        tokenId: token.tokenId,
        merchantId: merchantId,
        amount: _amount,
        timestamp: now,
        nonce: nonce,
      );

      final paymentData = <String, dynamic>{
        'token_id': token.tokenId,
        'wallet_id': token.walletId,
        'max_amount': token.maxAmount,
        'expiry_timestamp': token.expiryTimestamp,
        'server_signature': token.serverSignature,
        'amount': _amount,
        'merchant_id': merchantId,
        'merchant_name': _peerName,
        'timestamp': now,
        'nonce': nonce,
        'payment_signature': paymentSignature,
      };

      // ------------------------------------------------------------
      // BLE FALLBACK TRANSPORT
      //
      // The normal sound/ultrasonic flow remains the primary path.
      // This ViewModel is handling the BLE P2P fallback path.
      // ------------------------------------------------------------

      _state = P2pState.transmittingPayload;
      _statusMessage =
          'Sending offline payment token through BLE fallback...';
      notifyListeners();

      final bleSuccess =
          await _bleTransport.sendPayment(
        paymentData: paymentData,
      );

      if (!bleSuccess) {
        _state = P2pState.failed;
        _statusMessage =
            'BLE payment failed. No token was deducted.';
        notifyListeners();
        return false;
      }

      // ------------------------------------------------------------
      // ACK RECEIVED
      //
      // Only now is the payment committed.
      // ------------------------------------------------------------

      _state = P2pState.waitingPeerAck;
      _statusMessage =
          'Receiver acknowledged the offline payment.';
      notifyListeners();

      // ------------------------------------------------------------
      // MARK TOKEN AS USED
      // ------------------------------------------------------------

      _tokenRepo.markTokenUsed(token.tokenId);

      // ------------------------------------------------------------
      // RECORD TRANSACTION
      // ------------------------------------------------------------

      final txnId =
          'P2P-${const Uuid().v4().substring(0, 6).toUpperCase()}';

      final txn = TransactionRecord(
        txnId: txnId,
        tokenId: token.tokenId,
        merchantId: merchantId,
        merchantName: _peerName,
        amount: _amount,
        timestamp: now,
        channel: PaymentChannel.bleAdvert,
        status: TxnStatus.verified,
        syncStatus: SyncStatus.offlineUnsynced,
        nonce: nonce,
        isDebit: true,
      );

      _db.recordStudentDebit(txn);

      _committedTransaction = txn;

      _state = P2pState.committedSuccess;
      _statusMessage =
          'BLE ACK received. ₹${_amount.toStringAsFixed(2)} '
          'successfully sent using offline token.';

      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[P2P] Payment failed: $e',
      );

      debugPrint(
        '[P2P] Stack trace: $stackTrace',
      );

      _state = P2pState.failed;
      _statusMessage =
          'Payment failed. Your offline token was not deducted.';

      notifyListeners();

      return false;
    }
  }

  void reset() {
    _state = P2pState.idle;
    _statusMessage = null;
    _committedTransaction = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _bleTransport.dispose();
    super.dispose();
  }
}