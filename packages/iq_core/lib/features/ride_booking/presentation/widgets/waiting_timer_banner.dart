import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Dark overlay timer banner shown on top of the map.
/// Displays a countdown or count-up timer with a message label.
/// Used for waiting time at pickup and ETA during trip.
class WaitingTimerBanner extends StatefulWidget {
  WaitingTimerBanner({
    super.key,
    String? message,
    this.warningMessage,
    this.startTime,
    this.isCountdown = false,
    this.isLiveEta = false,
    this.totalSeconds,
    this.remainingDistanceKm,
  }) : message = message ?? AppStrings.waitingForPassenger;

  final String message;
  final String? warningMessage;
  final DateTime? startTime;
  final bool isCountdown;

  /// When true, no internal timer runs. The widget simply displays
  /// [totalSeconds] and [remainingDistanceKm] as provided by the parent.
  /// Values update only when the parent rebuilds with new data
  /// (e.g. after each GPS-based route re-fetch).
  final bool isLiveEta;
  final int? totalSeconds;

  /// If provided, shows remaining distance below the timer (e.g. "1.5 km").
  final double? remainingDistanceKm;

  @override
  State<WaitingTimerBanner> createState() => _WaitingTimerBannerState();
}

class _WaitingTimerBannerState extends State<WaitingTimerBanner> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isLiveEta) {
      _seconds = widget.totalSeconds ?? 0;
      // No timer — parent drives updates via rebuild.
      return;
    }
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
  void didUpdateWidget(WaitingTimerBanner old) {
    super.didUpdateWidget(old);
    // In live-ETA mode, sync displayed seconds when parent rebuilds.
    if (widget.isLiveEta) {
      _seconds = widget.totalSeconds ?? 0;
    }
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
        color: AppColors.overlayDark, // dark semi-transparent
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Message label ──
          IqText(
            widget.message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          // ── Timer ──
          IqText(
            _formattedTime,
            style: AppTypography.numberLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22.sp,
            ),
            dir: TextDirection.ltr,
          ),
          // ── Remaining distance ──
          if (widget.remainingDistanceKm != null &&
              widget.remainingDistanceKm! > 0) ...[
            SizedBox(height: 6.h),
            IqText(
              '${widget.remainingDistanceKm!.toStringAsFixed(1)} km',
              style: AppTypography.numberLarge.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
              dir: TextDirection.ltr,
            ),
          ],
          if (widget.warningMessage != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14.w,
                  color: AppColors.amber,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: IqText(
                    widget.warningMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.amber,
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
