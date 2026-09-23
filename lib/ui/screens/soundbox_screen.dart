import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/soundbox_viewmodel.dart';
import '../widgets/fintech_card.dart';

class SoundBoxScreen extends StatelessWidget {
  const SoundBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final soundboxVM = context.watch<SoundBoxViewModel>();

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
                border: Border.all(color: AppColors.tealAccent),
              ),
              child: const Text(
                'KIOSK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealAccent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('VENDOR SOUNDBOX POS'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              soundboxVM.isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: soundboxVM.isListening ? AppColors.tealAccent : AppColors.mutedText,
            ),
            tooltip: 'Toggle Mic Listener',
            onPressed: () => soundboxVM.toggleListening(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SoundBox Device Silhouette Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.electricYellow, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricYellow.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // SoundBox Header Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: soundboxVM.isListening ? AppColors.tealAccent : AppColors.mutedText,
                              boxShadow: [
                                if (soundboxVM.isListening)
                                  BoxShadow(
                                    color: AppColors.tealAccent.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            soundboxVM.isListening ? 'MIC ACTIVE: 18-22kHz FSK' : 'MIC PAUSED',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderStroke),
                        ),
                        child: const Text(
                          'KIOSK LOCKED',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 9,
                            color: AppColors.lightPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // OLED LCD Screen Simulation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF051515),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tealAccent.withOpacity(0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tealAccent.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DBIT MAIN CANTEEN • TERMINAL #01',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: AppColors.tealAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm:ss a').format(DateTime.now()),
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: AppColors.tealAccent,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF0F3838), height: 20),
                        if (soundboxVM.lastVerifiedPayload != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                '₹${soundboxVM.lastVerifiedPayload!.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payer: ${soundboxVM.lastVerifiedPayload!.payerName}',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Txn Nonce: ${soundboxVM.lastVerifiedPayload!.nonce.substring(0, 16)}',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'READY FOR AIRGAP PAYMENT\nHold student phone near mic (30cm–1m)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                color: AppColors.tealAccent,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Speaker Grille Section with Yellow Announcement Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.electricYellow, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // Speaker Grille Holes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            9,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          soundboxVM.lastAnnouncement,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.electricYellow,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daily Sales Stats Strip
            Row(
              children: [
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.tealAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL SALES TODAY',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${soundboxVM.totalSalesToday.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FintechCard(
                    leftBorderColor: AppColors.successGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CAMPUS WI-FI SYNC',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CONNECTED',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Received Payments Log
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SOUNDBOX CREDIT JOURNAL (${soundboxVM.creditHistory.length} ENTRIES)',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            ...soundboxVM.creditHistory.map((item) {
              final dateStr = DateFormat('hh:mm a').format(
                DateTime.fromMillisecondsSinceEpoch(item.timestamp),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FintechCard(
                  leftBorderColor: AppColors.tealAccent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.merchantName, // Shows student payer name
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified at $dateStr via 18-22kHz Ultrasonic',
                            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                      Text(
                        '+₹${item.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tealAccent,
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
