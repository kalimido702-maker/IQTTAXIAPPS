import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../driver_home/presentation/bloc/driver_home_bloc.dart';
import '../../../driver_home/presentation/bloc/driver_home_event.dart';

/// Displays the driver's vehicle information (read-only).
/// Data comes from the [DriverHomeBloc] state's `homeData`.
class VehicleInfoPage extends StatelessWidget {
  const VehicleInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeData = context.read<DriverHomeBloc>().state.homeData;

    return Scaffold(
      appBar: AppBar(
        title: IqText(
          AppStrings.vehicleInfo,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  children: [
                    _VehicleInfoCard(
                      label: AppStrings.vehicleType,
                      value: homeData?.vehicleTypeName ?? '-',
                    ),
                    SizedBox(height: 12.h),
                    _VehicleInfoCard(
                      label: AppStrings.vehicleMake,
                      value: homeData?.carMake ?? '-',
                    ),
                    SizedBox(height: 12.h),
                    _VehicleInfoCard(
                      label: AppStrings.vehicleModel,
                      value: homeData?.carModel ?? '-',
                    ),
                    SizedBox(height: 12.h),
                    _VehicleInfoCard(
                      label: AppStrings.vehicleNumber,
                      value: homeData?.carNumber ?? '-',
                    ),
                    SizedBox(height: 12.h),
                    _VehicleInfoCard(
                      label: AppStrings.vehicleColor,
                      value: homeData?.carColor ?? '-',
                    ),
                  ],
                ),
              ),
            ),

            // ── Edit button ──
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => _showEditVehicleSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: IqText(
                    AppStrings.edit,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet for editing vehicle color & number.
  void _showEditVehicleSheet(BuildContext context) {
    final homeData = context.read<DriverHomeBloc>().state.homeData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorController =
        TextEditingController(text: homeData?.carColor ?? '');
    final numberController =
        TextEditingController(text: homeData?.carNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetCtx) {
        return _EditVehicleSheet(
          colorController: colorController,
          numberController: numberController,
          parentContext: context,
        );
      },
    );
  }
}

/// Bottom sheet widget for editing vehicle info.
class _EditVehicleSheet extends StatefulWidget {
  const _EditVehicleSheet({
    required this.colorController,
    required this.numberController,
    required this.parentContext,
  });

  final TextEditingController colorController;
  final TextEditingController numberController;
  final BuildContext parentContext;

  @override
  State<_EditVehicleSheet> createState() => _EditVehicleSheetState();
}

class _EditVehicleSheetState extends State<_EditVehicleSheet> {
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Capture references before the async gap.
    final parentCtx = widget.parentContext;
    final driverHomeBloc = parentCtx.read<DriverHomeBloc>();
    final messenger = ScaffoldMessenger.of(parentCtx);
    final parentNavigator = Navigator.of(parentCtx);

    try {
      final dio = sl<ApiClient>().dio;
      final formData = FormData.fromMap({
        'car_color': widget.colorController.text.trim(),
        'car_number': widget.numberController.text.trim(),
      });

      final response = await dio.post(
        'api/v1/user/driver-profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Refresh home data so the page shows updated values.
        driverHomeBloc.add(const DriverHomeLoadRequested());

        Navigator.pop(context); // close bottom sheet
        parentNavigator.pop(); // close vehicle info page

        messenger.showSnackBar(
          SnackBar(
            content: Text(AppStrings.vehicleUpdatedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      } else {
        _showError();
      }
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.vehicleUpdateFailed),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grayBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            IqText(
              AppStrings.edit,
              style: AppTypography.heading3.copyWith(
                color: isDark ? AppColors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            // ── Vehicle Color ──
            _buildField(
              label: AppStrings.vehicleColor,
              controller: widget.colorController,
              isDark: isDark,
            ),
            SizedBox(height: 14.h),
            // ── Vehicle Number ──
            _buildField(
              label: AppStrings.vehicleNumber,
              controller: widget.numberController,
              isDark: isDark,
            ),
            SizedBox(height: 24.h),
            // ── Save button ──
            SizedBox(
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withAlpha(120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : IqText(
                        AppStrings.save,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkGray : AppColors.textSubtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.textDark,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkInputBg : AppColors.grayLightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: AppColors.grayBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}

/// A single vehicle info row: label (bold) on top, value below,
/// with a gold vertical accent bar on the right.
class _VehicleInfoCard extends StatelessWidget {
  const _VehicleInfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grayLightBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // ── Gold accent bar ──
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            // ── Label + Value ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IqText(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  IqText(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkGray
                          : AppColors.textSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
