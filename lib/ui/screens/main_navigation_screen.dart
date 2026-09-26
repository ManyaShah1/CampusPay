import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'campus_coins_screen.dart';
import 'profile_settings_screen.dart';
import 'scan_and_pay_screen.dart';
import 'student_home_screen.dart';
import 'transactions_ledger_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StudentHomeScreen(
        onNavigateToHistory: () => setState(() => _currentIndex = 1),
        onNavigateToRewards: () => setState(() => _currentIndex = 3),
      ),
      const TransactionsLedgerScreen(),
      const SizedBox.shrink(), // Center button placeholder
      const CampusCoinsScreen(),
      const ProfileSettingsScreen(),
    ];
  }

  void _onCenterScanPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanAndPayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildStitchNavBar(),
    );
  }

  Widget _buildStitchNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AppColors.borderStroke, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0: Home
              _buildNavItem(
                index: 0,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Home',
              ),

              // 1: History
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'History',
              ),

              // 2: Center Floating Scan & Pay Button
              GestureDetector(
                onTap: _onCenterScanPressed,
                child: Container(
                  width: 54,
                  height: 54,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.electricYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricYellow.withValues(alpha: 0.55),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.onElectricYellow,
                    size: 28,
                  ),
                ),
              ),

              // 3: Rewards
              _buildNavItem(
                index: 3,
                icon: Icons.stars_rounded,
                label: 'Rewards',
              ),

              // 4: Profile
              _buildNavItem(
                index: 4,
                icon: Icons.badge_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.lightPurple : AppColors.mutedText;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
