import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../widgets/fintech_card.dart';
import '../widgets/transmission_wave_widget.dart';
import 'receipt_screen.dart';

class PaymentFlowScreen extends StatefulWidget {
  const PaymentFlowScreen({super.key});

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '80');

  final List<Map<String, String>> _merchants = [
    {'id': 'MCH-CANTEEN-01', 'name': 'DBIT Main Canteen', 'desc': 'Terminal SB-01'},
    {'id': 'MCH-XEROX-02', 'name': 'Campus Stationery & Xerox', 'desc': 'Terminal SB-02'},
    {'id': 'MCH-CAFE-03', 'name': 'Engineering Quad Cafe', 'desc': 'Terminal SB-03'},
  ];

  late String _selectedMerchantId;
  late String _selectedMerchantName;

  @override
  void initState() {
    super.initState();
    _selectedMerchantId = _merchants[0]['id']!;
    _selectedMerchantName = _merchants[0]['name']!;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentVM = context.watch<PaymentViewModel>();
    final walletVM = context.watch<WalletViewModel>();

    if (paymentVM.currentStep == PaymentStep.completed &&
        paymentVM.lastResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        walletVM.refresh();
        walletVM.awardCoins((paymentVM.amount / 5).round(), 'Canteen Payment');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(result: paymentVM.lastResult!),
          ),
        );
      });
    }

    final isTransmitting =
        paymentVM.currentStep == PaymentStep.transmittingDualWaves ||
            paymentVM.currentStep == PaymentStep.waitingAcousticAck ||
            paymentVM.currentStep == PaymentStep.signingPayload;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('OFFLINE AIRGAP PAY'),
        actions: [
          // Token count capsule
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.electricYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.electricYellow.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, size: 11, color: AppColors.electricYellow),
                const SizedBox(width: 5),
                Text(
                  '${walletVM.availableTokenCount} TOKENS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.electricYellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isTransmitting
            ? _buildTransmissionState(paymentVM)
            : _buildInputState(context, paymentVM, walletVM),
      ),
    );
  }

  Widget _buildInputState(
    BuildContext context,
    PaymentViewModel paymentVM,
    WalletViewModel walletVM,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protocol banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.electricYellow.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.electricYellow.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Text('📡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIER 2 · OFFLINE-FIRST PROTOCOL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.electricYellow,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '18–22kHz ultrasonic + BLE broadcast. No Internet needed.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.lightMutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Merchant select label
        Text(
          'VENDOR TERMINAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Merchant cards
        ..._merchants.map((m) {
          final isSelected = m['id'] == _selectedMerchantId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FintechCard(
              leftBorderColor: isSelected ? AppColors.electricYellow : AppColors.borderStroke,
              backgroundColor: isSelected
                  ? AppColors.electricYellow.withOpacity(0.05)
                  : AppColors.cardDark,
              glow: isSelected ? AppColors.yellowGlow : null,
              onTap: () => setState(() {
                _selectedMerchantId = m['id']!;
                _selectedMerchantName = m['name']!;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          size: 20,
                          color: isSelected
                              ? AppColors.electricYellow
                              : AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['name']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            '${m['desc']} · BLE pre-paired',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.electricYellow,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Amount label
        Text(
          'PAYMENT AMOUNT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Amount input — Bodoni Moda editorial style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderStroke, width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                '₹',
                style: GoogleFonts.bodoniModa(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.electricYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.borderStroke),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preset amount capsule pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [30.0, 80.0, 120.0, 200.0].map((amt) {
              final isSelected =
                  _amountController.text == amt.toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(
                    () => _amountController.text = amt.toStringAsFixed(0),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.electricYellow
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.electricYellow
                            : AppColors.borderStroke,
                      ),
                    ),
                    child: Text(
                      '₹${amt.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.backgroundBlack
                            : AppColors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Error message
        if (paymentVM.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.redAccent.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paymentVM.errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Primary CTA
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0) return;
              paymentVM.selectMerchant(
                  id: _selectedMerchantId, name: _selectedMerchantName);
              paymentVM.setAmount(amt);
              paymentVM.initiateOfflinePayment();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_up_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  'TRANSMIT AIRGAP WAVES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransmissionState(PaymentViewModel paymentVM) {
    String stateTitle = 'PREPARING CRYPTO PAYLOAD...';
    String stateDesc = 'Signing payload with device secp256k1 private key';
    Color ringColor = AppColors.electricYellow;

    if (paymentVM.currentStep == PaymentStep.transmittingDualWaves) {
      stateTitle = 'EMITTING 18–22kHz + BLE BURST...';
      stateDesc =
          'Emitting FSK acoustic audio waves + BLE advertisements simultaneously';
      ringColor = AppColors.electricYellow;
    } else if (paymentVM.currentStep == PaymentStep.waitingAcousticAck) {
      stateTitle = 'AWAITING SOUNDBOX ACK...';
      stateDesc = 'SoundBox mic verified payload. Waiting for return ACK tone';
      ringColor = AppColors.successGreen;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        TransmissionWaveWidget(size: 240, label: stateTitle),
        const SizedBox(height: 36),
        Text(
          stateTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ringColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stateDesc,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.lightMutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        FintechCard(
          child: Column(
            children: [
              _buildMetricRow('TARGET:', paymentVM.merchantName),
              const SizedBox(height: 8),
              _buildMetricRow(
                  'AMOUNT:', '₹${paymentVM.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildMetricRow('CARRIER 1:', '18–22kHz FSK Ultrasonic'),
              const SizedBox(height: 8),
              _buildMetricRow('CARRIER 2:', 'BLE Non-paired Advert'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => paymentVM.reset(),
          child: const Text('CANCEL TRANSMISSION'),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
