import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/onboarding_service.dart';

class TourStep {
  final String stepTag;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final String buttonText;

  const TourStep({
    required this.stepTag,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.bulletPoints,
    required this.buttonText,
  });
}

class HomeTourOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const HomeTourOverlay({super.key, required this.onFinish});

  @override
  State<HomeTourOverlay> createState() => _HomeTourOverlayState();
}

class _HomeTourOverlayState extends State<HomeTourOverlay> {
  int _currentStep = 0;

  final List<TourStep> _steps = const [
    TourStep(
      stepTag: 'STEP 1 OF 4 • OFFLINE WALLET',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.electricYellow,
      iconBg: Color(0xFF4C1D95),
      title: 'Encrypted Campus Wallet',
      description:
          'Your offline balance is secured with on-device AES-256 encryption. Tap "Add Money" anytime to recharge using Razorpay with UPI or cards.',
      bulletPoints: [
        'Live dynamic balance with zero mock data',
        '10 pre-signed ECDSA cryptographic tokens',
        'Instant Razorpay checkout top-up gateway',
      ],
      buttonText: 'Next: Fast Actions ➔',
    ),
    TourStep(
      stepTag: 'STEP 2 OF 4 • FAST ACTIONS',
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Color(0xFF1C1917),
      iconBg: AppColors.electricYellow,
      title: 'Scan & Pay Anywhere',
      description:
          'Pay in seconds at DBIT canteen, stationery, or xerox shops. Scan merchant QR codes using your camera or send peer-to-peer funds offline.',
      bulletPoints: [
        'Camera QR scanner with UPI ID & number parsing',
        'P2P offline transfer directly to classmates',
        'Offline USSD *99# dialing for zero-net fallback',
      ],
      buttonText: 'Next: Offline Mode ➔',
    ),
    TourStep(
      stepTag: 'STEP 3 OF 4 • ZERO INTERNET',
      icon: Icons.sensors_rounded,
      iconColor: Colors.white,
      iconBg: Color(0xFF7C3AED),
      title: 'Works Without Internet',
      description:
          'Never worry about weak mobile coverage in basement canteens. CampusPay transmits secure tokens over ultrasonic sound waves and Bluetooth.',
      bulletPoints: [
        'Zero-drop acoustic & BLE soundwave payments',
        'Hardware SoundBox verification ready',
        'Local ledger syncs automatically when online',
      ],
      buttonText: 'Next: Rewards ➔',
    ),
    TourStep(
      stepTag: 'STEP 4 OF 4 • REWARDS VAULT',
      icon: Icons.stars_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFFF7C2),
      title: 'Earn Rewards Every Day',
      description:
          'Collect CampusCoins with every transaction across college. Redeem them at the campus vault for free coffee, snacks, and event passes.',
      bulletPoints: [
        'Automatic coin accrual on every campus spend',
        'Daily login streak multipliers',
        'Instant voucher redemption at campus stalls',
      ],
      buttonText: "Explore CampusPay 🚀",
    ),
  ];

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    await OnboardingService.completeTour();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Stack(
          children: [
            // Centered Tour Guide Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Step Tag + Skip button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1DBFF),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              step.stepTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6B21A8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _finishTour,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Step Icon
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: step.iconBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: step.iconBg.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(step.icon, color: step.iconColor, size: 28),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        step.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1727),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        step.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bullet Points
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: step.bulletPoints.map((point) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F2937),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dots Indicator
                          Row(
                            children: List.generate(_steps.length, (index) {
                              final isActive = index == _currentStep;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF6B21A8)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),

                          // Action Buttons
                          Row(
                            children: [
                              if (_currentStep > 0)
                                TextButton(
                                  onPressed: _prevStep,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B21A8),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.electricYellow,
                                  foregroundColor: const Color(0xFF1C1917),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  step.buttonText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1C1917),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
