import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import 'token_vault_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

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
              Container(
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
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/profile_avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    'MS',
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                          'Manya Shah',
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
                            color: AppColors.electricYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.electricYellow,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),
                    Text(
                      'DBIT Mumbai • B.Tech Computer Engineering',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.lightPurpleDim,
                      ),
                    ),

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
                            'Student ID: DBIT2024021',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        'Edit Profile',
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
                  ],
                ),
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
                      value: '₹2,450.00',
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
              Text(
                sublabel,
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
