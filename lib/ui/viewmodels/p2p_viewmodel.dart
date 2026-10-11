import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/audio/acoustic_carrier.dart';
import '../../core/audio/p2p_message.dart';
import '../../core/ble/ble_p2p_transport.dart';
import '../../core/crypto/ecdsa_service.dart';
import '../../data/database/local_ledger_db.dart';
import '../../data/models/offline_token.dart';
import '../../data/models/transaction_record.dart';
import '../../data/repositories/token_repository.dart';

enum P2pState {
  idle,
  listening,
  transmittingPayload,
  waitingPeerAck,
  retrying,
  committedSuccess,
  failed,
}

enum P2pRole {
  sender,
  receiver,
}

class P2pViewModel extends ChangeNotifier {
  final EcdsaService _ecdsa = EcdsaService();
  final LocalLedgerDb _db = LocalLedgerDb();
  final TokenRepository _tokenRepo = TokenRepository();
  final BleP2pTransport _bleTransport = BleP2pTransport();
  final AcousticCarrier _acoustic = AcousticCarrier();

  P2pState _state = P2pState.idle;
  P2pRole _activeRole = P2pRole.sender;
  AudioCarrierMode _carrierMode = AudioCarrierMode.audibleFsk;

  double _amount = 150.0;
  String _peerName = 'Rohan Verma (SE-COMPS)';
  String _currentUserId = 'Aarav Sharma (TE-IT)';
  String? _statusMessage;
  TransactionRecord? _committedTransaction;
  P2pMessage? _lastReceivedP2pMessage;

  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _ackTimeoutTimer;
  StreamSubscription? _p2pSubscription;
  StreamSubscription? _audioStatusSubscription;

  P2pState get state => _state;
  P2pRole get activeRole => _activeRole;
  AudioCarrierMode get carrierMode => _carrierMode;
  double get amount => _amount;
  String get peerName => _peerName;
  String get currentUserId => _currentUserId;
  String? get statusMessage => _statusMessage;
  TransactionRecord? get committedTransaction => _committedTransaction;
  P2pMessage? get lastReceivedP2pMessage => _lastReceivedP2pMessage;
  int get retryCount => _retryCount;
  int get maxRetries => _maxRetries;

  P2pViewModel() {
    _initP2pMessageListener();
  }

  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void setPeerName(String name) {
    _peerName = name;
    notifyListeners();
  }

  void setCurrentUserId(String id) {
    _currentUserId = id;
    notifyListeners();
  }

  void setCarrierMode(AudioCarrierMode mode) {
    _carrierMode = mode;
    _acoustic.setMode(mode);
    notifyListeners();
  }

  void setActiveRole(P2pRole role) {
    _activeRole = role;
    if (role == P2pRole.receiver) {
      startReceiverListeningMode();
    } else {
      stopReceiverListeningMode();
    }
    notifyListeners();
  }

  void _initP2pMessageListener() {
    _audioStatusSubscription = _acoustic.onStatusEvent.listen((message) {
      if (message.startsWith('Diagnostic:') ||
          (_activeRole == P2pRole.receiver &&
              (message.startsWith('Audio Error:') ||
                  message.startsWith('Audio sync tone detected') ||
                  message.startsWith('Receiving frame data') ||
                  message.startsWith('Frame decode failed:') ||
                  message.startsWith('Received frame rejected:')))) {
        _statusMessage = message;
        notifyListeners();
      }
    });
    _p2pSubscription = _acoustic.onP2pMessageReceived.listen((msg) {
      debugPrint(
        '[P2pViewModel] Incoming P2P Message: Type ${msg.type}, '
        'Txn ${msg.txnId}, Status ${msg.status}',
      );
      _lastReceivedP2pMessage = msg;

      if (_activeRole == P2pRole.receiver && msg.type == 'REQ') {
        _handleIncomingReceiverRequest(msg);
      } else if (_activeRole == P2pRole.sender &&
          (_state == P2pState.transmittingPayload ||
              _state == P2pState.waitingPeerAck ||
              _state == P2pState.retrying)) {
        _handleIncomingSenderAck(msg);
      }
    });
  }

  /// Receiver Mode: Handles incoming sound-wave transfer requests.
  Future<void> _handleIncomingReceiverRequest(P2pMessage req) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // If the sender retries after a lost ACK, resend the result without
    // crediting this in-memory ledger twice.
    TransactionRecord? previousCredit;
    for (final txn in _db.getStudentTransactions()) {
      if (txn.nonce == req.nonce) {
        previousCredit = txn;
        break;
      }
    }
    if (previousCredit != null) {
      final sameTransfer = previousCredit.txnId == req.txnId &&
          previousCredit.amount == req.amountInRupees &&
          !previousCredit.isDebit;
      _statusMessage = sameTransfer
          ? 'Duplicate request received; resending the existing transfer ACK.'
          : 'REJECTED: Nonce was already used for a different transfer.';
      _state = sameTransfer ? P2pState.committedSuccess : P2pState.failed;
      notifyListeners();
      await _acoustic.emitAcousticAck(
        nonce: req.nonce,
        isSuccess: sameTransfer,
        txnId: req.txnId,
      );
      return;
    }

    const allowedSkewMs = 5 * 60 * 1000;
    if ((now - req.timestamp).abs() > allowedSkewMs) {
      _statusMessage =
          'REJECTED: Sound wave timestamp exceeds ±5min freshness window';
      _state = P2pState.failed;
      notifyListeners();
      await _acoustic.emitAcousticAck(
        nonce: req.nonce,
        isSuccess: false,
        txnId: req.txnId,
      );
      return;
    }

    final verifyResult = _ecdsa.verifyPayload(
      tokenId: 'P2P-${req.txnId}',
      merchantId: req.recipientId,
      amount: req.amountInRupees,
      timestamp: req.timestamp,
      nonce: req.nonce,
      signature: req.signature,
      tokenExpiry: now + 86400000,
    );

    if (!verifyResult.isValid) {
      _statusMessage = 'REJECTED: ${verifyResult.reason}';
      _state = P2pState.failed;
      notifyListeners();
      await _acoustic.emitAcousticAck(
        nonce: req.nonce,
        isSuccess: false,
        txnId: req.txnId,
      );
      return;
    }

    final currentBalance = _db.getDecryptedBalance();
    _db.updateBalance(currentBalance + req.amountInRupees);

    final creditTxn = TransactionRecord(
      txnId: req.txnId,
      tokenId: 'P2P-TOKEN-${req.nonce.substring(0, 8).toUpperCase()}',
      merchantId: req.senderId,
      merchantName: req.senderId,
      amount: req.amountInRupees,
      timestamp: now,
      channel: PaymentChannel.ultrasonicFsk,
      status: TxnStatus.verified,
      syncStatus: SyncStatus.offlineUnsynced,
      nonce: req.nonce,
      isDebit: false,
    );

    _db.recordStudentCredit(creditTxn);
    _committedTransaction = creditTxn;

    await _acoustic.emitAcousticAck(
      nonce: req.nonce,
      isSuccess: true,
      txnId: req.txnId,
    );

    _state = P2pState.committedSuccess;
    _statusMessage =
        'Sound-wave transfer received. ₹${req.amountInRupees.toStringAsFixed(2)} '
        'credited from ${req.senderId}.';
    notifyListeners();
  }

  /// Sender Mode: Handles incoming acoustic ACK or NAK frames.
  void _handleIncomingSenderAck(P2pMessage ackMsg) {
    if (ackMsg.type != 'ACK' && ackMsg.type != 'NAK') return;
    if (_committedTransaction == null) return;
    final pendingNonce = _committedTransaction!.nonce;

    if (ackMsg.nonce != pendingNonce) {
      debugPrint(
        '[P2pViewModel] Nonce mismatch on ACK: expected $pendingNonce, '
        'got ${ackMsg.nonce}',
      );
      return;
    }
    if (ackMsg.txnId != _committedTransaction!.txnId) {
      debugPrint(
        '[P2pViewModel] Transaction mismatch on ACK: expected '
        '${_committedTransaction!.txnId}, got ${ackMsg.txnId}',
      );
      return;
    }
    if (ackMsg.amountPaise != 0 ||
        ackMsg.senderId != 'RECEIVER' ||
        ackMsg.recipientId != 'SENDER' ||
        (DateTime.now().millisecondsSinceEpoch - ackMsg.timestamp).abs() >
            5 * 60 * 1000) {
      debugPrint(
        '[P2pViewModel] ACK envelope validation failed for ${ackMsg.txnId}',
      );
      return;
    }

    _ackTimeoutTimer?.cancel();
    _ackTimeoutTimer = null;
    _acoustic.stopListening();

    if (ackMsg.type == 'ACK' && ackMsg.status == 'OK') {
      final currentBalance = _db.getDecryptedBalance();
      _db.updateBalance(currentBalance - _committedTransaction!.amount);
      _db.recordStudentDebit(_committedTransaction!);
      _state = P2pState.committedSuccess;
      _statusMessage =
          'Acoustic ACK received. ₹${_amount.toStringAsFixed(2)} '
          'recorded as sent to $_peerName.';
      notifyListeners();
    } else {
      _state = P2pState.failed;
      _statusMessage =
          'Peer returned a negative ACK (${ackMsg.status}). '
          'Wallet balance untouched.';
      notifyListeners();
    }
  }

  /// Receiver Mode: Activates the microphone listener.
  Future<void> startReceiverListeningMode() async {
    _activeRole = P2pRole.receiver;
    _state = P2pState.idle;
    _statusMessage = 'Requesting microphone access and starting receiver...';
    notifyListeners();

    final permissionGranted = await _acoustic.checkAndRequestPermission();
    if (!permissionGranted) {
      _state = P2pState.failed;
      _statusMessage =
          'Microphone permission denied. Enable RECORD_AUDIO in device '
          'settings to receive sound-wave transfers.';
      notifyListeners();
      return;
    }

    final started = await _acoustic.startListening();
    if (!started) {
      _state = P2pState.failed;
      _statusMessage =
          'Receiver microphone could not start. Check microphone permission '
          'and close other apps using the mic.';
      notifyListeners();
      return;
    }
    _state = P2pState.listening;
    _statusMessage =
        'Microphone is recording. Keep this screen open to receive a '
        'sound-wave request.';
    notifyListeners();
  }

  /// Starts the wallet-free audible PING diagnostic listener.
  Future<void> startAcousticDiagnosticReceiver() async {
    _activeRole = P2pRole.receiver;
    _state = P2pState.idle;
    _statusMessage =
        'Diagnostic: requesting microphone and starting PING listener...';
    notifyListeners();

    await _acoustic.stopListening();
    await Future.delayed(const Duration(milliseconds: 150));
    final permissionGranted = await _acoustic.checkAndRequestPermission();
    if (!permissionGranted) {
      _state = P2pState.failed;
      _statusMessage = 'Diagnostic: microphone permission denied.';
      notifyListeners();
      return;
    }

    final started = await _acoustic.startDiagnosticListening();
    if (!started) {
      _state = P2pState.failed;
      _statusMessage = 'Diagnostic: receiver microphone could not start.';
      notifyListeners();
      return;
    }

    _carrierMode = AudioCarrierMode.audibleFsk;
    _state = P2pState.listening;
    _statusMessage =
        'Diagnostic: listening for PING; wallets are untouched.';
    notifyListeners();
  }

  /// Sends the fixed PING diagnostic; it is not a payment request.
  Future<void> sendAcousticDiagnosticPing() async {
    _activeRole = P2pRole.sender;
    _statusMessage =
        'Diagnostic: starting PING playback; wallets are untouched.';
    notifyListeners();
    try {
      await _acoustic.emitDiagnosticPing();
    } catch (error) {
      _statusMessage = 'Diagnostic: PING could not start: $error';
      notifyListeners();
    }
  }

  Future<void> stopReceiverListeningMode() async {
    await _acoustic.stopListening();
    if (_state == P2pState.listening) {
      _state = P2pState.idle;
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Starts the primary acoustic P2P payment flow. BLE is intentionally not
  /// invoked automatically when acoustic delivery or its ACK is uncertain.
  Future<bool> sendP2pTransfer() async {
    _activeRole = P2pRole.sender;
    final currentBalance = _db.getDecryptedBalance();
    if (_amount <= 0) {
      _statusMessage = 'Enter a valid payment amount.';
      _state = P2pState.failed;
      notifyListeners();
      return false;
    }
    if (currentBalance < _amount) {
      _statusMessage =
          'Insufficient balance in Campus Wallet (Available: '
          '₹${currentBalance.toStringAsFixed(2)})';
      _state = P2pState.failed;
      notifyListeners();
      return false;
    }

    final permissionGranted = await _acoustic.checkAndRequestPermission();
    if (!permissionGranted) {
      _state = P2pState.failed;
      _statusMessage =
          'Microphone permission required for sound-wave ACK reception.';
      notifyListeners();
      return false;
    }

    _retryCount = 0;
    final nonce = _ecdsa.generateNonce();
    final txnId = 'P2P-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final signature = _ecdsa.signPayload(
      tokenId: 'P2P-$txnId',
      merchantId: _peerName,
      amount: _amount,
      timestamp: now,
      nonce: nonce,
    );

    _committedTransaction = TransactionRecord(
      txnId: txnId,
      tokenId: 'P2P-TOKEN-${nonce.substring(0, 8)}',
      merchantId: 'STU-${_peerName.replaceAll(' ', '-').toUpperCase()}',
      merchantName: _peerName,
      amount: _amount,
      timestamp: now,
      channel: PaymentChannel.p2pAcoustic,
      status: TxnStatus.verified,
      syncStatus: SyncStatus.offlineUnsynced,
      nonce: nonce,
      isDebit: true,
    );

    return _executeTransmissionWithAckWait(
      reqNonce: nonce,
      reqTxnId: txnId,
      signature: signature,
      timestamp: now,
    );
  }

  /// Explicit BLE sender operation retained from the feature branch. It is
  /// separate from the acoustic flow and is not called on acoustic timeout.
  Future<bool> sendBleP2pTransfer() async {
    _activeRole = P2pRole.sender;
    try {
      if (_amount <= 0) {
        _state = P2pState.failed;
        _statusMessage = 'Enter a valid payment amount.';
        notifyListeners();
        return false;
      }

      final OfflineToken? token = _tokenRepo.getAvailableToken();
      if (token == null) {
        _state = P2pState.failed;
        _statusMessage = 'No valid offline payment token available.';
        notifyListeners();
        return false;
      }
      if (token.isExpired) {
        _state = P2pState.failed;
        _statusMessage = 'Your offline payment token has expired.';
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

      final nonce = _ecdsa.generateNonce();
      final now = DateTime.now().millisecondsSinceEpoch;
      const merchantId = 'STU-ROHAN-4211';
      final paymentSignature = _ecdsa.signPayload(
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

      _state = P2pState.transmittingPayload;
      _statusMessage = 'Sending offline payment token through BLE...';
      notifyListeners();

      final bleSuccess = await _bleTransport.sendPayment(
        paymentData: paymentData,
      );
      if (!bleSuccess) {
        _state = P2pState.failed;
        _statusMessage = 'BLE payment failed. No token was deducted.';
        notifyListeners();
        return false;
      }

      _state = P2pState.waitingPeerAck;
      _statusMessage = 'BLE receiver returned an ACK.';
      notifyListeners();

      _tokenRepo.markTokenUsed(token.tokenId);
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
          'recorded as sent using the offline token.';
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[P2P] BLE payment failed: $e');
      debugPrint('[P2P] Stack trace: $stackTrace');
      _state = P2pState.failed;
      _statusMessage = 'BLE payment failed. The transfer was not recorded.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _executeTransmissionWithAckWait({
    required String reqNonce,
    required String reqTxnId,
    required String signature,
    required int timestamp,
  }) async {
    final reqMsg = P2pMessage(
      type: 'REQ',
      txnId: reqTxnId,
      senderId: _currentUserId,
      recipientId: _peerName,
      amountPaise: (_amount * 100).round(),
      timestamp: timestamp,
      nonce: reqNonce,
      signature: signature,
    );

    _state = P2pState.transmittingPayload;
    _statusMessage =
        'Emitting FSK sound-wave burst over speaker '
        '(${_carrierMode == AudioCarrierMode.audibleFsk ? '1.2–2.4kHz Audible FSK' : '18–22kHz Ultrasonic'})...';
    notifyListeners();

    try {
      final listening = await _acoustic.startListening();
      if (!listening) {
        throw StateError('Sender microphone could not start for ACK reception.');
      }

      await _acoustic.emitP2pMessage(reqMsg);
      if (_state == P2pState.committedSuccess || _state == P2pState.failed) {
        return _state == P2pState.committedSuccess;
      }

      _state = P2pState.waitingPeerAck;
      _statusMessage =
          'Request transmission completed. Waiting for the peer to return an ACK...';
      notifyListeners();

      _ackTimeoutTimer?.cancel();
      _ackTimeoutTimer = Timer(const Duration(seconds: 60), () {
        _handleAckTimeout(
          reqNonce: reqNonce,
          reqTxnId: reqTxnId,
          signature: signature,
          timestamp: timestamp,
        );
      });
      return true;
    } catch (error) {
      await _acoustic.stopListening();
      _state = P2pState.failed;
      _statusMessage = 'Sound-wave transmission failed: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> _handleAckTimeout({
    required String reqNonce,
    required String reqTxnId,
    required String signature,
    required int timestamp,
  }) async {
    await _acoustic.stopListening();
    if (_state != P2pState.waitingPeerAck) return;

    if (_retryCount < _maxRetries) {
      _retryCount++;
      _state = P2pState.retrying;
      _statusMessage =
          'Acoustic ACK timeout. Retrying sound-wave transmission '
          '(Attempt $_retryCount of $_maxRetries)...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 600));
      if (_state == P2pState.committedSuccess || _state == P2pState.failed) {
        return;
      }
      await _executeTransmissionWithAckWait(
        reqNonce: reqNonce,
        reqTxnId: reqTxnId,
        signature: signature,
        timestamp: timestamp,
      );
    } else {
      _state = P2pState.failed;
      _statusMessage =
          'No acoustic ACK received after $_maxRetries retries. '
          'The outcome may be unresolved; BLE was not attempted.';
      notifyListeners();
    }
  }

  void reset() {
    _ackTimeoutTimer?.cancel();
    _ackTimeoutTimer = null;
    _acoustic.stopListening();
    _state = P2pState.idle;
    _statusMessage = null;
    _committedTransaction = null;
    _retryCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ackTimeoutTimer?.cancel();
    _p2pSubscription?.cancel();
    _audioStatusSubscription?.cancel();
    _acoustic.stopListening();
    _bleTransport.dispose();
    super.dispose();
  }
}
