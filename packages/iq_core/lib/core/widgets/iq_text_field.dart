import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'iq_text.dart';

/// App-wide TextField replacement.
///
/// Wraps [TextField] with consistent styling and full RTL / LTR support.
///
/// **RTL/LTR behaviour:**
///  - By default the field inherits the ambient [Directionality]
///    (RTL in IQ Taxi).
///  - Set [dir] to [TextDirection.ltr] for Latin / numeric-only fields.
///  - [textAlign] auto-adjusts to match the direction unless overridden.
class IqTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;

  /// Text direction for both the label and the input.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? dir;

  /// Explicit text alignment. If null, it mirrors [dir]:
  ///  - RTL → [TextAlign.right]
  ///  - LTR → [TextAlign.left]
  final TextAlign? textAlign;

  /// Custom text style for the input value.
  final TextStyle? style;

  const IqTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.inputFormatters,
    this.textInputAction,
    this.onTap,
    this.dir,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve direction: explicit → ambient
    final resolvedDir = dir ?? Directionality.of(context);
    final resolvedAlign = textAlign ??
        (resolvedDir == TextDirection.rtl ? TextAlign.right : TextAlign.left);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          IqText(
            label!,
            style: AppTypography.labelLarge,
            dir: resolvedDir,
          ),
          SizedBox(height: 15.h),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          textDirection: resolvedDir,
          textAlign: resolvedAlign,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.inputHint,
            hintTextDirection: resolvedDir,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBackground,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: maxLines != null && maxLines! > 1 ? 16.h : 8.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.inputBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.inputFocusBorder,
                width: 2,
              ),
            ),
          ),
          style: style ?? AppTypography.inputText,
        ),
      ],
    );
  }
}
