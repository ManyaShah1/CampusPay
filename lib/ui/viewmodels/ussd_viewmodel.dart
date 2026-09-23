import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/ussd/ussd_service.dart';
import '../../core/ussd/ussd_session_state.dart';
import '../../data/repositories/payment_repository.dart';

/// ViewModel driving the USSD payment wizard.
///
/// Owned by [MultiProvider] in main.dart and consumed by [UssdSessionScreen].
/// Call [startPayment] after the user enters payee VPA and amount.
class UssdViewModel extends ChangeNotifier {
  final UssdService _ussdService = UssdService();
  final PaymentRepository _paymentRepo = PaymentRepository();

  UssdSessionState _state = UssdSessionState.idle;
  UssdSessionState get state => _state;

  StreamSubscription<Map<String, String>>? _eventSub;

  // ── Public fields set by the UI before calling startPayment ──────────────
  String payeeVpa = '';
  String amountRaw = '';

  // ── Start a new USSD payment session ─────────────────────────────────────
  Future<void> startPayment() async {
    if (payeeVpa.isEmpty || amountRaw.isEmpty) return;

    _cancelEventSub();

    _updateState(_state.copyWith(
      step: UssdStep.dialingUssd,
      statusMessage: 'Connecting GSM modem… dialing *99#',
      responseLog: [],
      errorMessage: null,
    ));

    // Subscribe to native USSD event stream before calling native method
    _eventSub = _ussdService.ussdEvents.listen(
      _onUssdEvent,
      onError: (err) {
        _updateState(_state.copyWith(
          step: UssdStep.failed,
          errorMessage: 'Event stream error: $err',
          statusMessage: 'GSM session failed',
        ));
      },
    );

    final result = await _ussdService.startUssdSession(
      payeeVpa: payeeVpa,
      amount: _wholeAmount(amountRaw),
    );

    // Handle synchronous result codes (permission-denied / fallback paths)
    switch (result) {
      case 'fallback_dialer':
      case 'dialer_opened':
        _updateState(_state.copyWith(
          step: UssdStep.dialerOpened,
          statusMessage:
              'System dialer opened.\nNavigate the *99# menu to complete payment.',
        ));
        _cancelEventSub();
        break;

      case 'platform_unsupported':
        _updateState(_state.copyWith(
          step: UssdStep.failed,
          errorMessage: 'USSD is only supported on Android with a SIM card.',
          statusMessage: 'Platform not supported',
        ));
        _cancelEventSub();
        break;

      case 'error':
        // State will be updated by the event stream; only update if stream
        // didn't already set a terminal state
        if (!_state.isTerminal) {
          _updateState(_state.copyWith(
            step: UssdStep.failed,
            errorMessage: 'USSD session failed — check GSM signal.',
            statusMessage: 'Session error',
          ));
        }
        _cancelEventSub();
        break;

      // 'success' → NPCI responded; stay in awaitingPin, event stream handles
      default:
        break;
    }
  }

  // ── Handle live USSD events from native EventChannel ─────────────────────
  void _onUssdEvent(Map<String, String> event) {
    final type = event['type'] ?? '';
    final text = event['text'] ?? '';
    final newLog = List<String>.from(_state.responseLog)..add('[$type] $text');

    switch (type) {
      case 'status':
        _updateState(_state.copyWith(
          step: _inferStepFromStatus(text),
          statusMessage: text,
          responseLog: newLog,
        ));
        break;

      case 'response':
        // Parse NPCI response to determine which menu step we're on
        final newStep = _inferStepFromNpciResponse(text);
        _updateState(_state.copyWith(
          step: newStep,
          lastResponse: text,
          statusMessage: _stepToStatusMessage(newStep),
          responseLog: newLog,
        ));

        if (newStep == UssdStep.confirmed) {
          _recordTransaction();
          _cancelEventSub();
        }
        break;

      case 'error':
        _updateState(_state.copyWith(
          step: UssdStep.failed,
          errorMessage: text,
          statusMessage: 'GSM error',
          responseLog: newLog,
        ));
        _cancelEventSub();
        break;

      case 'fallback':
        _updateState(_state.copyWith(
          step: UssdStep.dialerOpened,
          statusMessage: 'System dialer opened for *99# session',
          responseLog: newLog,
        ));
        _cancelEventSub();
        break;
    }
  }

  // ── Heuristic: infer step from NPCI response text ─────────────────────────
  // NPCI menu responses are not standardised across banks, but common patterns:
  //  "Send Money" / "Pay" / "Transfer"  → menuSendMoney
  //  "Enter UPI PIN" / "PIN"            → awaitingPin
  //  "successfully" / "approved"        → confirmed
  UssdStep _inferStepFromNpciResponse(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pin') || lower.contains('enter your upi')) {
      return UssdStep.awaitingPin;
    }
    if (lower.contains('success') ||
        lower.contains('approved') ||
        lower.contains('completed') ||
        lower.contains('debit')) {
      return UssdStep.confirmed;
    }
    if (lower.contains('send') ||
        lower.contains('pay') ||
        lower.contains('transfer') ||
        lower.contains('mobile')) {
      return UssdStep.menuSendMoney;
    }
    if (lower.contains('payee') ||
        lower.contains('amount') ||
        lower.contains('enter amount')) {
      return UssdStep.menuPayee;
    }
    return _state.step; // No change
  }

  UssdStep _inferStepFromStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('dial')) return UssdStep.dialingUssd;
    return _state.step;
  }

  String _stepToStatusMessage(UssdStep step) {
    switch (step) {
      case UssdStep.dialingUssd:
        return 'Dialing *99# via GSM modem…';
      case UssdStep.menuSendMoney:
        return 'NPCI connected — navigating to Send Money (option 7)…';
      case UssdStep.menuPayee:
        return 'Sending payee VPA to NPCI…';
      case UssdStep.awaitingPin:
        return '🔐 NPCI is waiting for your UPI PIN.\nType it on your phone\'s keypad now.';
      case UssdStep.confirmed:
        return '✅ Transaction confirmed by NPCI bank gateway!';
      case UssdStep.failed:
        return 'Session failed';
      case UssdStep.dialerOpened:
        return 'System dialer opened — navigate *99# manually';
      default:
        return _state.statusMessage;
    }
  }

  // ── Record successful USSD txn in local SQLite ledger ────────────────────
  Future<void> _recordTransaction() async {
    final amt = double.tryParse(amountRaw) ?? 0.0;
    if (amt <= 0) return;
    await _paymentRepo.executeSilentUssdPayment(
      merchantId: 'UPI-$payeeVpa',
      merchantName: payeeVpa,
      amount: amt,
      mpin: '****', // MPIN never stored; placeholder only
    );
  }

  // ── Reset state ───────────────────────────────────────────────────────────
  void reset() {
    _cancelEventSub();
    _updateState(UssdSessionState.idle);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _updateState(UssdSessionState newState) {
    _state = newState;
    notifyListeners();
  }

  void _cancelEventSub() {
    _eventSub?.cancel();
    _eventSub = null;
  }

  /// NPCI expects amount as a whole-number string ("120" not "120.0")
  String _wholeAmount(String raw) {
    final d = double.tryParse(raw) ?? 0.0;
    return d.toInt().toString();
  }

  @override
  void dispose() {
    _cancelEventSub();
    super.dispose();
  }
}
