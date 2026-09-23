import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardDarker,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: token.isUsed ? AppColors.borderStroke : badgeColor.withOpacity(0.5),
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
                    blurRadius: 6,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${index.toString().padLeft(2, '0')} ${token.tokenId.substring(8)}',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
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
