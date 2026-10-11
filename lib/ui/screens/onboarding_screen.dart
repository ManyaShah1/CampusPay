import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/onboarding_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await OnboardingService.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(startTour: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/campus_pay_logo.png',
                      height: 28,
                      errorBuilder: (_, _, _) => const SizedBox(width: 28, height: 28),
                    ),
                    if (_currentPage < 3)
                      GestureDetector(
                        onTap: _finishOnboarding,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              ),

              // PageView Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  children: [
                    _buildScreen1(),
                    _buildScreen2(),
                    _buildScreen3(),
                    _buildScreen4(),
                  ],
                ),
              ),

              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: _buildBottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Screen 1: Welcome to CampusPay ──────────────────────────────────────────
  Widget _buildScreen1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome to\n',
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1329),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                TextSpan(
                  text: 'CampusPay',
                  style: GoogleFonts.fraunces(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1329),
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pay, receive and explore\nDBIT campus – online or offline.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/screen1_graphic.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Screen 2: Pay Anywhere On Campus ───────────────────────────────────────
  Widget _buildScreen2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Pay Anywhere\nOn Campus',
            style: GoogleFonts.fraunces(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1329),
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan any merchant QR or use\nSoundBox to pay in seconds.\nWorks online and offline.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/screen2_graphic.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Feature Grid Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE8F5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScreen2Pill(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan & Pay',
                  iconColor: const Color(0xFF1F1A24),
                  boxColor: AppColors.electricYellow,
                ),
                _buildScreen2Pill(
                  icon: Icons.graphic_eq_rounded,
                  label: 'SoundBox',
                  iconColor: Colors.white,
                  boxColor: const Color(0xFF6B21A8),
                ),
                _buildScreen2Pill(
                  icon: Icons.people_alt_rounded,
                  label: 'P2P',
                  iconColor: const Color(0xFF6B21A8),
                  boxColor: const Color(0xFFF1DBFF),
                ),
                _buildScreen2Pill(
                  icon: Icons.link_rounded,
                  label: 'USSD',
                  iconColor: const Color(0xFF6B21A8),
                  boxColor: const Color(0xFFF1DBFF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildScreen2Pill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color boxColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1727),
          ),
        ),
      ],
    );
  }

  // ── Screen 3: Works Offline Too ────────────────────────────────────────────
  Widget _buildScreen3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Works\nOffline Too',
            style: GoogleFonts.fraunces(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1329),
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pay using SoundBox, Bluetooth,\nNFC or USSD. No internet needed.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/screen3_graphic.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Benefits Checklist
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE8F5)),
            ),
            child: Column(
              children: [
                _buildCheckRow('Instant & Secure'),
                const SizedBox(height: 10),
                _buildCheckRow('Works across campus'),
                const SizedBox(height: 10),
                _buildCheckRow('Syncs automatically later'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1A24),
          ),
        ),
      ],
    );
  }

  // ── Screen 4: Earn Rewards Every Day ───────────────────────────────────────
  Widget _buildScreen4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Earn Rewards\nEvery Day',
            style: GoogleFonts.fraunces(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C1329),
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pay, participate and unlock\nexciting rewards, campus deals\nand event passes.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/screen4_graphic.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rewards Category Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE8F5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardChip(
                  icon: Icons.star_rounded,
                  iconBg: const Color(0xFFFFF7C2),
                  iconColor: const Color(0xFFD97706),
                  label: 'Earn Coins',
                ),
                _buildRewardChip(
                  icon: Icons.card_giftcard_rounded,
                  iconBg: const Color(0xFFF1DBFF),
                  iconColor: const Color(0xFF6B21A8),
                  label: 'Redeem Deals',
                ),
                _buildRewardChip(
                  icon: Icons.confirmation_number_rounded,
                  iconBg: const Color(0xFFF1DBFF),
                  iconColor: const Color(0xFF6B21A8),
                  label: 'Event Passes',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1727),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation Bar & Pagination ────────────────────────────────────
  Widget _buildBottomBar() {
    if (_currentPage == 0) {
      // Screen 1: Centered pagination dots + Full Width "Get Started ->" button
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPaginationDots(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricYellow,
                foregroundColor: const Color(0xFF1C1917),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Color(0xFF1C1917),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Screens 2, 3, 4: Row with [Back] [Dots] [Next / Let's Go ->]
    final isLast = _currentPage == 3;
    final nextBtnText = isLast ? "Let's Go" : 'Next';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back text button
        GestureDetector(
          onTap: _onBack,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              'Back',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B21A8),
              ),
            ),
          ),
        ),

        // Pagination Dots
        _buildPaginationDots(),

        // Next or Let's Go yellow button
        ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricYellow,
            foregroundColor: const Color(0xFF1C1917),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nextBtnText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1917),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF1C1917),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6B21A8) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
