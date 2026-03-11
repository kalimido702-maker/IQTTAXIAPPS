import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/widgets/iq_text_field.dart';

/// Interactive star-rating widget with optional comment field.
class TripRatingWidget extends StatefulWidget {
  TripRatingWidget({
    super.key,
    this.initialRating = 0,
    this.onRatingChanged,
    this.onCommentChanged,
    this.showComment = true,
    String? commentHint,
  }) : commentHint = commentHint ?? AppStrings.writeCommentHere;

  final int initialRating;
  final ValueChanged<int>? onRatingChanged;
  final ValueChanged<String>? onCommentChanged;
  final bool showComment;
  final String commentHint;

  @override
  State<TripRatingWidget> createState() => _TripRatingWidgetState();
}

class _TripRatingWidgetState extends State<TripRatingWidget> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _setRating(int value) {
    if (value == _rating) return;
    HapticFeedback.lightImpact();
    setState(() => _rating = value);
    widget.onRatingChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => _setRating(starIndex),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Icon(
                  starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: starIndex <= _rating ? AppColors.starFilled : AppColors.starEmpty,
                  size: 44.w,
                ),
              ),
            );
          }),
        ),
        if (widget.showComment) ...[
          SizedBox(height: 20.h),
          IqTextField(
            hintText: widget.commentHint,
            maxLines: 3,
            onChanged: widget.onCommentChanged,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}

/// Non-interactive read-only star display.
class TripRatingStars extends StatelessWidget {
  const TripRatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = true,
  });

  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: AppColors.starFilled,
          size: size.w,
        ),
        SizedBox(width: 2.w),
        if (showValue)
          IqText(
            rating.toStringAsFixed(1),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textDark,
            ),
            dir: TextDirection.ltr,
          ),
      ],
    );
  }
}
