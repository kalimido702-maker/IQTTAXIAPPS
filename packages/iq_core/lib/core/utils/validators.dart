import '../constants/app_strings.dart';

/// Phone number validation for Iraqi numbers
class Validators {
  Validators._();

  /// Validate Iraqi phone number (10 digits after country code)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterPhone;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  /// Validate OTP code
  static String? validateOtp(String? value, {int length = 6}) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterOtp;
    }
    if (value.length != length) {
      return '${AppStrings.otpMustBeDigits} $length ${AppStrings.digits}';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterName;
    }
    if (value.trim().length < 2) {
      return AppStrings.nameTooShort;
    }
    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }
}
