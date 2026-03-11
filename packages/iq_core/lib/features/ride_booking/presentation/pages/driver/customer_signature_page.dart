import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_text.dart';

/// Page where the customer signs upon receiving delivery.
///
/// Returns the signature image [File] path via `Navigator.pop(context, path)`.
class CustomerSignaturePage extends StatefulWidget {
  const CustomerSignaturePage({super.key});

  @override
  State<CustomerSignaturePage> createState() => _CustomerSignaturePageState();
}

class _CustomerSignaturePageState extends State<CustomerSignaturePage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmSignature() async {
    if (_controller.isEmpty) return;

    final Uint8List? data =
        await _controller.toPngBytes(height: 1000, width: 1000);
    if (data == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    file.writeAsBytesSync(data);

    if (mounted) {
      Navigator.pop(context, file.path);
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

              // ── Title ──
              IqText(
                AppStrings.getCustomerSignature,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // ── Signature pad ──
              Container(
                width: double.infinity,
                height: 280.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grayLightBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.grayBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Signature(
                    controller: _controller,
                    backgroundColor:
                        isDark ? AppColors.darkCard : AppColors.shimmerBase,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // ── Clear button ──
              TextButton(
                onPressed: () => _controller.clear(),
                child: IqText(
                  AppStrings.resetSignature,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(),

              // ── Confirm button ──
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _confirmSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: IqText(
                    AppStrings.confirmSignature,
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
