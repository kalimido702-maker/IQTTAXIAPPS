import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Mutable pointer-down tracker used by [IqHapticTapWrapper].
///
/// Stored outside the widget so no [StatefulWidget] is needed.
class _HapticTracker {
  _HapticTracker._();
  static Offset? downPosition;
}

/// Wraps the entire app to provide haptic feedback on every tap gesture.
///
/// Uses a [Listener] with translucent hit-test to intercept pointer events
/// without consuming them. Differentiates taps from scrolls/drags by
/// checking pointer displacement (< 20 px = tap).
class IqHapticTapWrapper extends StatelessWidget {
  const IqHapticTapWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _HapticTracker.downPosition = e.position,
      onPointerUp: (e) {
        final down = _HapticTracker.downPosition;
        if (down != null && (e.position - down).distance < 20) {
          HapticFeedback.lightImpact();
        }
        _HapticTracker.downPosition = null;
      },
      onPointerCancel: (_) => _HapticTracker.downPosition = null,
      child: child,
    );
  }
}
