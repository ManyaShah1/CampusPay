import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedPeer = _peers[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pVM = context.watch<P2pViewModel>();
    final walletVM = context.watch<WalletViewModel>();

    final isProcessing = p2pVM.state == P2pState.transmittingPayload ||
        p2pVM.state == P2pState.waitingPeerAck;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('P2P AIRGAP TRANSFER'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isProcessing
            ? _buildProcessingState(p2pVM)
            : p2pVM.state == P2pState.committedSuccess
                ? _buildSuccessState(context, p2pVM, walletVM)
                : _buildInputState(context, p2pVM, walletVM),
      ),
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
                  const Icon(Icons.security_rounded,
                      size: 14, color: AppColors.lightPurple),
                  const SizedBox(width: 8),
                  Text(
                    'TWO-PHASE AIRGAP COMMIT',
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
                'Funds deducted ONLY after peer receives the ultrasonic payload and responds with a verified Acoustic ACK.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.lightMutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

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
                  // Avatar with initials
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

        // Amount input — Bodoni Moda editorial
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
        const SizedBox(height: 24),

        // Error state
        if (p2pVM.statusMessage != null && p2pVM.state == P2pState.failed)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.redAccent.withOpacity(0.5)),
            ),
            child: Text(
              p2pVM.statusMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.redAccent,
              ),
            ),
          ),

        // Send button — purple secondary CTA style
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
      ],
    );
  }

  Widget _buildProcessingState(P2pViewModel p2pVM) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const TransmissionWaveWidget(size: 220),
        const SizedBox(height: 32),
        Text(
          p2pVM.state == P2pState.transmittingPayload
              ? 'TRANSMITTING TO ${_selectedPeer.split(' ')[0].toUpperCase()}...'
              : 'WAITING FOR ACOUSTIC ACK...',
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
          'P2P AIRGAP COMMIT COMPLETE',
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
              _row('STATUS', 'COMMITTED VIA ACOUSTIC ACK'),
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
              walletVM.awardCoins(15, 'P2P Transfer Bonus');
              Navigator.pop(context);
            },
            child: const Text('FINISH'),
          ),
        ),
      ],
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
