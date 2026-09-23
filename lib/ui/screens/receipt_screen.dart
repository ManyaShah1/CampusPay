import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/payment_repository.dart';
import '../widgets/fintech_card.dart';

class ReceiptScreen extends StatelessWidget {
  final PaymentExecutionResult result;

  const ReceiptScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final record = result.transactionRecord;
    final payload = result.payload;
    final timeStr = DateFormat('dd MMM yyyy, hh:mm:ss a').format(
      DateTime.fromMillisecondsSinceEpoch(record.timestamp),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('PAYMENT RECEIPT'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Icon Banner
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successGreen.withOpacity(0.15),
                border: Border.all(color: AppColors.successGreen, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.successGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PAYMENT VERIFIED & COMMITTED',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.successGreen,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${record.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            Text(
              'Paid to ${record.merchantName}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.lightMutedText,
              ),
            ),
            const SizedBox(height: 24),

            // Scannable Receipt QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload.serialize(),
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SCANNABLE OPTICAL PROOF',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cryptographic Details
            FintechCard(
              leftBorderColor: AppColors.deepPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('TRANSACTION ID:', record.txnId),
                  const SizedBox(height: 8),
                  _buildDetailRow('TOKEN USED:', record.tokenId),
                  const SizedBox(height: 8),
                  _buildDetailRow('NONCE (ANTI-REPLAY):', record.nonce.substring(0, 16)),
                  const SizedBox(height: 8),
                  _buildDetailRow('CARRIER:', record.channelDisplayName),
                  const SizedBox(height: 8),
                  _buildDetailRow('TIMESTAMP:', timeStr),
                  const SizedBox(height: 8),
                  _buildDetailRow('PAYER SIG (ECDSA):', '${payload.payerSignature.substring(0, 18)}...'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('BACK TO WALLET'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            color: AppColors.mutedText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
