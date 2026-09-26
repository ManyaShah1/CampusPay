import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/offline_token.dart';

class TokenStatusBadge extends StatelessWidget {
  final OfflineToken token;
  final int index;

  const TokenStatusBadge({
    super.key,
    required this.token,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppColors.electricYellow;
    String statusText = 'ACTIVE';

    if (token.isUsed) {
      badgeColor = AppColors.mutedText;
      statusText = 'USED';
    } else if (token.isExpired) {
      badgeColor = AppColors.redAccent;
      statusText = 'EXPIRED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9999), // capsule
        border: Border.all(
          color: token.isUsed ? AppColors.borderStroke : badgeColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
              boxShadow: [
                if (!token.isUsed)
                  BoxShadow(
                    color: badgeColor.withOpacity(0.6),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${index.toString().padLeft(2, '0')} ${token.tokenId.substring(8)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: badgeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
