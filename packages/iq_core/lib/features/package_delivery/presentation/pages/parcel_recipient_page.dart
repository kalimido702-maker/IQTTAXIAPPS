import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_phone_input.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/widgets/iq_text_field.dart';
import '../bloc/package_delivery_bloc.dart';
import '../bloc/package_delivery_event.dart';
import '../bloc/package_delivery_state.dart';

/// Screen 3 — Recipient details.
///
/// User enters the recipient's name, phone number, and delivery instructions.
/// A "استقبل بنفسي" (Receive self) checkbox bypasses name/phone requirement.
///
/// Matches Figma node 7:4142.
class ParcelRecipientPage extends StatefulWidget {
  const ParcelRecipientPage({
    super.key,
    required this.onConfirmed,
  });

  /// Called when the bloc transitions to [loadingBooking] or [bookingReady].
  final VoidCallback onConfirmed;

  @override
  State<ParcelRecipientPage> createState() => _ParcelRecipientPageState();
}

class _ParcelRecipientPageState extends State<ParcelRecipientPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _receiveSelf = false;

  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
      listenWhen: (prev, curr) =>
          curr.status == PackageDeliveryStatus.loadingBooking ||
          curr.status == PackageDeliveryStatus.bookingReady,
      listener: (_, __) => widget.onConfirmed(),
      child: Scaffold(
        appBar: IqAppBar(title: AppStrings.packageRecipientDetails),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              // welcome text
              IqText(
                AppStrings.welcomeBack,
                style: AppTypography.labelLarge,
              ),
              IqText(
                AppStrings.recipientSubtitle,
                style: AppTypography.bodyLarge,
              ),

              SizedBox(height: 24.h),

              // ── Receive self checkbox ──
              _buildReceiveSelfCheckbox(),

              SizedBox(height: 24.h),

              // ── Sender / Recipient name ──
              IqTextField(
                label: AppStrings.senderName,
                hintText: AppStrings.recipientNameHint,
                controller: _nameController,
                errorText: _nameError,
                enabled: !_receiveSelf,
                onChanged: (_) => _clearErrors(),
              ),

              SizedBox(height: 20.h),

              // ── Phone number ──
              IqText(AppStrings.phoneNumber, style: AppTypography.labelLarge),
              SizedBox(height: 15.h),
              IgnorePointer(
                ignoring: _receiveSelf,
                child: Opacity(
                  opacity: _receiveSelf ? 0.5 : 1.0,
                  child: IqPhoneInput(
                    errorText: _phoneError,
                    onChanged: (value) {
                      _phoneController.text = value;
                      _clearErrors();
                    },
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ── Instructions ──
              IqTextField(
                label: AppStrings.instructions,
                hintText: AppStrings.notesHint,
                controller: _instructionsController,
                maxLines: 4,
              ),

              SizedBox(height: 40.h),

              // ── Confirm button ──
              BlocBuilder<PackageDeliveryBloc, PackageDeliveryState>(
                builder: (context, state) {
                  return IqPrimaryButton(
                    text: AppStrings.confirm,
                    isLoading:
                        state.status == PackageDeliveryStatus.loadingBooking,
                    onPressed: _onConfirm,
                  );
                },
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Receive self toggle
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildReceiveSelfCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IqText(
          AppStrings.receiveSelf,
          style: AppTypography.bodyLarge,
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 20.w,
          height: 20.w,
          child: Checkbox(
            value: _receiveSelf,
            onChanged: (val) {
              setState(() {
                _receiveSelf = val ?? false;
                if (_receiveSelf) {
                  _nameError = null;
                  _phoneError = null;
                }
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r),
            ),
            side: const BorderSide(
              color: AppColors.grayInactive,
              width: 1.5,
            ),
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Validation & submit
  // ═══════════════════════════════════════════════════════════════════

  void _clearErrors() {
    if (_nameError != null || _phoneError != null) {
      setState(() {
        _nameError = null;
        _phoneError = null;
      });
    }
  }

  void _onConfirm() {
    if (!_receiveSelf) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      bool hasError = false;

      if (name.isEmpty) {
        _nameError = AppStrings.pleaseEnterName;
        hasError = true;
      }
      if (phone.isEmpty || phone.length < 7) {
        _phoneError = AppStrings.pleaseEnterValidPhone;
        hasError = true;
      }

      if (hasError) {
        setState(() {});
        return;
      }
    }

    context.read<PackageDeliveryBloc>().add(
          PackageDeliveryRecipientConfirmed(
            name: _receiveSelf ? '' : _nameController.text.trim(),
            mobile: _receiveSelf ? '' : _phoneController.text.trim(),
            instructions: _instructionsController.text.trim(),
            receiveSelf: _receiveSelf,
          ),
        );
  }
}
