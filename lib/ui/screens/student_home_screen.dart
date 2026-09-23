import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_record.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../widgets/fintech_card.dart';
import 'campus_coins_screen.dart';
import 'payment_flow_screen.dart';
import 'p2p_transfer_screen.dart';
import 'token_vault_screen.dart';
import 'ussd_session_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.electricYellow),
              ),
              child: const Text(
                'DBIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.electricYellow,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('CAMPUSPAY'),
          ],
        ),
        actions: [
          // Network status toggle button (Simulate Offline / Online)
          TextButton.icon(
            onPressed: () => walletVM.toggleNetworkStatus(),
            icon: Icon(
              walletVM.isOnline ? Icons.wifi : Icons.wifi_off_rounded,
              size: 16,
              color: walletVM.isOnline ? AppColors.successGreen : AppColors.amberAccent,
            ),
            label: Text(
              walletVM.isOnline ? 'ONLINE' : 'ZERO-NET',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: walletVM.isOnline ? AppColors.successGreen : AppColors.amberAccent,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.white),
            tooltip: 'Reconcile Ledgers',
            onPressed: () async {
              final count = await walletVM.syncLedger();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.cardDark,
                    content: Text(
                      'Reconciliation complete. $count transactions settled with server ledger.',
                      style: const TextStyle(color: AppColors.successGreen),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => walletVM.refresh(),
        color: AppColors.electricYellow,
        backgroundColor: AppColors.cardDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Campus Wallet Card
              _buildWalletHeroCard(context, walletVM, currencyFormat),
              const SizedBox(height: 16),

              // Payment Tier Mode Pills
              _buildPaymentTierChips(),
              const SizedBox(height: 20),

              // Primary Action Buttons
              _buildQuickActions(context, walletVM),
              const SizedBox(height: 24),

              // CampusCoins Gamification Strip
              _buildCampusCoinsBanner(context, walletVM),
              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LOCAL LEDGER (SQLITE)',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarker,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Text(
                      'IMMUTABLE JOURNAL',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9.5,
                        color: AppColors.lightPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Transaction List
              if (walletVM.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No transactions recorded yet.'),
                  ),
                )
              else
                ...walletVM.transactions.map((txn) => _buildTransactionTile(txn)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHeroCard(
    BuildContext context,
    WalletViewModel walletVM,
    NumberFormat currencyFormat,
  ) {
    return Container(
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
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.electricYellow),
                  const SizedBox(width: 6),
                  Text(
                    'CAMPUS WALLET (AES-256)',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricYellow,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TokenVaultScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.deepPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.lightPurple),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key_rounded, size: 12, color: AppColors.lightPurple),
                      const SizedBox(width: 4),
                      Text(
                        '${walletVM.availableTokenCount}/10 TOKENS',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            currencyFormat.format(walletVM.balance),
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student: Aarav Sharma (TE-IT-42)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              Text(
                'Max ₹500/offline txn',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.lightPurple,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTierChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTierBadge(
            title: 'TIER 1 • ONLINE UPI',
            color: AppColors.successGreen,
            desc: 'Razorpay / NPCI',
          ),
          const SizedBox(width: 8),
          _buildTierBadge(
            title: 'TIER 2 • OFFLINE AIRGAP',
            color: AppColors.electricYellow,
            desc: '18-22kHz + BLE',
          ),
          const SizedBox(width: 8),
          _buildTierBadge(
            title: 'TIER 3 • SILENT USSD',
            color: AppColors.lightPurple,
            desc: '*99# Cellular',
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge({
    required String title,
    required Color color,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WalletViewModel walletVM) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        FintechCard(
          leftBorderColor: AppColors.electricYellow,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentFlowScreen()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner_rounded, color: AppColors.electricYellow, size: 28),
              SizedBox(height: 8),
              Text(
                'PAY MERCHANT',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Scan QR • Sound + BLE',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        FintechCard(
          leftBorderColor: AppColors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const P2pTransferScreen()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.people_alt_rounded, color: AppColors.lightPurple, size: 28),
              SizedBox(height: 8),
              Text(
                'P2P AIRGAP SEND',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Student-to-Student',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        FintechCard(
          leftBorderColor: AppColors.amberAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UssdSessionScreen()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.dialpad_rounded, color: AppColors.amberAccent, size: 28),
              SizedBox(height: 8),
              Text(
                '*99# SILENT USSD',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Cellular • Zero Internet',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        FintechCard(
          leftBorderColor: AppColors.successGreen,
          onTap: () {
            _showTopUpDialog(context, walletVM);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_card_rounded, color: AppColors.successGreen, size: 28),
              SizedBox(height: 8),
              Text(
                'TOP UP WALLET',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
              Text(
                'Razorpay UPI Gateway',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampusCoinsBanner(BuildContext context, WalletViewModel walletVM) {
    return FintechCard(
      leftBorderColor: AppColors.electricYellow,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CampusCoinsScreen()),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.electricYellow.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🪙', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${walletVM.coinsState.totalCoins} CAMPUSCOINS',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.electricYellow,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '≈ ₹${walletVM.coinsState.rupeeEquivalent.toStringAsFixed(1)} off',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🔥 ${walletVM.coinsState.streakDays}-Day Streak • 2 coins/₹10 spent',
                    style: const TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedText),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionRecord txn) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(txn.timestamp),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FintechCard(
        leftBorderColor: txn.syncStatus == SyncStatus.reconciled
            ? AppColors.successGreen
            : AppColors.amberAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.merchantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${txn.channelDisplayName} • $dateStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      txn.syncStatus == SyncStatus.reconciled ? 'RECONCILED' : 'OFFLINE (PENDING SYNC)',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: txn.syncStatus == SyncStatus.reconciled
                            ? AppColors.successGreen
                            : AppColors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nonce: ${txn.nonce.substring(0, 8)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '-₹${txn.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WalletViewModel walletVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'TOP UP CAMPUS WALLET',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select amount to top-up via Razorpay UPI:',
              style: TextStyle(fontSize: 13, color: AppColors.lightMutedText),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [200.0, 500.0, 1000.0].map((amt) {
                return OutlinedButton(
                  onPressed: () {
                    walletVM.topUpWallet(amt);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.cardDark,
                        content: Text(
                          '₹${amt.toStringAsFixed(0)} added to Campus Wallet successfully!',
                          style: const TextStyle(color: AppColors.successGreen),
                        ),
                      ),
                    );
                  },
                  child: Text('₹${amt.toStringAsFixed(0)}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
