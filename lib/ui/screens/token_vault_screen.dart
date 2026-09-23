import 'package:flutter/material.dart';
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
        title: const Text('ECDSA TOKEN STORE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.electricYellow),
            tooltip: 'Replenish Token Batch',
            onPressed: () {
              walletVM.replenishTokens();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.cardDark,
                  content: Text(
                    'Fetched fresh batch of 10 ECDSA secp256k1 tokens with 48hr expiry.',
                    style: TextStyle(color: AppColors.electricYellow),
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
            // Header stats
            Row(
              children: [
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.electricYellow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ACTIVE TOKENS', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.mutedText)),
                        const SizedBox(height: 4),
                        Text(
                          '${walletVM.availableTokenCount} OF 10',
                          style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.lightPurple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BATCH EXPIRY', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.mutedText)),
                        const SizedBox(height: 4),
                        Text(
                          tokens.isNotEmpty ? tokens.first.remainingTimeFormatted : '48h 00m',
                          style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightPurple),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Token Batch Grid
            const Text(
              'CRYPTOGRAPHIC PRE-AUTH POOL',
              style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            const SizedBox(height: 8),

            ...tokens.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final t = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FintechCard(
                  leftBorderColor: t.isUsed ? AppColors.borderStroke : AppColors.electricYellow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TokenStatusBadge(token: t, index: idx),
                      Text(
                        'Limit: ₹${t.maxAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Security Callout Boxes Section (From Architecture Poster)
            const Text(
              'SECURITY INVARIANTS & HARDWARE AUDIT',
              style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            const SizedBox(height: 12),

            _buildCallout(
              icon: '🔐',
              title: 'AES-256 GCM AT REST',
              desc: 'Wallet balance is encrypted on-device with keys wrapped by the hardware secure enclave.',
            ),
            _buildCallout(
              icon: '🔑',
              title: 'ECDSA secp256k1 ASYMMETRIC SIGNING',
              desc: 'Device private key never leaves the device. Payloads are signed with elliptic curve cryptography.',
            ),
            _buildCallout(
              icon: '🎲',
              title: 'UUID NONCE (ANTI-REPLAY)',
              desc: 'Every payment embeds an ephemeral UUID. SoundBoxes reject any previously seen nonces.',
            ),
            _buildCallout(
              icon: '1️⃣',
              title: 'SINGLE USE TOKEN ENFORCEMENT',
              desc: 'Token is marked USED locally in SQLite prior to audio/BLE burst, preventing double spend.',
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

  Widget _buildCallout({required String icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDarker,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricYellow,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.35),
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
