import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import 'campus_coins_screen.dart';
import 'p2p_transfer_screen.dart';
import 'scan_and_pay_screen.dart';
import 'token_vault_screen.dart';
import 'ussd_session_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onNavigateToRewards;

  const StudentHomeScreen({
    super.key,
    this.onNavigateToHistory,
    this.onNavigateToRewards,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _nfcPulseActive = false;

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

  void _showAddMoneyModal() {
    HapticFeedback.lightImpact();
    final walletVM = context.read<WalletViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
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
              Text(
                'Top Up Campus Wallet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select an amount to recharge via campus bank gateway',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildQuickAddBtn(ctx, 200, walletVM),
                  const SizedBox(width: 8),
                  _buildQuickAddBtn(ctx, 500, walletVM),
                  const SizedBox(width: 8),
                  _buildQuickAddBtn(ctx, 1000, walletVM),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddBtn(
    BuildContext ctx,
    double amount,
    WalletViewModel walletVM,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          walletVM.addFunds(amount);
          HapticFeedback.mediumImpact();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceContainerLow,
              content: Text(
                '₹${amount.toInt()} added to Campus Wallet!',
                style: GoogleFonts.plusJakartaSans(color: AppColors.white),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
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
      body: SafeArea(
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
                                  'Good morning, Manya',
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

                const SizedBox(height: 20),

                // ── Recent Campus Activity ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Campus Activity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onNavigateToHistory != null) {
                          widget.onNavigateToHistory!();
                        }
                      },
                      child: Text(
                        'See All >',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightPurple,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildActivityTile(
                  icon: Icons.restaurant_rounded,
                  iconBg: AppColors.electricYellow.withValues(alpha: 0.15),
                  iconColor: AppColors.electricYellow,
                  title: 'Campus Canteen',
                  badge: 'SOUNDBOX',
                  badgeBg: AppColors.electricYellow,
                  badgeColor: AppColors.onElectricYellow,
                  time: 'Today, 11:42 AM',
                  amount: '-₹120.00',
                  subtitle: 'Verified instant',
                  subtitleColor: AppColors.successGreen,
                ),

                const SizedBox(height: 8),

                _buildActivityTile(
                  icon: Icons.local_cafe_rounded,
                  iconBg: AppColors.deepPurple.withValues(alpha: 0.3),
                  iconColor: AppColors.lightPurple,
                  title: 'Central Library Café',
                  badge: 'UPI',
                  badgeBg: AppColors.successGreen.withValues(alpha: 0.2),
                  badgeColor: AppColors.successGreen,
                  time: 'Yesterday, 4:15 PM',
                  amount: '-₹80.00',
                  subtitle: '+8 CampusCoins',
                  subtitleColor: AppColors.onSurfaceVariant,
                ),

                const SizedBox(height: 8),

                _buildActivityTile(
                  icon: Icons.menu_book_rounded,
                  iconBg: AppColors.surfaceContainerHigh,
                  iconColor: AppColors.lightPurple,
                  title: 'University Stationery',
                  badge: 'BLE OFFLINE',
                  badgeBg: AppColors.deepPurple,
                  badgeColor: AppColors.white,
                  time: 'Yesterday, 1:20 PM',
                  amount: '-₹240.00',
                  subtitle: 'Synced offline',
                  subtitleColor: AppColors.successGreen,
                ),

                const SizedBox(height: 24),

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

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String time,
    required String amount,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.bodoniModa(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
