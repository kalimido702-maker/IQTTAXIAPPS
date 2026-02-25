import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Animated searching-for-driver overlay with radial pulse.
class SearchingDriverAnimation extends StatefulWidget {
  const SearchingDriverAnimation({
    super.key,
    this.message = 'نحن نبحث عن سائق قريب',
    this.onCancel,
    this.autoCancel = true,
    this.autoCancelSeconds = 120,
  });

  final String message;
  final VoidCallback? onCancel;
  final bool autoCancel;
  final int autoCancelSeconds;

  @override
  State<SearchingDriverAnimation> createState() =>
      _SearchingDriverAnimationState();
}

class _SearchingDriverAnimationState extends State<SearchingDriverAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (widget.autoCancel &&
          _elapsedSeconds >= widget.autoCancelSeconds &&
          widget.onCancel != null) {
        widget.onCancel!();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulse animation
        SizedBox(
          width: 200.w,
          height: 200.w,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                painter: _PulsePainter(
                  progress: _pulseController.value,
                  color: AppColors.primary,
                ),
                child: Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      color: AppColors.white,
                      size: 36.w,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h),
        IqText(
          widget.message,
          style: AppTypography.heading3.copyWith(color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        IqText(
          _timerText,
          style: AppTypography.numberLarge.copyWith(
            color: AppColors.textMuted,
          ),
          dir: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 concentric expanding rings
    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1.0 - phase) * 0.3;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => oldDelegate.progress != progress;
}
