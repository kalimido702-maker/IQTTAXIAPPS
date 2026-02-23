import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// A custom "current location" marker overlay that sits on top of the map.
///
/// Renders:
///  - A pulsing translucent accuracy circle (same colour as the arrow)
///  - A solid circle with a navigation-arrow icon pointing upward
///
/// Designed to match the Figma design (teal/green arrow, white border,
/// soft pulsing accuracy ring). Placed at the centre of the map and
/// the camera is kept in sync with the user's position.
class IqLocationMarker extends StatefulWidget {
  const IqLocationMarker({
    super.key,
    this.color = AppColors.markerTeal,
    this.size = 50,
    this.accuracyRadius = 80,
    this.showAccuracy = true,
    this.heading,
  });

  /// Main accent colour for the marker and accuracy ring.
  final Color color;

  /// Diameter of the inner marker circle.
  final double size;

  /// Diameter of the outer accuracy ring (when [showAccuracy] is true).
  final double accuracyRadius;

  /// Whether to show the accuracy ring around the marker.
  final bool showAccuracy;

  /// Compass heading in degrees (0 = north). If null, the arrow points up.
  final double? heading;

  @override
  State<IqLocationMarker> createState() => _IqLocationMarkerState();
}

class _IqLocationMarkerState extends State<IqLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Gentle pulse on the accuracy ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markerSize = widget.size.w;
    final accuracySize = widget.accuracyRadius.w;

    return SizedBox(
      width: accuracySize,
      height: accuracySize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Accuracy ring (pulsing) ──
          if (widget.showAccuracy)
            AnimatedBuilder(
              listenable: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: accuracySize,
                height: accuracySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
            ),

          // ── Inner marker ──
          Container(
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(color: AppColors.white, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _headingRadians,
              child: Icon(
                Icons.navigation_rounded,
                color: AppColors.white,
                size: markerSize * 0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _headingRadians {
    if (widget.heading == null) return 0;
    return widget.heading! * (math.pi / 180);
  }
}

/// Same as Flutter's [AnimatedBuilder] but accepts a child for perf.
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
