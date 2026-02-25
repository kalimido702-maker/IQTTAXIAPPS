import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Waiting timer banner shown when driver is waiting at pickup.
/// Displays a countdown or count-up timer with a warning message.
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
  late final ValueNotifier<int> _seconds;

  @override
  void initState() {
    super.initState();
    final initial = widget.startTime != null
        ? DateTime.now().difference(widget.startTime!).inSeconds
        : 0;
    _seconds = ValueNotifier<int>(initial);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.isCountdown && widget.totalSeconds != null) {
        _seconds.value = widget.totalSeconds! -
            DateTime.now().difference(widget.startTime ?? DateTime.now()).inSeconds;
        if (_seconds.value < 0) _seconds.value = 0;
      } else {
        _seconds.value++;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  String _formattedTime(int secs) {
    final h = (secs ~/ 3600).toString().padLeft(2, '0');
    final m = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$h hr : $m min : $s sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IqText(
            widget.message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6.h),
          ValueListenableBuilder<int>(
            valueListenable: _seconds,
            builder: (_, secs, __) => IqText(
              _formattedTime(secs),
              style: AppTypography.numberLarge.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w700,
              ),
              dir: TextDirection.ltr,
            ),
          ),
          if (widget.warningMessage != null) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16.w,
                  color: AppColors.warning,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: IqText(
                    widget.warningMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
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
