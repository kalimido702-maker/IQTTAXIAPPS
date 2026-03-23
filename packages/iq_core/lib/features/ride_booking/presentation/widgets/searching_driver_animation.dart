import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

// ---------------------------------------------------------------------------
// Searching-for-driver bottom sheet  (Figma 7:2182)
// ---------------------------------------------------------------------------

/// A bottom sheet shown while searching for a nearby driver.
///
/// Contains: drag handle • title • taxi SVG • loading dots • status text •
/// ETA countdown • yellow cancel button.
class SearchingDriverSheet extends StatefulWidget {
  const SearchingDriverSheet({
    super.key,
    required this.onCancel,
    this.onAutoCancel,
    this.autoCancel = true,
    this.autoCancelSeconds = 120,
  });

  final VoidCallback onCancel;

  /// Called when auto-cancel timer expires. If null, [onCancel] is used.
  final VoidCallback? onAutoCancel;
  final bool autoCancel;
  final int autoCancelSeconds;

  @override
  State<SearchingDriverSheet> createState() => _SearchingDriverSheetState();
}

class _SearchingDriverSheetState extends State<SearchingDriverSheet>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.autoCancelSeconds;
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (widget.autoCancel && _remainingSeconds <= 0) {
        // Stop timer FIRST to prevent calling onCancel every second.
        _timer?.cancel();
        _timer = null;
        // Use dedicated auto-cancel callback (skips dialog, cancels directly)
        (widget.onAutoCancel ?? widget.onCancel).call();
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _minutes =>
      (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
  String get _seconds =>
      (_remainingSeconds % 60).toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(30.w, 12.h, 30.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────
              Center(
                child: Container(
                  width: 50.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.dragHandle,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // ── Title ────────────────────────────────────────
              IqText(
                AppStrings.searchingForDriver,
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(
                  color: isDark ? AppColors.white : AppColors.textDark,
                ),
              ),
              SizedBox(height: 30.h),

              // ── Taxi SVG illustration ────────────────────────
              SvgPicture.asset(
                'assets/svg/wait_driver.svg',
                width: 201.w,
                height: 138.h,
              ),

              SizedBox(height: 10.h),

              // ── Animated loading dots ────────────────────────
              SizedBox(
                height: 56.h,
                child: _LoadingDots(controller: _dotsController),
              ),

              SizedBox(height: 24.h),

              // ── Status text ──────────────────────────────────
              IqText(
                AppStrings.searchingDriverSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.chipText,
                ),
              ),
              SizedBox(height: 30.h),

              // ── ETA label ────────────────────────────────────
              IqText(
                AppStrings.estimatedArrivalTime,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              SizedBox(height: 8.h),

              // ── Timer ────────────────────────────────────────
              IqText(
                '$_minutes : $_seconds',
                textAlign: TextAlign.center,
                dir: TextDirection.ltr,
                style: AppTypography.heading1.copyWith(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.white : AppColors.black,
                  height: 0.80,
                ),
              ),
              SizedBox(height: 30.h),

              // ── Cancel button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonYellow,
                    foregroundColor: AppColors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000),
                    ),
                  ),
                  child: IqText(
                    AppStrings.cancelTrip,
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated loading dots (bouncing style from Figma)
// ---------------------------------------------------------------------------

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2 phase offset.
            final phase = (controller.value + i * 0.2) % 1.0;
            final bounce = math.sin(phase * math.pi);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Transform.translate(
                offset: Offset(0, -bounce * 10),
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.6 + bounce * 0.4,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
