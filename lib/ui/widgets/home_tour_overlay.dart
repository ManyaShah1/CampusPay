import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/onboarding_service.dart';

class TourElementTarget {
  final GlobalKey key;
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String actionTip;

  const TourElementTarget({
    required this.key,
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.electricYellow,
    required this.actionTip,
  });
}

class HomeTourOverlay extends StatefulWidget {
  final List<TourElementTarget> targets;
  final VoidCallback onFinish;

  const HomeTourOverlay({
    super.key,
    required this.targets,
    required this.onFinish,
  });

  @override
  State<HomeTourOverlay> createState() => _HomeTourOverlayState();
}

class _HomeTourOverlayState extends State<HomeTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Rect? _targetRect;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusCurrentTarget();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _focusCurrentTarget() {
    if (!mounted || widget.targets.isEmpty) return;

    final target = widget.targets[_currentIndex];
    final targetContext = target.key.currentContext;

    if (targetContext != null) {
      // Scroll to target if it is within a Scrollable
      final scrollable = Scrollable.maybeOf(targetContext);
      if (scrollable != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 320),
          alignment: 0.35,
          curve: Curves.easeInOutCubic,
        );
      }

      void measure() {
        if (!mounted) return;
        final overlayBox = context.findRenderObject() as RenderBox?;
        final renderBox =
            target.key.currentContext?.findRenderObject() as RenderBox?;
        if (overlayBox != null && renderBox != null && renderBox.hasSize) {
          final localOffset =
              overlayBox.globalToLocal(renderBox.localToGlobal(Offset.zero));
          setState(() {
            _targetRect = localOffset & renderBox.size;
          });
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => measure());
      Future.delayed(const Duration(milliseconds: 340), measure);
    }
  }

  void _nextTarget() {
    HapticFeedback.lightImpact();
    if (_currentIndex < widget.targets.length - 1) {
      setState(() {
        _currentIndex++;
        _targetRect = null;
      });
      _focusCurrentTarget();
    } else {
      _finishTour();
    }
  }

  void _prevTarget() {
    HapticFeedback.lightImpact();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _targetRect = null;
      });
      _focusCurrentTarget();
    }
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    await OnboardingService.completeTour();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targets.isEmpty) return const SizedBox.shrink();

    final target = widget.targets[_currentIndex];
    final screenSize = MediaQuery.of(context).size;
    final isLast = _currentIndex == widget.targets.length - 1;

    // Determine tooltip position relative to target
    final showBelow = _targetRect == null ||
        (_targetRect!.bottom + 270 < screenSize.height);

    double? tooltipTop;
    double? tooltipBottom;

    if (_targetRect != null) {
      if (showBelow) {
        tooltipTop = (_targetRect!.bottom + 14)
            .clamp(16.0, screenSize.height - 290.0);
      } else {
        tooltipBottom = (screenSize.height - _targetRect!.top + 14)
            .clamp(16.0, screenSize.height - 290.0);
      }
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Spotlight Canvas (Dark Scrim with Cutout Hole and Glowing Border)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: _targetRect,
                  glowValue: _pulseAnimation.value,
                  accentColor: target.accentColor,
                ),
              );
            },
          ),

          // Dismiss / Background tap catcher (for skipping)
          GestureDetector(
            onTap: _nextTarget,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),

          // Interactive Tooltip Card
          Positioned(
            left: 16,
            right: 16,
            top: showBelow ? tooltipTop : null,
            bottom: showBelow ? null : tooltipBottom,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildTooltipCard(
                key: ValueKey(_currentIndex),
                target: target,
                isLast: isLast,
                showBelow: showBelow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipCard({
    required Key key,
    required TourElementTarget target,
    required bool isLast,
    required bool showBelow,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: target.accentColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Badge, Step Counter, Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: target.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      target.badge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1917),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentIndex + 1} of ${widget.targets.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _finishTour,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title Row with Icon
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: target.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(target.icon, size: 18, color: const Color(0xFF1C1917)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  target.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1727),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            target.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF4B5563),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Action Tip Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    target.actionTip,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Controls: Step Dots + Prev / Next Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress dots
              Row(
                children: List.generate(widget.targets.length, (idx) {
                  final isActive = idx == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF6B21A8)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              // Buttons
              Row(
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _prevTarget,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B21A8),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _nextTarget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricYellow,
                      foregroundColor: const Color(0xFF1C1917),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLast ? 'Done ' : 'Next ➔',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double glowValue;
  final Color accentColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.glowValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const overlayColor = Color(0xBF000000); // 75% dark scrim
    final backgroundPaint = Paint()..color = overlayColor;

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, backgroundPaint);
      return;
    }

    final inflated = targetRect!.inflate(6);
    final rrect = RRect.fromRectAndRadius(inflated, const Radius.circular(16));

    // Draw dark scrim with clear cutout
    final screenPath = Path()..addRect(Offset.zero & size);
    final cutoutPath = Path()..addRRect(rrect);
    final combinedPath =
        Path.combine(PathOperation.difference, screenPath, cutoutPath);
    canvas.drawPath(combinedPath, backgroundPaint);

    // Glowing Neon Stroke around the highlighted element
    final strokePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, strokePaint);

    // Pulsing Outer Aura Halo
    final haloPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25 * glowValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawRRect(rrect, haloPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.glowValue != glowValue ||
        oldDelegate.accentColor != accentColor;
  }
}
