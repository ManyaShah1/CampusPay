/// Lifecycle states for a USSD payment session
enum UssdStep {
  /// Initial state — no session started
  idle,

  /// Requesting CALL_PHONE permission from the user
  requestingPermission,

  /// Permission denied permanently — fallback dialer shown
  permissionDenied,

  /// GSM modem is dialing *99#
  dialingUssd,

  /// Menu step 1: selecting "Send Money" option (7) from NPCI menu
  menuSendMoney,

  /// Menu step 2: NPCI acknowledged payee VPA, navigating to amount
  menuPayee,

  /// Menu step 3: NPCI acknowledged amount, awaiting UPI PIN
  awaitingPin,

  /// NPCI confirmed the transaction
  confirmed,

  /// Fallback: system dialer was opened (permission denied or API < 26)
  dialerOpened,

  /// Something went wrong (GSM error, invalid PIN, etc.)
  failed,
}

/// Snapshot of the USSD session at any point in time
class UssdSessionState {
  final UssdStep step;

  /// Latest raw USSD response text received from NPCI via GSM
  final String? lastResponse;

  /// Human-readable status message shown in the UI terminal log
  final String statusMessage;

  /// Error description (only set when step == failed)
  final String? errorMessage;

  /// Ordered log of all USSD response lines received so far
  final List<String> responseLog;

  const UssdSessionState({
    required this.step,
    this.lastResponse,
    required this.statusMessage,
    this.errorMessage,
    this.responseLog = const [],
  });

  /// Initial idle state
  static const idle = UssdSessionState(
    step: UssdStep.idle,
    statusMessage: 'Ready to initiate *99# session',
  );

  UssdSessionState copyWith({
    UssdStep? step,
    String? lastResponse,
    String? statusMessage,
    String? errorMessage,
    List<String>? responseLog,
  }) {
    return UssdSessionState(
      step: step ?? this.step,
      lastResponse: lastResponse ?? this.lastResponse,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      responseLog: responseLog ?? this.responseLog,
    );
  }

  bool get isTerminal =>
      step == UssdStep.confirmed ||
      step == UssdStep.failed ||
      step == UssdStep.dialerOpened;

  bool get isActive =>
      step != UssdStep.idle &&
      step != UssdStep.confirmed &&
      step != UssdStep.failed &&
      step != UssdStep.dialerOpened;
}
