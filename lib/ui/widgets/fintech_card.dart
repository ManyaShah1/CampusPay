import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FintechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? leftBorderColor;
  final double leftBorderWidth;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const FintechCard({
    super.key,
    required this.child,
    this.padding,
    this.leftBorderColor,
    this.leftBorderWidth = 4.0,
    this.onTap,
    this.backgroundColor = AppColors.cardDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leftBorderColor != null)
                Container(
                  width: leftBorderWidth,
                  color: leftBorderColor,
                ),
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }
}
