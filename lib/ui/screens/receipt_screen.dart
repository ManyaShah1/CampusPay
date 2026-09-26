import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Success State ─────────────────────────────────────────────
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
                    blurRadius: 28,
                    spreadRadius: 0,
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
              'PAYMENT VERIFIED & COMMITTED',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.successGreen,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Amount — Bodoni Moda editorial
            Text(
              '₹${record.amount.toStringAsFixed(2)}',
              style: GoogleFonts.bodoniModa(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: -1.5,
              ),
            ),
            Text(
              'Paid to ${record.merchantName}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // ── QR Code Card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload.serialize(),
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SCANNABLE OPTICAL PROOF',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Cryptographic Details ─────────────────────────────────────
            FintechCard(
              leftBorderColor: AppColors.deepPurple,
              glow: AppColors.purpleGlow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 14, color: AppColors.lightPurple),
                      const SizedBox(width: 8),
                      Text(
                        'CRYPTOGRAPHIC PROOF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.borderStroke, height: 1),
                  const SizedBox(height: 14),
                  _buildDetailRow('TRANSACTION ID', record.txnId),
                  const SizedBox(height: 10),
                  _buildDetailRow('TOKEN USED', record.tokenId),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      'NONCE (ANTI-REPLAY)', record.nonce.substring(0, 16)),
                  const SizedBox(height: 10),
                  _buildDetailRow('CARRIER', record.channelDisplayName),
                  const SizedBox(height: 10),
                  _buildDetailRow('TIMESTAMP', timeStr),
                  const SizedBox(height: 10),
                  _buildDetailRow('PAYER SIG (ECDSA)',
                      '${payload.payerSignature.substring(0, 18)}...'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── CTA ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'BACK TO WALLET',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
