import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/razorpay_service.dart';
import '../viewmodels/wallet_viewmodel.dart';
import 'campus_coins_screen.dart';
import 'p2p_transfer_screen.dart';
import 'scan_and_pay_screen.dart';
import 'token_vault_screen.dart';
import 'ussd_session_screen.dart';
import '../../core/services/onboarding_service.dart';
import '../widgets/home_tour_overlay.dart';

class StudentHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onNavigateToRewards;
  final bool initialShowTour;

  const StudentHomeScreen({
    super.key,
    this.onNavigateToHistory,
    this.onNavigateToRewards,
    this.initialShowTour = false,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _nfcPulseActive = false;
  bool _showTour = false;
  late final RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _checkTourStatus();
  }

  void _checkTourStatus() async {
    if (widget.initialShowTour) {
      if (mounted) setState(() => _showTour = true);
    } else {
      final completed = await OnboardingService.isTourCompleted();
      if (!completed && mounted) {
        setState(() => _showTour = true);
      }
    }
  }

  void _initRazorpay() {
    _razorpayService = RazorpayService();
    _razorpayService.onSuccess = (response, amount) {
      if (!mounted) return;
      final walletVM = Provider.of<WalletViewModel>(context, listen: false);
      walletVM.addFunds(amount);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.successGreen, width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${amount.toInt()} Added to Campus Wallet!',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Razorpay ID: ${response.paymentId ?? "N/A"}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    };

    _razorpayService.onFailure = (response) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.errorRed, width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.errorRed,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Cancelled or Failed',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      response.message ?? 'Transaction could not be completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    };

    _razorpayService.onExternalWallet = (response) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Redirecting to ${response.walletName ?? "External Wallet"}...',
            style: GoogleFonts.plusJakartaSans(color: AppColors.white),
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _triggerNfcPulse() {
    HapticFeedback.heavyImpact();
    setState(() => _nfcPulseActive = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _nfcPulseActive = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerLow,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(
              Icons.contactless_rounded,
              color: AppColors.electricYellow,
            ),
            const SizedBox(width: 10),
            Text(
              'DBIT NFC Tap & Pay Armed (18.4 kHz)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startRazorpayTopUp(double amount) {
    try {
      _razorpayService.openCheckout(
        amount: amount,
        studentName: 'Manya Shah',
        studentEmail: 'manya.shah@dbit.ac.in',
        studentContact: '9876543210',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(
            'Unable to open Razorpay gateway: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _showAddMoneyModal() {
    HapticFeedback.lightImpact();
    final customAmountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.borderStroke)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Up Campus Wallet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.electricYellow,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Razorpay Gateway',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Instant recharge via UPI, Debit/Credit Card, or Netbanking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Quick preset buttons
              Row(
                children: [
                  _buildQuickAddBtn(ctx, 200),
                  const SizedBox(width: 8),
                  _buildQuickAddBtn(ctx, 500),
                  const SizedBox(width: 8),
                  _buildQuickAddBtn(ctx, 1000),
                ],
              ),
              const SizedBox(height: 16),

              // Custom Amount TextField
              TextField(
                controller: customAmountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    color: AppColors.electricYellow,
                    fontWeight: FontWeight.w800,
                  ),
                  hintText: 'Enter custom amount (e.g. 350)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderStroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.electricYellow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = customAmountController.text.trim();
                    final amt = double.tryParse(text);
                    if (amt != null && amt > 0) {
                      Navigator.pop(ctx);
                      _startRazorpayTopUp(amt);
                    }
                  },
                  icon: const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: AppColors.onElectricYellow,
                  ),
                  label: Text(
                    'Proceed to Razorpay Checkout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onElectricYellow,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddBtn(BuildContext ctx, double amount) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(ctx);
          _startRazorpayTopUp(amount);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLow,
          foregroundColor: AppColors.electricYellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.borderStroke),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Text(
          '+₹${amount.toInt()}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildHeader(context),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => walletVM.refresh(),
              color: AppColors.electricYellow,
              backgroundColor: AppColors.cardDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting Block ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Hey, Manya',
                                  style: GoogleFonts.bodoniModa(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'DBIT Mumbai • Campus mode: ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'ON',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _triggerNfcPulse,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _nfcPulseActive
                                  ? AppColors.electricYellow
                                  : AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _nfcPulseActive
                                    ? AppColors.electricYellow
                                    : AppColors.borderStroke,
                              ),
                            ),
                            child: Icon(
                              Icons.contactless_rounded,
                              size: 18,
                              color: _nfcPulseActive
                                  ? AppColors.onElectricYellow
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderStroke),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                size: 18,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Hero Wallet Card (ID-1 Aspect Ratio Style) ───────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B21A8),
                        Color(0xFF581C87),
                        Color(0xFF4C1D95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withValues(alpha: 0.38),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Vector Soundwave Lines Watermark
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: 0.2,
                          child: Row(
                            children: List.generate(8, (i) {
                              final heights = [30.0, 55.0, 80.0, 40.0, 70.0, 95.0, 50.0, 65.0];
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 3,
                                height: heights[i % heights.length],
                                decoration: BoxDecoration(
                                  color: AppColors.electricYellow,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shield_rounded,
                                      size: 14,
                                      color: AppColors.electricYellow,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Campus Wallet',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppColors.successGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Ready',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'AVAILABLE BALANCE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightPurpleDim,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Large Bodoni Moda Balance
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.electricYellow,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${walletVM.balance.toInt()}',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                '.00',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lightPurpleDim,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Card Footer
                          Container(
                            padding: const EdgeInsets.only(top: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TokenVaultScreen(),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.token_rounded,
                                          size: 16,
                                          color: AppColors.lightPurpleDim,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '${walletVM.unspentTokenCount} Offline Tokens',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _showAddMoneyModal,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: Text(
                                    'Add Money',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.electricYellow,
                                    foregroundColor: AppColors.onElectricYellow,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Fast Campus Actions Bento Grid (4 Columns) ───────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FAST CAMPUS ACTIONS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Smart Routing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // 1. Scan & Pay
                    _buildBentoAction(
                      icon: Icons.qr_code_scanner_rounded,
                      iconBg: AppColors.electricYellow.withValues(alpha: 0.2),
                      iconColor: AppColors.electricYellow,
                      label: 'Scan & Pay',
                      tagText: 'FAST',
                      tagBg: AppColors.electricYellow,
                      tagTextColor: AppColors.onElectricYellow,
                      hasDot: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanAndPayScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Send P2P
                    _buildBentoAction(
                      icon: Icons.send_rounded,
                      iconBg: AppColors.deepPurple.withValues(alpha: 0.35),
                      iconColor: AppColors.lightPurple,
                      label: 'Send P2P',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const P2pTransferScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Receive
                    _buildBentoAction(
                      icon: Icons.call_received_rounded,
                      iconBg: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurface,
                      label: 'Receive',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TokenVaultScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 4. USSD Offline
                    _buildBentoAction(
                      icon: Icons.dialpad_rounded,
                      iconBg: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurface,
                      label: 'USSD *99#',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UssdSessionScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Payment Mode Tri-Channel Protocol Card ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderStroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sensors_rounded,
                                size: 16,
                                color: AppColors.lightPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PAYMENT MODE READY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              'Zero-Drop Net',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildProtocolChip(
                            dotColor: AppColors.successGreen,
                            title: 'Online UPI',
                            subtitle: '(Active)',
                          ),
                          const SizedBox(width: 6),
                          _buildProtocolChip(
                            dotColor: AppColors.electricYellow,
                            title: 'Offline Wallet',
                            subtitle: '(${walletVM.unspentTokenCount} Cached)',
                          ),
                          const SizedBox(width: 6),
                          _buildProtocolChip(
                            dotColor: AppColors.lightPurple,
                            title: 'USSD',
                            subtitle: '(*99# Ready)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.borderStroke,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.offline_bolt_rounded,
                              size: 15,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ultrasonic + BLE offline protocol armed. Pay at canteen, printer, or library without internet.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── CampusCoins Rewards Bento Card ───────────────────────────
                GestureDetector(
                  onTap: () {
                    if (widget.onNavigateToRewards != null) {
                      widget.onNavigateToRewards!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CampusCoinsScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF1DCFF), Color(0xFFF1DBFF), Color(0xFFFFF7C2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderStroke,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5BFFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.deepPurple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${walletVM.coinsState.totalCoins}',
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Coins',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerLowest,
                                              borderRadius: BorderRadius.circular(
                                                9999,
                                              ),
                                            ),
                                            child: Text(
                                              '🔥 5-day streak',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${walletVM.coinsState.rupeeEquivalent.toStringAsFixed(0)} redemption value at campus stores',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: AppColors.cardElevation,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepPurpleAlt,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: AppColors.deepPurpleAlt,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Tactile Footer Statement ─────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.electricYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Money moved. Vibes intact.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.lightPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      if (_showTour)
        Positioned.fill(
          child: HomeTourOverlay(
            onFinish: () => setState(() => _showTour = false),
          ),
        ),
    ],
  ),
);
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/brand_logo.png',
            height: 32,
            errorBuilder: (_, _, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.electricYellow,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'DBIT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onElectricYellow,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CampusPay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'DBIT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSecondaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'DBIT Mumbai Campus',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _showTour = true),
          icon: const Icon(
            Icons.help_outline_rounded,
            size: 20,
            color: AppColors.onSurface,
          ),
          tooltip: 'App Tour',
        ),
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile_avatar.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'M',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoAction({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    String? tagText,
    Color? tagBg,
    Color? tagTextColor,
    bool hasDot = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (tagText != null)
                Positioned(
                  top: -8,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg ?? AppColors.electricYellow,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      tagText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: tagTextColor ?? AppColors.onElectricYellow,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      if (hasDot)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.electricYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolChip({
    required Color dotColor,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
