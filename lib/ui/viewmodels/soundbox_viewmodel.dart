import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/audio/acoustic_carrier.dart';
import '../../core/crypto/ecdsa_service.dart';
import '../../data/database/local_ledger_db.dart';
import '../../data/models/payment_payload.dart';
import '../../data/models/transaction_record.dart';

class SoundBoxViewModel extends ChangeNotifier {
  final EcdsaService _ecdsa = EcdsaService();
  final AcousticCarrier _acoustic = AcousticCarrier();
  final LocalLedgerDb _db = LocalLedgerDb();

  StreamSubscription? _packetSubscription;

  bool _isListening = true;
  final bool _isBleActive = true;
  String _lastAnnouncement = 'Device Ready • Listening on 18–22kHz FSK';
  PaymentPayload? _lastVerifiedPayload;
  VerificationResult? _lastVerificationResult;
  List<TransactionRecord> _creditHistory = [];

  bool get isListening => _isListening;
  bool get isBleActive => _isBleActive;
  String get lastAnnouncement => _lastAnnouncement;
  PaymentPayload? get lastVerifiedPayload => _lastVerifiedPayload;
  VerificationResult? get lastVerificationResult => _lastVerificationResult;
  List<TransactionRecord> get creditHistory => _creditHistory;

  double get totalSalesToday {
    return _creditHistory.fold(0.0, (sum, item) => sum + item.amount);
  }

  SoundBoxViewModel() {
    _refreshHistory();
    _startListening();
  }

  void _refreshHistory() {
    _creditHistory = _db.getSoundboxTransactions();
    notifyListeners();
  }

  void _startListening() {
    _packetSubscription = _acoustic.onUltrasonicPacketReceived.listen((packet) async {
      debugPrint('[SoundBoxVM] Ultrasonic packet caught: ₹${packet.amount}, Nonce: ${packet.nonce}');

      try {
        final payload = PaymentPayload.deserialize(packet.rawPayload);

        // Step 6: Local Edge ECDSA Verification
        final result = _ecdsa.verifyPayload(
          tokenId: payload.tokenId,
          merchantId: payload.merchantId,
          amount: payload.amount,
          timestamp: payload.timestamp,
          nonce: payload.nonce,
          signature: payload.payerSignature,
          tokenExpiry: payload.tokenExpiry,
        );

        _lastVerifiedPayload = payload;
        _lastVerificationResult = result;

        if (result.isValid) {
          // Log credit into SoundBox local SQLite ledger
          final creditRecord = TransactionRecord(
            txnId: 'SB-TXN-${payload.nonce.substring(0, 6).toUpperCase()}',
            tokenId: payload.tokenId,
            merchantId: payload.merchantId,
            merchantName: payload.payerName,
            amount: payload.amount,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            channel: PaymentChannel.ultrasonicFsk,
            status: TxnStatus.verified,
            syncStatus: SyncStatus.reconciled,
            nonce: payload.nonce,
            isDebit: false,
          );
          _db.recordSoundboxCredit(creditRecord);

          // Emit instant Acoustic ACK return wave back to student phone
          await _acoustic.emitAcousticAck(nonce: payload.nonce, isSuccess: true);

          // Step 7: TTS audio announcement & display
          _lastAnnouncement = 'CampusPay se ₹${payload.amount.toStringAsFixed(0)} mila 🔊';
        } else {
          _lastAnnouncement = 'PAYMENT REJECTED: ${result.reason} ⚠️';
          await _acoustic.emitAcousticAck(nonce: payload.nonce, isSuccess: false);
        }

        _refreshHistory();
      } catch (e) {
        _lastAnnouncement = 'MALFORMED PACKET: ${e.toString()}';
        notifyListeners();
      }
    });
  }

  void toggleListening() {
    _isListening = !_isListening;
    notifyListeners();
  }

  @override
  void dispose() {
    _packetSubscription?.cancel();
    super.dispose();
  }
}
