import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'iq_text.dart';

/// Iraq flag as an inline SVG so we don't depend on any external asset file.
const _iraqFlagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 600">
  <rect width="900" height="200" fill="#CE1126"/>
  <rect y="200" width="900" height="200" fill="#FFF"/>
  <rect y="400" width="900" height="200" fill="#000"/>
  <g fill="#007A3D" transform="translate(450,300)">
    <text font-size="120" font-family="serif" text-anchor="middle" dy="30">الله أكبر</text>
  </g>
</svg>
''';

/// Phone number input field matching Figma design.
///
/// Layout:
/// ┌──────────────────────────────────────────┐
/// │  🇮🇶  +964 |  123 456 7899              │
/// └──────────────────────────────────────────┘
///
/// • White background, 1px `#FEB800` border, 12px radius
/// • Iraq flag (30×20) → "+964 | " prefix → phone TextField
/// • Height: 52
class IqPhoneInput extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;

  const IqPhoneInput({
    super.key,
    this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 52.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: errorText != null
                    ? AppColors.error
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Iraq flag ──
              ClipRRect(
                borderRadius: BorderRadius.circular(2.r),
                child: SvgPicture.string(
                  _iraqFlagSvg,
                  width: 30.w,
                  height: 20.h,
                  fit: BoxFit.cover,
                ),
              ),

              SizedBox(width: 8.w),

              // ── Country code ──
              IqText(
                '+964 | ',
                dir: TextDirection.ltr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16.sp,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  height: 1.13,
                ),
              ),

              // ── Phone text field ──
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '123 456 7899',
                    hintStyle: TextStyle(
                      color: AppColors.grayLight,
                      fontSize: 16.sp,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      height: 1.13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16.sp,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    height: 1.13,
                  ),
                ),
              ),
            ].reversed.toList(), // Reverse to have the flag on the left and text on the right
          ),
        ),

        // ── Error text ──
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          IqText(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
