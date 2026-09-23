import 'package:flutter/material.dart';
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
  final TextEditingController _amountController = TextEditingController(text: '80');

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

    // Listen for completion to push ReceiptScreen
    if (paymentVM.currentStep == PaymentStep.completed && paymentVM.lastResult != null) {
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

    final isTransmitting = paymentVM.currentStep == PaymentStep.transmittingDualWaves ||
        paymentVM.currentStep == PaymentStep.waitingAcousticAck ||
        paymentVM.currentStep == PaymentStep.signingPayload;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('OFFLINE AIRGAP PAY'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.electricYellow),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, size: 12, color: AppColors.electricYellow),
                const SizedBox(width: 4),
                Text(
                  '${walletVM.availableTokenCount} TOKENS LEFT',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
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
        // Mode Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDarker,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.electricYellow.withOpacity(0.4)),
          ),
          child: Row(
            children: const [
              Text('📡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIER 2 • OFFLINE-FIRST PROTOCOL',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.electricYellow,
                      ),
                    ),
                    Text(
                      'Simultaneous 18–22kHz ultrasonic audio burst + BLE broadcast. No Internet needed.',
                      style: TextStyle(fontSize: 11, color: AppColors.lightMutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Merchant Select
        const Text(
          'DESTINATION VENDOR TERMINAL',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        ..._merchants.map((m) {
          final isSelected = m['id'] == _selectedMerchantId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FintechCard(
              leftBorderColor: isSelected ? AppColors.electricYellow : AppColors.borderStroke,
              backgroundColor: isSelected ? const Color(0xFF222222) : AppColors.cardDark,
              onTap: () {
                setState(() {
                  _selectedMerchantId = m['id']!;
                  _selectedMerchantName = m['name']!;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.white),
                      ),
                      Text(
                        '${m['desc']} • BLE Beacon pre-paired',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.electricYellow, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Amount Input
        const Text(
          'PAYMENT AMOUNT (₹)',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.electricYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.borderStroke),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preset amount pills
        Row(
          children: [30.0, 80.0, 120.0, 200.0].map((amt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.cardDarker,
                side: const BorderSide(color: AppColors.borderStroke),
                label: Text(
                  '₹${amt.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _amountController.text = amt.toStringAsFixed(0);
                  });
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Error message if any
        if (paymentVM.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.redAccent),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paymentVM.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.redAccent),
                  ),
                ),
              ],
            ),
          ),

        // Pay Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0) return;

              paymentVM.selectMerchant(id: _selectedMerchantId, name: _selectedMerchantName);
              paymentVM.setAmount(amt);
              paymentVM.initiateOfflinePayment();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.volume_up_rounded, size: 20),
                SizedBox(width: 10),
                Text('TRANSMIT DUAL AIRGAP WAVES'),
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
      stateDesc = 'Emitting FSK acoustic audio waves + BLE advertisements simultaneously';
      ringColor = AppColors.electricYellow;
    } else if (paymentVM.currentStep == PaymentStep.waitingAcousticAck) {
      stateTitle = 'AWAITING SOUNDBOX ACOUSTIC ACK...';
      stateDesc = 'SoundBox mic verified payload. Waiting for high-frequency return ACK tone';
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
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ringColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stateDesc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.lightMutedText),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: Column(
            children: [
              _buildMetricRow('TARGET:', paymentVM.merchantName),
              const SizedBox(height: 6),
              _buildMetricRow('AMOUNT:', '₹${paymentVM.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildMetricRow('CARRIER 1:', '18-22kHz FSK Ultrasonic (30cm-1m)'),
              const SizedBox(height: 6),
              _buildMetricRow('CARRIER 2:', 'BLE Non-paired Advert (10-30m)'),
            ],
          ),
        ),
        const SizedBox(height: 30),
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
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
