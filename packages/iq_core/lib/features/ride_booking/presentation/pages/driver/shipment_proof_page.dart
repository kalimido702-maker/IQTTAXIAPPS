import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_text.dart';

/// Page where the driver uploads an image as shipping proof
/// (before loading or after unloading goods for delivery trips).
///
/// Returns the selected [File] path via `Navigator.pop(context, path)`.
class ShipmentProofPage extends StatefulWidget {
  const ShipmentProofPage({super.key, this.isBefore = true});

  /// `true` = upload proof before trip (loading),
  /// `false` = upload proof after trip (unloading).
  final bool isBefore;

  @override
  State<ShipmentProofPage> createState() => _ShipmentProofPageState();
}

class _ShipmentProofPageState extends State<ShipmentProofPage> {
  File? _selectedImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: IqText(
          AppStrings.shipmentVerification,
          style: AppTypography.heading3.copyWith(
            color: isDark ? AppColors.white : AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 24.h),

              // ── Title text ──
              IqText(
                widget.isBefore
                    ? AppStrings.uploadShipmentProofBefore
                    : AppStrings.uploadShipmentProofAfter,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // ── Dotted upload area ──
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); _pickImage(); },
                child: Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.grayLightBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.grayBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200.h,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 32.w,
                              color: AppColors.grayPlaceholder,
                            ),
                            SizedBox(height: 8.h),
                            IqText(
                              AppStrings.uploadImageJpgPng,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.grayPlaceholder,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const Spacer(),

              // ── Continue button ──
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _selectedImage != null
                      ? () => Navigator.pop(context, _selectedImage!.path)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grayBorder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: IqText(
                    AppStrings.continueText,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
