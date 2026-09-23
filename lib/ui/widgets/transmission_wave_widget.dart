import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TransmissionWaveWidget extends StatefulWidget {
  final double size;
  final bool isTransmitting;
  final String label;

  const TransmissionWaveWidget({
    super.key,
    this.size = 200,
    this.isTransmitting = true,
    this.label = '18–22kHz ULTRASONIC + BLE',
  });

  @override
  State<TransmissionWaveWidget> createState() => _TransmissionWaveWidgetState();
}

class _TransmissionWaveWidgetState extends State<TransmissionWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave 3 (Outer BLE ring)
              _buildWaveRing(
                progress: (_controller.value + 0.6) % 1.0,
                color: AppColors.lightPurple,
              ),
              // Wave 2 (Mid Ultrasonic ring)
              _buildWaveRing(
                progress: (_controller.value + 0.3) % 1.0,
                color: AppColors.electricYellow,
              ),
              // Wave 1 (Inner ring)
              _buildWaveRing(
                progress: _controller.value,
                color: AppColors.electricYellow,
              ),
              // Center emitter beacon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundBlack,
                  border: Border.all(color: AppColors.electricYellow, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricYellow.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.sensors_rounded,
                    color: AppColors.electricYellow,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveRing({required double progress, required Color color}) {
    final currentSize = 64 + (widget.size - 64) * progress;
    final opacity = math.max(0.0, 1.0 - progress);

    return Container(
      width: currentSize,
      height: currentSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity * 0.7),
          width: 2.0,
        ),
      ),
    );
  }
}
