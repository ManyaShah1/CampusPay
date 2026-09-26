import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/audio/acoustic_carrier.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import 'payment_success_screen.dart';

class OfflinePaymentScreen extends StatefulWidget {
  final String merchantName;
  final String counter;
  final String vendorId;
  final double amount;

  const OfflinePaymentScreen({
    super.key,
    this.merchantName = 'Campus Café',
    this.counter = 'Counter 3',
    this.vendorId = 'CPV001',
    this.amount = 120.0,
  });

  @override
  State<OfflinePaymentScreen> createState() => _OfflinePaymentScreenState();
}

class _OfflinePaymentScreenState extends State<OfflinePaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  int _currentStep = 1; // 1: Chirp transmitted, 2: Verification, 3: Completed
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _playUltrasoundAndProgress();
  }

  void _playUltrasoundAndProgress() {
    try {
      AcousticCarrier().emitUltrasonicBurst(
        rawPayload: 'OFFLINE_PAY_${widget.vendorId}_${widget.amount}',
        nonce: '9948-AX',
        amount: widget.amount,
      );
    } catch (_) {}

    _stepTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _currentStep = 2);
        _stepTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) {
            _completeTransaction();
          }
        });
      }
    });
  }

  void _completeTransaction() {
    final walletVM = context.read<WalletViewModel>();
    walletVM.deductOffline(widget.amount, merchant: widget.merchantName);

    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          merchantName: widget.merchantName,
          counter: widget.counter,
          amount: widget.amount,
          transactionId: 'CPX8F29A1',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildHeader(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // ── Top Ambient Security Banner ───────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
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
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.lightPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Air-Gapped Offline Vault • 18.4 kHz Chirp',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.electricYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Hero Ultrasonic Acoustic Link Card ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderStroke),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Node: Student Handset
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.deepPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.smartphone_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.electricYellow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.wifi_tethering_rounded,
                                      size: 11,
                                      color: AppColors.onElectricYellow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STUDENT HANDSET',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AppColors.electricYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Internal Piezo Speaker',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.borderStroke),
                          ),
                          child: Text(
                            'TOKEN #08/10',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Center Animated Acoustic Wave Transmitter
                    Container(
                      height: 110,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(double.infinity, 110),
                                painter: _AcousticWavePainter(
                                  progress: _waveController.value,
                                ),
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: AppColors.borderStroke,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.electricYellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '18,432 Hz ACOUSTIC CARRIER',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Node: Campus Soundbox
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.speaker_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.electricYellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CAMPUS SOUNDBOX',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Counter 3 Canteen (POS Node)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.electricYellow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sensors_rounded,
                                size: 13,
                                color: AppColors.onElectricYellow,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PAIRING ACTIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onElectricYellow,
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

              const SizedBox(height: 14),

              // ── Payment Merchant & Amount Voucher Card ────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/cafe_stall.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_cafe_rounded,
                                    color: AppColors.lightPurple,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PAYING MERCHANT',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Campus Café (Counter 3)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#CC-049',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Amount display bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${widget.amount.toInt()}',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                '.00',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.electricYellow,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              'OFFLINE ZERO-PIN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onElectricYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Cryptographic Metadata Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.key_rounded,
                              size: 14,
                              color: AppColors.lightPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ECDSA P-256 Auth',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.security_update_good_rounded,
                              size: 14,
                              color: AppColors.electricYellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Nonce #9948-AX',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Cryptographic Transmission Progress Steps Card ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACOUSTIC HANDSHAKE PROTOCOL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Step 1: Chirp
                    _buildStepRow(
                      icon: Icons.check_rounded,
                      iconBg: AppColors.successGreen,
                      iconColor: AppColors.surfaceContainerLowest,
                      title: '18.4 kHz Ultrasonic Chirp',
                      subtitle: 'Modulated payload broadcast',
                      badgeText: 'DONE',
                      badgeBg: AppColors.surfaceContainerHigh,
                      badgeColor: AppColors.successGreen,
                    ),

                    const SizedBox(height: 10),

                    // Step 2: Signature
                    _buildStepRow(
                      icon: Icons.sync_rounded,
                      iconBg: AppColors.deepPurple,
                      iconColor: AppColors.lightPurple,
                      title: 'ECDSA Signature & Nonce Verify',
                      subtitle: _currentStep >= 2
                          ? 'Cryptographic handshake validated'
                          : 'Mutual cross-counter handshake...',
                      badgeText: _currentStep >= 2 ? 'VERIFIED' : 'ACTIVE',
                      badgeBg: _currentStep >= 2
                          ? AppColors.successGreen
                          : AppColors.deepPurple,
                      badgeColor: AppColors.white,
                      isAnimated: _currentStep < 2,
                    ),

                    const SizedBox(height: 10),

                    // Step 3: Standby Fallback
                    _buildStepRow(
                      icon: Icons.bluetooth_rounded,
                      iconBg: AppColors.surfaceContainer,
                      iconColor: AppColors.onSurfaceVariant,
                      title: 'BLE Fallback Channel',
                      subtitle: 'Hot standby if acoustic dampens',
                      badgeText: 'STANDBY',
                      badgeBg: AppColors.surfaceContainerHigh,
                      badgeColor: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricYellow,
                    foregroundColor: AppColors.onElectricYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.electricYellow.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.onElectricYellow,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRANSMITTING AUDIO CHIRP (18.4 kHz)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Cancel Transaction',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Reassurance
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_sync_rounded,
                    size: 15,
                    color: AppColors.lightPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offline, but always on. Auto-reconciles on reconnect.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'DBIT Zero-Latency Settlement • Secure Enclave Enabled',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Text(
        'Payment Transfer',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'UPI 128-bit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    bool isAnimated = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _AcousticWavePainter extends CustomPainter {
  final double progress;
  _AcousticWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 4; i++) {
      final waveProgress = (progress + i * 0.25) % 1.0;
      final radius = 20 + waveProgress * 40;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = (i % 2 == 0 ? AppColors.electricYellow : AppColors.lightPurple)
            .withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AcousticWavePainter oldDelegate) => true;
}
