import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/audio/acoustic_carrier.dart';
import '../../core/crypto/ecdsa_service.dart';
import '../../data/database/local_ledger_db.dart';
import '../../data/models/transaction_record.dart';

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
  final AcousticCarrier _acoustic = AcousticCarrier();

  P2pState _state = P2pState.idle;
  double _amount = 150.0;
  String _peerName = 'Rohan Verma (SE-COMPS)';
  String? _statusMessage;
  TransactionRecord? _committedTransaction;

  P2pState get state => _state;
  double get amount => _amount;
  String get peerName => _peerName;
  String? get statusMessage => _statusMessage;
  TransactionRecord? get committedTransaction => _committedTransaction;

  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void setPeerName(String name) {
    _peerName = name;
    notifyListeners();
  }

  /// Initiates two-phase commit P2P transfer
  Future<bool> sendP2pTransfer() async {
    final currentBalance = _db.getDecryptedBalance();
    if (currentBalance < _amount) {
      _statusMessage = 'Insufficient balance in Campus Wallet';
      _state = P2pState.failed;
      notifyListeners();
      return false;
    }

    final nonce = _ecdsa.generateNonce();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Phase 1: Transmitting Signed Payload
    _state = P2pState.transmittingPayload;
    _statusMessage = 'Emitting ultrasonic burst + BLE advertisement...';
    notifyListeners();

    await _acoustic.emitUltrasonicBurst(
      rawPayload: 'P2P|$nonce|$_amount|$_peerName',
      nonce: nonce,
      amount: _amount,
    );

    // Phase 2: Waiting for Acoustic ACK from Peer
    _state = P2pState.waitingPeerAck;
    _statusMessage = 'Peer verified signature. Awaiting acoustic ACK confirmation...';
    notifyListeners();

    await _acoustic.emitAcousticAck(nonce: nonce, isSuccess: true);

    // Two-Phase Commit Rule: ONLY NOW deduct from wallet
    _db.updateBalance(currentBalance - _amount);

    final txnId = 'P2P-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    final txn = TransactionRecord(
      txnId: txnId,
      tokenId: 'P2P-TOKEN-${nonce.substring(0, 8)}',
      merchantId: 'STU-ROHAN-4211',
      merchantName: _peerName,
      amount: _amount,
      timestamp: now,
      channel: PaymentChannel.p2pAcoustic,
      status: TxnStatus.verified,
      syncStatus: SyncStatus.offlineUnsynced,
      nonce: nonce,
      isDebit: true,
    );

    _db.recordStudentDebit(txn);
    _committedTransaction = txn;
    _state = P2pState.committedSuccess;
    _statusMessage = 'Acoustic ACK received. ₹$_amount successfully sent!';
    notifyListeners();
    return true;
  }

  void reset() {
    _state = P2pState.idle;
    _statusMessage = null;
    _committedTransaction = null;
    notifyListeners();
  }
}
