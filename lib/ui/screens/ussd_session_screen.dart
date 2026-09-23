import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ussd/ussd_session_state.dart';
import '../viewmodels/ussd_viewmodel.dart';
import '../widgets/fintech_card.dart';

/// Real *99# USSD Payment Wizard — 3-step flow:
///   Step 1: Enter payee VPA / mobile number
///   Step 2: Enter amount
///   Step 3: Live GSM terminal + UPI PIN instruction
class UssdSessionScreen extends StatefulWidget {
  const UssdSessionScreen({super.key});

  @override
  State<UssdSessionScreen> createState() => _UssdSessionScreenState();
}

class _UssdSessionScreenState extends State<UssdSessionScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _vpaCtrl    = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  int _currentStep = 0; // 0 = VPA, 1 = Amount, 2 = Live session

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _vpaCtrl.dispose();
    _amountCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextFromVpa() {
    final vpa = _vpaCtrl.text.trim();
    if (!_isValidVpa(vpa)) {
      _showError('Enter a valid UPI ID (e.g. 9876543210@upi) or 10-digit mobile number');
      return;
    }
    _goToStep(1);
  }

  void _nextFromAmount() {
    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amt <= 0 || amt > 100000) {
      _showError('Enter a valid amount between ₹1 and ₹1,00,000');
      return;
    }
    _initiateUssdSession();
  }

  Future<void> _initiateUssdSession() async {
    final vm = context.read<UssdViewModel>();
    vm.payeeVpa  = _vpaCtrl.text.trim();
    vm.amountRaw = _amountCtrl.text.trim();
    _goToStep(2);
    await vm.startPayment();
  }

  void _reset() {
    context.read<UssdViewModel>().reset();
    _vpaCtrl.clear();
    _amountCtrl.clear();
    _goToStep(0);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black)),
        backgroundColor: AppColors.amberAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isValidVpa(String v) {
    if (v.isEmpty) return false;
    // UPI VPA pattern: something@bank or 10-digit mobile
    if (RegExp(r'^\d{10}$').hasMatch(v)) return true;
    if (RegExp(r'^[\w.\-]+@[\w]+$').hasMatch(v)) return true;
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Vpa(),
                _buildStep2Amount(),
                _buildStep3Session(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundBlack,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
        onPressed: () {
          if (_currentStep > 0 && _currentStep < 2) {
            _goToStep(_currentStep - 1);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '*99# UPI PAYMENT',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.white,
            ),
          ),
          Text(
            'GSM cellular fallback — works without internet',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutedText,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['PAYEE', 'AMOUNT', 'GSM DIAL'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: (i ~/ 2) < _currentStep
                    ? AppColors.amberAccent
                    : const Color(0xFF2A2A2A),
              ),
            );
          }
          final step = i ~/ 2;
          final isActive   = step == _currentStep;
          final isComplete = step < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? AppColors.successGreen
                  : isActive
                      ? AppColors.amberAccent
                      : const Color(0xFF2A2A2A),
            ),
            child: Center(
              child: isComplete
                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.black : AppColors.mutedText,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Payee VPA ─────────────────────────────────────────────────────

  Widget _buildStep1Vpa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _sectionTitle('PAYEE UPI ID / MOBILE'),
          const SizedBox(height: 6),
          const Text(
            'Enter the recipient\'s UPI Virtual Payment Address\nor their 10-digit mobile number',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.5),
          ),
          const SizedBox(height: 20),

          // VPA input
          TextField(
            controller: _vpaCtrl,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\w.\-@]')),
            ],
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 18,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.amberAccent, width: 1.5),
              ),
              hintText: '9876543210@upi  or  9876543210',
              hintStyle: const TextStyle(
                color: AppColors.mutedText,
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.amberAccent),
            ),
          ),
          const SizedBox(height: 16),

          // Examples
          FintechCard(
            leftBorderColor: AppColors.lightPurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ACCEPTED FORMATS',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightPurple,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text('• 9876543210@sbi   (UPI ID)', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.lightMutedText)),
                Text('• canteen@upi       (Merchant VPA)', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.lightMutedText)),
                Text('• 9876543210        (Mobile → NPCI resolves)', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.lightMutedText)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _primaryButton(
            label: 'CONTINUE',
            icon: Icons.arrow_forward_rounded,
            onTap: _nextFromVpa,
          ),

          const SizedBox(height: 20),
          _tierBadge(),
        ],
      ),
    );
  }

  // ── Step 2: Amount ────────────────────────────────────────────────────────

  Widget _buildStep2Amount() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Payee confirmation chip
          Consumer<UssdViewModel>(
            builder: (_, vm, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightPurple.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.lightPurple, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _vpaCtrl.text.isNotEmpty ? _vpaCtrl.text : '—',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppColors.lightPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle('PAYMENT AMOUNT'),
          const SizedBox(height: 16),

          // Big ₹ input
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.amberAccent, width: 1.5),
              ),
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 32,
                color: AppColors.amberAccent,
                fontWeight: FontWeight.w700,
              ),
              hintText: '0',
              hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 40),
            ),
          ),
          const SizedBox(height: 12),

          // Quick-amount chips
          Wrap(
            spacing: 8,
            children: [50, 100, 150, 200, 500].map((amt) {
              return GestureDetector(
                onTap: () => _amountCtrl.text = amt.toString(),
                child: Chip(
                  label: Text('₹$amt', style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.cardDark,
                  labelStyle: const TextStyle(color: AppColors.white, fontFamily: 'SpaceGrotesk'),
                  side: const BorderSide(color: Color(0xFF3A3A3A)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          FintechCard(
            leftBorderColor: AppColors.amberAccent,
            child: const Text(
              '🔐  After you tap Initiate, the app will dial *99# silently and navigate NPCI menus automatically. You will only need to enter your UPI PIN when prompted.',
              style: TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),

          _primaryButton(
            label: 'INITIATE *99# SESSION',
            icon: Icons.call_rounded,
            onTap: _nextFromAmount,
            color: AppColors.amberAccent,
          ),
        ],
      ),
    );
  }

  // ── Step 3: Live GSM terminal ─────────────────────────────────────────────

  Widget _buildStep3Session() {
    return Consumer<UssdViewModel>(
      builder: (_, vm, _) {
        final state = vm.state;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              _buildSessionHeader(state),
              const SizedBox(height: 20),

              // Terminal log
              _buildTerminalLog(state),
              const SizedBox(height: 20),

              // Contextual bottom card
              _buildBottomCard(state),

              if (state.isTerminal) ...[
                const SizedBox(height: 24),
                _primaryButton(
                  label: state.step == UssdStep.confirmed ? 'DONE' : 'TRY AGAIN',
                  icon: state.step == UssdStep.confirmed
                      ? Icons.check_circle_outline_rounded
                      : Icons.refresh_rounded,
                  onTap: () {
                    if (state.step == UssdStep.confirmed) {
                      Navigator.pop(context);
                    } else {
                      _reset();
                    }
                  },
                  color: state.step == UssdStep.confirmed
                      ? AppColors.successGreen
                      : AppColors.amberAccent,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionHeader(UssdSessionState state) {
    final (icon, color, label) = switch (state.step) {
      UssdStep.dialingUssd    => (Icons.cell_tower_rounded,    AppColors.amberAccent,  'CONNECTING GSM MODEM'),
      UssdStep.menuSendMoney  => (Icons.phone_in_talk_rounded, AppColors.amberAccent,  'NAVIGATING NPCI MENU'),
      UssdStep.menuPayee      => (Icons.phone_in_talk_rounded, AppColors.amberAccent,  'SENDING PAYEE DETAILS'),
      UssdStep.awaitingPin    => (Icons.lock_rounded,          AppColors.lightPurple,  'ENTER YOUR UPI PIN'),
      UssdStep.confirmed      => (Icons.check_circle_rounded,  AppColors.successGreen, 'PAYMENT CONFIRMED'),
      UssdStep.dialerOpened   => (Icons.dialpad_rounded,       AppColors.amberAccent,  'COMPLETE IN DIALER'),
      UssdStep.failed         => (Icons.error_outline_rounded, const Color(0xFFEF4444), 'SESSION FAILED'),
      _                       => (Icons.cell_tower_rounded,    AppColors.mutedText,    'INITIALIZING'),
    };

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(
              state.isActive ? _pulseAnim.value * 0.6 : 0.3,
            ),
            width: 1.5,
          ),
          boxShadow: state.isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(_pulseAnim.value * 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.statusMessage,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightMutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (state.isActive)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalLog(UssdSessionState state) {
    final log = state.responseLog;
    if (log.isEmpty && state.step == UssdStep.dialingUssd) {
      return _terminalContainer(
        child: const Text(
          '> Connecting to *99# USSD gateway via GSM…',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: AppColors.amberAccent,
          ),
        ),
      );
    }
    if (log.isEmpty) return const SizedBox.shrink();

    return _terminalContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.terminal_rounded, size: 12, color: AppColors.mutedText),
              SizedBox(width: 6),
              Text(
                'USSD SESSION LOG',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 9,
                  color: AppColors.mutedText,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...log.asMap().entries.map((e) {
            final isLast  = e.key == log.length - 1;
            final isError = e.value.startsWith('[error]');
            final isResp  = e.value.startsWith('[response]');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${isLast ? '▶' : ' '} ${e.value}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10.5,
                  height: 1.5,
                  color: isError
                      ? const Color(0xFFEF4444)
                      : isResp
                          ? AppColors.white
                          : AppColors.amberAccent,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _terminalContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: child,
    );
  }

  Widget _buildBottomCard(UssdSessionState state) {
    if (state.step == UssdStep.awaitingPin) {
      return AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D1B69).withOpacity(_glowAnim.value),
                const Color(0xFF1A0F3C),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.lightPurple.withOpacity(_glowAnim.value * 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightPurple.withOpacity(_glowAnim.value * 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: const [
              Icon(Icons.lock_rounded, color: AppColors.lightPurple, size: 36),
              SizedBox(height: 12),
              Text(
                'ENTER YOUR UPI PIN NOW',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightPurple,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'NPCI has received the payee and amount.\nType your 4 or 6-digit UPI PIN on the\nkeypad that appeared on your screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightMutedText,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🔐  Your PIN travels only through the GSM channel.\nIt is NEVER stored or transmitted by this app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9.5,
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.step == UssdStep.confirmed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2E1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.successGreen.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BANK DEBIT CONFIRMED',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successGreen,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_amountCtrl.text} paid to ${_vpaCtrl.text}\nvia NPCI *99# GSM gateway',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightMutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.step == UssdStep.dialerOpened) {
      return FintechCard(
        leftBorderColor: AppColors.amberAccent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📲  COMPLETE IN YOUR DIALER',
                style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberAccent)),
            SizedBox(height: 6),
            Text(
              'The USSD code has been pre-filled in your system dialer. Tap the green call button, navigate the *99# NPCI menu, and enter your UPI PIN when prompted.',
              style: TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.5),
            ),
          ],
        ),
      );
    }

    if (state.step == UssdStep.failed) {
      return FintechCard(
        leftBorderColor: const Color(0xFFEF4444),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠  GSM SESSION ERROR',
                style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ?? 'Unknown error. Check GSM signal and SIM status.',
              style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.5),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.white,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.amberAccent,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _tierBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF261808),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amberAccent.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📶', style: TextStyle(fontSize: 12)),
            SizedBox(width: 6),
            Text(
              'TIER 3 — GSM CELLULAR · NO INTERNET REQUIRED',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.amberAccent,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
