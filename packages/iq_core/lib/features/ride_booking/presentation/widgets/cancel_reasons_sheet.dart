import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/widgets/iq_text_field.dart';
import '../../data/models/cancel_reason_model.dart';

/// Bottom sheet for selecting a cancellation reason.
class CancelReasonsSheet extends StatefulWidget {
  const CancelReasonsSheet({
    super.key,
    required this.reasons,
    required this.onConfirm,
    this.title = 'سبب الإلغاء',
  });

  final List<CancelReasonModel> reasons;
  final void Function(String reason, String? customReason) onConfirm;
  final String title;

  @override
  State<CancelReasonsSheet> createState() => _CancelReasonsSheetState();
}

class _CancelReasonsSheetState extends State<CancelReasonsSheet> {
  int? _selectedIndex;
  final _customController = TextEditingController();

  bool get _isOtherSelected {
    if (_selectedIndex == null) return false;
    final reason = widget.reasons[_selectedIndex!];
    return reason.reason.contains('أخرى') || reason.reason.contains('other');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.grayBorder,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          IqText(
            widget.title,
            style: AppTypography.heading3.copyWith(color: AppColors.textDark),
          ),
          SizedBox(height: 16.h),
          // Reason list
          ...List.generate(widget.reasons.length, (index) {
            final reason = widget.reasons[index];
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedIndex = index);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary50 : AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grayBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.grayLight,
                          width: isSelected ? 6.w : 2.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: IqText(
                        reason.reason,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Custom reason text field
          if (_isOtherSelected) ...[
            SizedBox(height: 8.h),
            IqTextField(
              controller: _customController,
              hintText: 'اكتب السبب هنا...',
              maxLines: 3,
            ),
          ],
          SizedBox(height: 20.h),
          IqPrimaryButton(
            text: 'تأكيد',
            onPressed: _selectedIndex != null
                ? () {
                    final reason = widget.reasons[_selectedIndex!].reason;
                    final custom =
                        _isOtherSelected ? _customController.text.trim() : null;
                    widget.onConfirm(reason, custom);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
