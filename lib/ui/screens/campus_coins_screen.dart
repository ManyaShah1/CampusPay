import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../widgets/fintech_card.dart';

class CampusCoinsScreen extends StatelessWidget {
  const CampusCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final coins = walletVM.coinsState;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('CAMPUSCOINS LOYALTY'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Coin Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.electricYellow, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricYellow.withOpacity(0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    '${coins.totalCoins}',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.electricYellow,
                    ),
                  ),
                  Text(
                    'Worth ₹${coins.rupeeEquivalent.toStringAsFixed(1)} off your next DBIT meal',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.lightMutedText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarker,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.electricYellow.withOpacity(0.5)),
                    ),
                    child: Text(
                      '🔥 ${coins.streakDays}-DAY ACTIVE STREAK',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.electricYellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Earn Rules Grid
            const Text(
              'EARNING RULES & MULTIPLIERS',
              style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.electricYellow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('VENDOR CHECKOUT', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.mutedText)),
                        SizedBox(height: 4),
                        Text('2 COINS / ₹10', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
                        Text('At all DBIT canteens', style: TextStyle(fontSize: 10, color: AppColors.lightMutedText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.lightPurple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('P2P AIRGAP', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.mutedText)),
                        SizedBox(height: 4),
                        Text('1 COIN / ₹10', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
                        Text('Student split bills', style: TextStyle(fontSize: 10, color: AppColors.lightMutedText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            FintechCard(
              leftBorderColor: AppColors.successGreen,
              child: Row(
                children: const [
                  Text('⚡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'BONUS: 3 DBIT shops visited in 1 day = +20 Coins • 5-day streak = +50 Coins',
                      style: TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Activity History
            const Text(
              'COIN ACTIVITY LEDGER',
              style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white),
            ),
            const SizedBox(height: 10),

            ...coins.history.map((act) {
              final dateStr = DateFormat('dd MMM, hh:mm a').format(
                DateTime.fromMillisecondsSinceEpoch(act.timestamp),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FintechCard(
                  leftBorderColor: act.isBonus ? AppColors.electricYellow : AppColors.lightPurple,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(act.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white)),
                          const SizedBox(height: 2),
                          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                        ],
                      ),
                      Text(
                        '+${act.coinsDelta}',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: act.isBonus ? AppColors.electricYellow : AppColors.lightPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
