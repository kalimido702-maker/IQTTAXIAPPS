import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Dark overlay timer banner shown on top of the map.
/// Displays a countdown or count-up timer with a message label.
/// Used for waiting time at pickup and ETA during trip.
class WaitingTimerBanner extends StatefulWidget {
  const WaitingTimerBanner({
    super.key,
    this.message = 'الوقت المتبقي لانتظار الراكب',
    this.warningMessage,
    this.startTime,
    this.isCountdown = false,
    this.totalSeconds,
  });

  final String message;
  final String? warningMessage;
  final DateTime? startTime;
  final bool isCountdown;
  final int? totalSeconds;

  @override
  State<WaitingTimerBanner> createState() => _WaitingTimerBannerState();
}

class _WaitingTimerBannerState extends State<WaitingTimerBanner> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null) {
      _seconds = DateTime.now().difference(widget.startTime!).inSeconds;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (widget.isCountdown && widget.totalSeconds != null) {
          _seconds = widget.totalSeconds! -
              DateTime.now()
                  .difference(widget.startTime ?? DateTime.now())
                  .inSeconds;
          if (_seconds < 0) _seconds = 0;
        } else {
          _seconds++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h hr : $m min : $s sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xCC000000), // dark semi-transparent
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Message label ──
          IqText(
            widget.message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          // ── Timer ──
          IqText(
            _formattedTime,
            style: AppTypography.numberLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22.sp,
            ),
            dir: TextDirection.ltr,
          ),
          if (widget.warningMessage != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14.w,
                  color: const Color(0xFFFFC107),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: IqText(
                    widget.warningMessage!,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFFFC107),
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
