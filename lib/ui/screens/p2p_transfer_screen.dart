import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/audio/acoustic_carrier.dart';
import '../../core/ble/ble_payment_carrier.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/transaction_record.dart';
import '../viewmodels/p2p_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../widgets/fintech_card.dart';
import '../widgets/transmission_wave_widget.dart';

class P2pTransferScreen extends StatefulWidget {
  const P2pTransferScreen({super.key});

  @override
  State<P2pTransferScreen> createState() => _P2pTransferScreenState();
}

class _P2pTransferScreenState extends State<P2pTransferScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '150');

  final List<String> _peers = [
    'Rohan Verma (SE-COMPS)',
    'Ananya Iyer (TE-EXTC)',
    'Siddharth Nair (BE-MECH)',
    'Pooja Kulkarni (FE-IT)',
  ];

  late String _selectedPeer;
  StreamSubscription<Map<String, dynamic>>? _paymentSubscription;
  Map<String, dynamic>? _receivedPayment;

  @override
  void initState() {
    super.initState();
    _selectedPeer = _peers[0];
    _paymentSubscription = BlePaymentCarrier().receivedPayments.listen((payment) {
      if (!mounted) return;
      setState(() => _receivedPayment = payment);
    });
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pVM = context.watch<P2pViewModel>();
    final walletVM = context.watch<WalletViewModel>();

    final isProcessing = p2pVM.state == P2pState.transmittingPayload ||
        p2pVM.state == P2pState.waitingPeerAck ||
        p2pVM.state == P2pState.retrying;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('P2P SOUND-WAVE TRANSFER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.lightPurple),
            tooltip: 'Reset P2P Engine',
            onPressed: () => p2pVM.reset(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Segmented Switcher: SEND vs RECEIVE
            _buildRoleSegmentedPicker(p2pVM),
            const SizedBox(height: 16),

            // Carrier Frequency Setting Toggle
            _buildCarrierFrequencyToggle(p2pVM),
            const SizedBox(height: 16),

            // Main Body view based on active role & state
            if (_receivedPayment != null) ...[
              _buildBleReceiveState(walletVM),
            ] else if (p2pVM.activeRole == P2pRole.receiver) ...[
              _buildReceiverFlow(p2pVM, walletVM),
            ] else ...[
              if (isProcessing) ...[
                _buildProcessingState(p2pVM),
              ] else if (p2pVM.state == P2pState.committedSuccess) ...[
                _buildSuccessState(context, p2pVM, walletVM),
              ] else ...[
                _buildInputState(context, p2pVM, walletVM),
              ],
            ],

            const SizedBox(height: 24),
            _buildLocalDemoBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildBleReceiveState(WalletViewModel walletVM) {
    final payment = _receivedPayment!;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final senderName = payment['sender_name']?.toString() ?? 'CampusPay user';
    final transactionId =
        payment['transaction_id']?.toString() ?? 'BLE-P2P';

    return Column(
      children: [
        const SizedBox(height: 36),
        const Icon(
          Icons.check_circle,
          size: 90,
          color: AppColors.successGreen,
        ),
        const SizedBox(height: 18),
        Text(
          'PAYMENT RECEIVED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: GoogleFonts.bodoniModa(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'From $senderName',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 28),
        FintechCard(
          leftBorderColor: AppColors.lightPurple,
          child: Column(
            children: [
              _row('TRANSACTION ID', transactionId),
              const SizedBox(height: 12),
              _row('STATUS', 'BLE TRANSPORT ACK (DEMO)'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Local prototype demo · No real bank funds moved',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _receivedPayment = null);
              walletVM.refresh();
            },
            child: const Text('DONE'),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSegmentedPicker(P2pViewModel p2pVM) {
    final isSender = p2pVM.activeRole == P2pRole.sender;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => p2pVM.setActiveRole(P2pRole.sender),
              child: Container(
                decoration: BoxDecoration(
                  color: isSender ? AppColors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: isSender ? AppColors.white : AppColors.mutedText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SEND MONEY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSender ? AppColors.white : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => p2pVM.setActiveRole(P2pRole.receiver),
              child: Container(
                decoration: BoxDecoration(
                  color: !isSender ? AppColors.tealAccent.withOpacity(0.2) : Colors.transparent,
                  border: !isSender ? Border.all(color: AppColors.tealAccent) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_received_rounded,
                        size: 16,
                        color: !isSender ? AppColors.tealAccent : AppColors.mutedText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RECEIVE MONEY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: !isSender ? AppColors.tealAccent : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarrierFrequencyToggle(P2pViewModel p2pVM) {
    final isAudible = p2pVM.carrierMode == AudioCarrierMode.audibleFsk;
    return FintechCard(
      leftBorderColor: isAudible ? AppColors.electricYellow : AppColors.tealAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAudible ? 'AUDIBLE FSK (1.2–2.4 kHz)' : 'ULTRASONIC FSK (18–22 kHz)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isAudible ? AppColors.electricYellow : AppColors.tealAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAudible
                      ? 'Tested & reliable audio fallback for all Android speakers/mics'
                      : 'Configurable high-frequency silent carrier (phone hardware dependent)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAudible,
            activeColor: AppColors.electricYellow,
            inactiveThumbColor: AppColors.tealAccent,
            onChanged: (val) {
              p2pVM.setCarrierMode(val ? AudioCarrierMode.audibleFsk : AudioCarrierMode.ultrasonicFsk);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverFlow(P2pViewModel p2pVM, WalletViewModel walletVM) {
    final isListening = p2pVM.state == P2pState.listening;
    final isSuccess = p2pVM.state == P2pState.committedSuccess && p2pVM.committedTransaction != null;

    if (isSuccess) {
      final txn = p2pVM.committedTransaction!;
      return Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successGreen.withOpacity(0.12),
              border: Border.all(color: AppColors.successGreen, width: 2),
            ),
            child: const Icon(Icons.download_done_rounded, color: AppColors.successGreen, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'SOUND WAVE TRANSFER RECEIVED!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${txn.amount.toStringAsFixed(2)}',
            style: GoogleFonts.bodoniModa(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          Text(
            'Credited from ${txn.merchantName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.lightMutedText,
            ),
          ),
          const SizedBox(height: 20),
          FintechCard(
            leftBorderColor: AppColors.successGreen,
            child: Column(
              children: [
                _row('TRANSACTION ID', txn.txnId),
                const SizedBox(height: 8),
                _row('NONCE PAIR', txn.nonce.substring(0, 16)),
                const SizedBox(height: 8),
                _row('ACOUSTIC ACK', 'SENT BACK VIA SPEAKER'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealAccent, foregroundColor: Colors.black),
              onPressed: () {
                walletVM.refresh();
                p2pVM.startReceiverListeningMode();
              },
              child: const Text('LISTEN FOR ANOTHER TRANSFER'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        TransmissionWaveWidget(
          size: 200,
          isTransmitting: isListening,
          label: 'MIC LISTENING FOR SOUND WAVE',
        ),
        const SizedBox(height: 24),
        Text(
          isListening ? 'RECEIVER MODE ACTIVE' : 'RECEIVER PAUSED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isListening ? AppColors.tealAccent : AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p2pVM.statusMessage ?? 'Hold sender phone near this device microphone (30cm–1m).',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.lightMutedText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isListening ? AppColors.cardDark : AppColors.tealAccent,
              foregroundColor: isListening ? AppColors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(isListening ? Icons.mic_off_rounded : Icons.mic_rounded),
            label: Text(isListening ? 'PAUSE RECEIVER MIC' : 'ACTIVATE RECEIVER MIC'),
            onPressed: () {
              if (isListening) {
                p2pVM.stopReceiverListeningMode();
              } else {
                p2pVM.startReceiverListeningMode();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.graphic_eq_rounded),
            label: const Text('START PING TEST LISTENER (NO WALLET CHANGE)'),
            onPressed: p2pVM.startAcousticDiagnosticReceiver,
          ),
        ),
      ],
    );
  }

  Widget _buildInputState(
    BuildContext context,
    P2pViewModel p2pVM,
    WalletViewModel walletVM,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protocol info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.deepPurple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightPurple.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, size: 14, color: AppColors.lightPurple),
                  const SizedBox(width: 8),
                  Text(
                    'TWO-PHASE DEMO TRANSFER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightPurple,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'The sender records this demo transfer after a matching peer ACK. '
                    'An ACK is transport confirmation, not cryptographic authentication.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.lightMutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'NEARBY PEERS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Peer list
        ..._peers.map((peer) {
          final isSelected = peer == _selectedPeer;
          final initials = peer.split(' ').take(2).map((w) => w[0]).join();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FintechCard(
              leftBorderColor: isSelected ? AppColors.lightPurple : AppColors.borderStroke,
              backgroundColor: isSelected
                  ? AppColors.deepPurple.withOpacity(0.08)
                  : AppColors.cardDark,
              glow: isSelected ? AppColors.purpleGlow : null,
              onTap: () => setState(() => _selectedPeer = peer),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.deepPurple.withOpacity(0.4)
                          : AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.lightPurple.withOpacity(0.5)
                            : AppColors.borderStroke,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.lightPurple
                              : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      peer,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.lightPurple,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        Text(
          'TRANSFER AMOUNT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Amount input
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
                  color: AppColors.lightPurple,
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
        const SizedBox(height: 20),

        // Error / Rejection Card State
        if (p2pVM.statusMessage != null && p2pVM.state == P2pState.failed)
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
                const Icon(Icons.error_outline_rounded, color: AppColors.redAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p2pVM.statusMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Send Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0) return;
              p2pVM.setPeerName(_selectedPeer);
              p2pVM.setAmount(amt);
              p2pVM.sendP2pTransfer();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_tethering_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  'EMIT P2P BURST TO PEER',
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bluetooth),
            label: const Text('SEND VIA BLE (MANUAL)  ·  NO AUTO-FALLBACK'),
            onPressed: p2pVM.committedTransaction == null
                ? () {
                    final amt =
                        double.tryParse(_amountController.text) ?? 0.0;
                    if (amt <= 0) return;
                    p2pVM.setPeerName(_selectedPeer);
                    p2pVM.setAmount(amt);
                    p2pVM.sendBleP2pTransfer();
                  }
                : null,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.hearing_rounded),
            label: const Text('SEND PING TEST (NO WALLET CHANGE)'),
            onPressed: p2pVM.sendAcousticDiagnosticPing,
          ),
        ),
        if (p2pVM.statusMessage?.startsWith('Diagnostic:') ?? false) ...[
          const SizedBox(height: 10),
          Text(
            p2pVM.statusMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.tealAccent),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessingState(P2pViewModel p2pVM) {
    final bool isBleSending =
        p2pVM.statusMessage?.startsWith('Sending offline payment token') ??
            false;
    final String processingLabel;
    if (isBleSending) {
      processingLabel = 'SENDING PAYMENT OVER BLE...';
    } else if (p2pVM.state == P2pState.transmittingPayload) {
      processingLabel = 'EMITTING SOUND WAVE BURST...';
    } else if (p2pVM.state == P2pState.retrying) {
      processingLabel = 'RETRYING (${p2pVM.retryCount}/${p2pVM.maxRetries})...';
    } else {
      processingLabel = 'AWAITING ACOUSTIC ACK...';
    }

    return Column(
      children: [
        const SizedBox(height: 40),
        const TransmissionWaveWidget(size: 220),
        const SizedBox(height: 32),
        Text(
          processingLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.lightPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p2pVM.statusMessage ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.lightMutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    P2pViewModel p2pVM,
    WalletViewModel walletVM,
  ) {
    final txn = p2pVM.committedTransaction!;
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen.withOpacity(0.12),
            border: Border.all(color: AppColors.successGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.successGreen.withOpacity(0.3),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.successGreen,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'P2P TRANSFER COMPLETE (DEMO)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.successGreen,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${txn.amount.toStringAsFixed(2)}',
          style: GoogleFonts.bodoniModa(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        Text(
          'Transferred to ${txn.merchantName}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 24),
        FintechCard(
          leftBorderColor: AppColors.lightPurple,
          child: Column(
            children: [
              _row('TRANSACTION ID', txn.txnId),
              const SizedBox(height: 8),
              _row('NONCE PAIR', txn.nonce.substring(0, 16)),
              const SizedBox(height: 8),
              _row('STATUS', 'PEER ACK RECEIVED (DEMO)'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              walletVM.refresh();
              if (txn.channel == PaymentChannel.p2pAcoustic) {
                walletVM.awardCoins(15, 'P2P Transfer Bonus');
              }
              p2pVM.reset();
            },
            child: const Text('FINISH'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalDemoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.electricYellow),
              const SizedBox(width: 8),
              Text(
                'LOCAL PROTOTYPE DEMO • ZERO INTERNET',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.electricYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sound-wave transfers transmit encrypted ECDSA tokens directly between phone speaker and microphone without moving real bank funds.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
