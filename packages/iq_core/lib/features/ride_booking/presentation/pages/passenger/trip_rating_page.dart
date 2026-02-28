import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_image.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../widgets/trip_rating_widget.dart';

/// Trip rating page (Figma 7:1036 passenger, 7:6659 driver).
/// Stars, comment, submit.
class TripRatingPage extends StatefulWidget {
  const TripRatingPage({
    super.key,
    required this.requestId,
    required this.otherPersonName,
    this.otherPersonPhoto,
    this.isDriver = false,
  });

  final String requestId;
  final String otherPersonName;
  final String? otherPersonPhoto;
  final bool isDriver;

  @override
  State<TripRatingPage> createState() => _TripRatingPageState();
}

class _TripRatingPageState extends State<TripRatingPage> {
  int _rating = 0;
  String _comment = '';
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);

    final repo = sl<BookingRepository>();
    await repo.submitRating(
      requestId: widget.requestId,
      rating: _rating,
      comment: _comment.isNotEmpty ? _comment : null,
    );

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    // Pop all the way back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingLG,
              vertical: AppDimens.paddingMD,
            ),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                // Header
                IqText(
                  AppStrings.rating,
                  style: AppTypography.heading2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 32.h),

                // Avatar
                ClipOval(
                  child: SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: widget.otherPersonPhoto != null &&
                            widget.otherPersonPhoto!.isNotEmpty
                        ? IqImage(
                            widget.otherPersonPhoto!,
                            fit: BoxFit.cover,
                            width: 100.w,
                            height: 100.w,
                          )
                        : Container(
                            color: AppColors.grayLightBg,
                            child: Icon(
                              Icons.person,
                              size: 56.w,
                              color: AppColors.grayLight,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Name
                IqText(
                  widget.otherPersonName,
                  style: AppTypography.heading3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 24.h),

                // Question
                IqText(
                  '${AppStrings.howWasYourTripWith} ${widget.otherPersonName}؟',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSubtitle,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Rating widget
                TripRatingWidget(
                  onRatingChanged: (r) => setState(() => _rating = r),
                  onCommentChanged: (c) => _comment = c,
                  commentHint: AppStrings.writeCommentHere,
                ),
                SizedBox(height: 40.h),

                // Submit
                IqPrimaryButton(
                  text: AppStrings.addRating,
                  isLoading: _submitting,
                  onPressed: _rating > 0 ? _submit : null,
                ),

                // Skip
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: IqText(
                    AppStrings.skip,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
