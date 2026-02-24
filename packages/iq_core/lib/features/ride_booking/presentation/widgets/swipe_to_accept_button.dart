import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// A swipe-to-accept button for the driver incoming request screen.
/// The thumb slides from left to right (visual left in RTL = start).
class SwipeToAcceptButton extends StatefulWidget {
  const SwipeToAcceptButton({
    super.key,
    required this.onAccepted,
    this.text = 'مرر لقبول الرحلة',
    this.height = 60,
  });

  final VoidCallback onAccepted;
  final String text;
  final double height;

  @override
  State<SwipeToAcceptButton> createState() => _SwipeToAcceptButtonState();
}

class _SwipeToAcceptButtonState extends State<SwipeToAcceptButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  late double _maxDrag;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  bool _accepted = false;

  static const _thumbWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_accepted) return;
    setState(() {
      // In RTL, positive delta.dx means dragging left (toward end).
      // We want the user to drag from right to left in RTL.
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final delta = isRtl ? -details.delta.dx : details.delta.dx;
      _dragPosition = (_dragPosition + delta).clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_accepted) return;

    if (_dragPosition >= _maxDrag * 0.8) {
      // Accepted!
      setState(() {
        _accepted = true;
        _dragPosition = _maxDrag;
      });
      HapticFeedback.heavyImpact();
      widget.onAccepted();
    } else {
      // Reset
      final startPos = _dragPosition;
      _resetAnimation = Tween<double>(begin: startPos, end: 0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
      )..addListener(() {
          setState(() => _dragPosition = _resetAnimation.value);
        });
      _resetController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height.h;
    final thumbW = _thumbWidth.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - thumbW - 8.w;

        final progress = _maxDrag > 0 ? (_dragPosition / _maxDrag) : 0.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              // Text label (fades out as user slides)
              Center(
                child: AnimatedOpacity(
                  opacity: (1.0 - progress * 2).clamp(0.0, 1.0),
                  duration: Duration.zero,
                  child: IqText(
                    widget.text,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: Directionality.of(context) == TextDirection.rtl
                    ? null
                    : 4.w + _dragPosition,
                right: Directionality.of(context) == TextDirection.rtl
                    ? 4.w + _dragPosition
                    : null,
                top: 4.h,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: thumbW,
                    height: height - 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular((height - 8.h) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _accepted
                          ? Icons.check_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      color: AppColors.primary,
                      size: 28.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
