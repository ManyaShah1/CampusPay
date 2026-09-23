import 'package:flutter/material.dart';
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
  final TextEditingController _amountController = TextEditingController(text: '150');

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
        // Protocol Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0A2D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightPurple.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TWO-PHASE AIRGAP COMMIT',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightPurple,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Funds are ONLY deducted from your wallet after peer receives the ultrasonic payload and responds with a verified Acoustic ACK.',
                style: TextStyle(fontSize: 11, color: AppColors.lightMutedText, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Peer Selection
        const Text(
          'SELECT NEARBY PEER',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 8),

        ..._peers.map((peer) {
          final isSelected = peer == _selectedPeer;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FintechCard(
              leftBorderColor: isSelected ? AppColors.lightPurple : AppColors.borderStroke,
              backgroundColor: isSelected ? const Color(0xFF1B1425) : AppColors.cardDark,
              onTap: () {
                setState(() => _selectedPeer = peer);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF2A153A),
                        child: Icon(Icons.person_rounded, size: 18, color: AppColors.lightPurple),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        peer,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.white),
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.lightPurple, size: 18),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Amount Input
        const Text(
          'TRANSFER AMOUNT (₹)',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText,
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
                  color: AppColors.lightPurple,
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
        const SizedBox(height: 24),

        if (p2pVM.statusMessage != null && p2pVM.state == P2pState.failed)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.redAccent),
            ),
            child: Text(
              p2pVM.statusMessage!,
              style: const TextStyle(fontSize: 12, color: AppColors.redAccent),
            ),
          ),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightPurple,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final amt = double.tryParse(_amountController.text) ?? 0.0;
              if (amt <= 0) return;

              p2pVM.setPeerName(_selectedPeer);
              p2pVM.setAmount(amt);
              p2pVM.sendP2pTransfer();
            },
            child: const Text('EMIT P2P BURST TO PEER'),
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
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.lightPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p2pVM.statusMessage ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.lightMutedText),
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
        const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 64),
        const SizedBox(height: 16),
        const Text(
          'P2P AIRGAP COMMIT COMPLETE',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${txn.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        Text(
          'Transferred to ${txn.merchantName}',
          style: const TextStyle(fontSize: 13, color: AppColors.lightMutedText),
        ),
        const SizedBox(height: 24),
        FintechCard(
          leftBorderColor: AppColors.lightPurple,
          child: Column(
            children: [
              _row('TRANSACTION ID', txn.txnId),
              const SizedBox(height: 6),
              _row('NONCE PAIR', txn.nonce.substring(0, 16)),
              const SizedBox(height: 6),
              _row('STATUS', 'COMMITTED VIA ACOUSTIC ACK'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 48,
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
        Text(label, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.mutedText)),
        Text(value, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
      ],
    );
  }
}
