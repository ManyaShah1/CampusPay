import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/student_profile.dart';
import '../auth/login_signup_page.dart' show AuthService, ProfileAuthButton;
import '../viewmodels/wallet_viewmodel.dart';
import 'token_vault_screen.dart';
import 'onboarding_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  void _showCompleteProfileSheet(BuildContext context, StudentProfile student) {
    final collegeCtrl = TextEditingController(
      text: student.collegeName?.isNotEmpty == true
          ? student.collegeName
          : 'Don Bosco Institute of Technology (DBIT Mumbai)',
    );
    String selectedBranch = student.branch?.isNotEmpty == true
        ? student.branch!
        : 'Computer Engineering';
    String selectedYear = student.year?.isNotEmpty == true
        ? student.year!
        : 'TE - 3rd Year';

    final branches = [
      'Computer Engineering',
      'Information Technology',
      'Electronics & Telecommunication (EXTC)',
      'Mechanical Engineering',
      'Artificial Intelligence & Data Science (AI & DS)',
    ];

    if (!branches.contains(selectedBranch)) {
      branches.insert(0, selectedBranch);
    }

    final years = [
      'FE - 1st Year',
      'SE - 2nd Year',
      'TE - 3rd Year',
      'BE - 4th Year',
    ];

    if (!years.contains(selectedYear)) {
      years.insert(0, selectedYear);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.electricYellow.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.onSurface,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Secondary information: College, Branch & Year',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. College Name
                    Text(
                      'COLLEGE NAME',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: collegeCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.account_balance_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Department / Branch
                    Text(
                      'ENGINEERING BRANCH / DEPARTMENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedBranch,
                      items: branches.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text(b, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedBranch = val);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.engineering_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Year of Study
                    Text(
                      'ACADEMIC YEAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedYear,
                      items: years.map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedYear = val);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricYellow,
                          foregroundColor: AppColors.onElectricYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await AuthService.updateSecondaryInfo(
                            collegeName: collegeCtrl.text,
                            branch: selectedBranch,
                            year: selectedYear,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Academic profile updated successfully!'),
                                backgroundColor: Color(0xFF6A1B9A),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Save Academic Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildHeader(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Identity Canvas Card (Vault Theme) ─────────────────────
              ValueListenableBuilder<StudentProfile?>(
                valueListenable: AuthService.currentStudent,
                builder: (context, student, _) {
                  final isLoggedIn = student != null;
                  final fullName = isLoggedIn ? student.fullName : 'Guest Student';
                  final initial = isLoggedIn && student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : 'G';
                  final isComplete = student?.isSecondaryComplete ?? false;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B21A8), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepPurple.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with Neon Rim
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.electricYellow,
                                    AppColors.lightPurple,
                                  ],
                                ),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceContainerLowest,
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isComplete)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.electricYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColors.onElectricYellow,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isLoggedIn && isComplete)
                                    ? AppColors.electricYellow.withValues(alpha: 0.2)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                isLoggedIn
                                    ? (isComplete ? 'Verified Student' : 'Incomplete (Step 2/2)')
                                    : 'Guest',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: (isLoggedIn && isComplete)
                                      ? AppColors.electricYellow
                                      : const Color(0xFFFBBF24),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),
                        Text(
                          isLoggedIn
                              ? (isComplete
                                  ? '${student.collegeName} • ${student.branch} • ${student.year}'
                                  : 'Academic Details Incomplete')
                              : 'Explore mode • DBIT Mumbai',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.lightPurpleDim,
                          ),
                        ),

                        if (isLoggedIn) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_rounded,
                                  size: 15,
                                  color: AppColors.electricYellow,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Student ID: ${student.studentId}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Prompt banner if secondary information is incomplete
                        if (isLoggedIn && !isComplete) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Academic Profile Incomplete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add your College, Branch, and Academic Year to unlock campus discounts and exam fee settlements.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF59E0B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _showCompleteProfileSheet(context, student),
                                    child: const Text(
                                      'Complete Profile Now (Step 2 of 2)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        if (isLoggedIn)
                          ElevatedButton.icon(
                            onPressed: () => _showCompleteProfileSheet(context, student),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: Text(
                              isComplete ? 'Edit Academic Profile' : 'Complete Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.electricYellow,
                              foregroundColor: AppColors.onElectricYellow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              elevation: 0,
                            ),
                          ),

                        const SizedBox(height: 10),
                        const ProfileAuthButton(),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── Quick Metrics Triptych ────────────────────────────────────
              Row(
                children: [
                  // Wallet Balance
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'WALLET',
                      value: '₹${walletVM.balance.toStringAsFixed(2)}',
                      sublabel: 'DBIT Vault',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CampusCoins
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.toll_rounded,
                      label: 'COINS',
                      value: '${walletVM.coinsState.totalCoins}',
                      sublabel:
                      '₹${walletVM.coinsState.rupeeEquivalent.toStringAsFixed(0)} value',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Offline Tokens
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.wifi_off_rounded,
                      label: 'OFFLINE',
                      value: '${walletVM.unspentTokenCount}/10',
                      sublabel: 'Active',
                      isStatusDot: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── DBIT NFC Pass Indicator Banner ────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.lightPurple.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.contactless_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DBIT Campus Tap & Dine',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fast Canteen checkouts & Turnstile entry',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
                        'SYNCD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Settings & Parameter List ─────────────────────────────────
              Text(
                'ACCOUNT & PARAMETERS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.person_rounded,
                title: 'Personal Details',
                subtitle: 'Contact, Guardian Info & KYC',
                onTap: () {},
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.savings_rounded,
                title: 'Wallet & Offline Limits',
                subtitle: '47h token expiry • Auto-reload ready',
                badgeText: '47h left',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TokenVaultScreen()),
                ),
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'Security & Biometric Locks',
                subtitle: 'ECDSA P-256 Hardware Enclave',
                onTap: () {},
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.speaker_phone_rounded,
                title: 'Payment Preferences & SoundBox',
                subtitle: 'DBIT Canteen Pods audio feedback',
                onTap: () {},
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications Center',
                subtitle: 'Bill splits, campus alerts & receipts',
                onTap: () {},
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.explore_rounded,
                title: 'Replay App Tour & Onboarding',
                subtitle: 'Walk through features and visual guide',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),

              _buildSettingsTile(
                icon: Icons.support_agent_rounded,
                title: 'Help & Support',
                subtitle: 'DBIT IT Helpdesk • Block A, Room 102',
                onTap: () {},
              ),

              const SizedBox(height: 30),
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
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/brand_logo.png',
            width: 26,
            height: 26,
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusPay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
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
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    bool isStatusDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.lightPurple),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.bodoniModa(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              if (isStatusDot) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.electricYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  sublabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
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
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.deepPurpleAlt, size: 20),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricYellow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onElectricYellow,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
