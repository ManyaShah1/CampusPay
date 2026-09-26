import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../widgets/fintech_card.dart';
import '../widgets/token_status_badge.dart';

class TokenVaultScreen extends StatelessWidget {
  const TokenVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final tokens = walletVM.tokens;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'ECDSA TOKEN VAULT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        backgroundColor: AppColors.surfaceContainerLowest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.electricYellow),
            tooltip: 'Replenish Token Batch',
            onPressed: () {
              walletVM.replenishTokens();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Fetched fresh batch of 10 ECDSA secp256k1 tokens (48hr expiry).',
                    style: TextStyle(color: AppColors.successGreen),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Row ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.electricYellow,
                    glow: AppColors.yellowGlow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE TOKENS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppColors.mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${walletVM.availableTokenCount} OF 10',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.lightPurple,
                    glow: AppColors.purpleGlow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BATCH EXPIRY',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppColors.mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tokens.isNotEmpty
                              ? tokens.first.remainingTimeFormatted
                              : '48h 00m',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lightPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Token Batch ───────────────────────────────────────────────
            Text(
              'CRYPTOGRAPHIC PRE-AUTH POOL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...tokens.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final t = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FintechCard(
                  leftBorderColor:
                      t.isUsed ? AppColors.borderStroke : AppColors.electricYellow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TokenStatusBadge(token: t, index: idx),
                      Text(
                        'Limit: ₹${t.maxAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // ── Security Invariants ───────────────────────────────────────
            Text(
              'SECURITY INVARIANTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildCallout(
              icon: '🔐',
              title: 'AES-256 GCM AT REST',
              desc: 'Wallet balance encrypted on-device with keys wrapped by the hardware secure enclave.',
            ),
            _buildCallout(
              icon: '🔑',
              title: 'ECDSA secp256k1 ASYMMETRIC SIGNING',
              desc: 'Device private key never leaves the device. Payloads signed with elliptic curve cryptography.',
            ),
            _buildCallout(
              icon: '🎲',
              title: 'UUID NONCE (ANTI-REPLAY)',
              desc: 'Every payment embeds an ephemeral UUID. SoundBoxes reject previously seen nonces.',
            ),
            _buildCallout(
              icon: '1️⃣',
              title: 'SINGLE-USE TOKEN ENFORCEMENT',
              desc: 'Token marked USED in SQLite prior to audio/BLE burst, preventing double spend.',
            ),
            _buildCallout(
              icon: '⏱',
              title: '48-HOUR ROLLING EXPIRY',
              desc: 'Forces regular online synchronization with the DBIT campus settlement server.',
            ),
            _buildCallout(
              icon: '🔒',
              title: 'DUAL LEDGER RECONCILIATION',
              desc: 'Token ID must match in both student debit journal AND vendor SoundBox credit log.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallout({
    required String icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricYellow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
