import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Base card widget — rounded-16, optional left accent bar, optional glow
class FintechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? leftBorderColor;
  final double leftBorderWidth;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final List<BoxShadow>? glow;
  final double borderRadius;

  const FintechCard({
    super.key,
    required this.child,
    this.padding,
    this.leftBorderColor,
    this.leftBorderWidth = 3.0,
    this.onTap,
    this.backgroundColor = AppColors.cardDark,
    this.glow,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: AppColors.borderStroke, width: 1),
        boxShadow: glow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leftBorderColor != null)
                Container(
                  width: leftBorderWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [leftBorderColor!, leftBorderColor!.withOpacity(0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
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
        borderRadius: radius,
        splashColor: AppColors.electricYellow.withOpacity(0.05),
        highlightColor: AppColors.electricYellow.withOpacity(0.03),
        child: content,
      );
    }
    return content;
  }
}
