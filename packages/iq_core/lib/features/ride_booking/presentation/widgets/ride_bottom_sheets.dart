import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/ride_preference_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows available payment methods and returns the selected option.
///
/// Returns: 1=cash, 2=wallet, 0=online/card (null if dismissed).
Future<int?> showPaymentMethodSheet(
  BuildContext context, {
  required int currentPayment,
  Map<String, bool> allowedMethods = const {},
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (_) => _PaymentMethodSheet(
      currentPayment: currentPayment,
      allowedMethods: allowedMethods,
    ),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.currentPayment,
    required this.allowedMethods,
  });

  final int currentPayment;
  final Map<String, bool> allowedMethods;

  @override
  Widget build(BuildContext context) {
    // Build the list of methods. If allowedMethods is empty show all.
    final methods = <_PaymentOption>[
      _PaymentOption(
        code: 1,
        name: AppStrings.cash,
        icon: Icons.payments_outlined,
        enabled: allowedMethods.isEmpty || allowedMethods['cash'] == true,
      ),
      _PaymentOption(
        code: 2,
        name: AppStrings.walletPayment,
        icon: Icons.account_balance_wallet_outlined,
        enabled: allowedMethods.isEmpty || allowedMethods['wallet'] == true,
      ),
      _PaymentOption(
        code: 0,
        name: AppStrings.onlinePayment,
        icon: Icons.credit_card,
        enabled: allowedMethods.isEmpty ||
            allowedMethods['online'] == true ||
            allowedMethods['card'] == true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 16.h),
              IqText(
                AppStrings.selectPaymentMethod,
                style: AppTypography.heading3.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20.h),
              ...methods
                  .where((m) => m.enabled)
                  .map((m) => _PaymentTile(
                        option: m,
                        isSelected: m.code == currentPayment,
                        onTap: () => Navigator.pop(context, m.code),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.code,
    required this.name,
    required this.icon,
    required this.enabled,
  });
  final int code;
  final String name;
  final IconData icon;
  final bool enabled;
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonYellow.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color:
                isSelected ? AppColors.buttonYellow : (isDark ? AppColors.darkDivider : AppColors.inputFill),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 24.w, color: isDark ? AppColors.white : AppColors.black),
            SizedBox(width: 14.w),
            Expanded(
              child: IqText(
                option.name,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 22.w, color: AppColors.buttonYellow),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promo Code Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a bottom sheet for entering a promo code.
///
/// Returns the entered code (null if dismissed or removed).
Future<String?> showPromoCodeSheet(
  BuildContext context, {
  String? currentCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (_) => _PromoCodeSheet(currentCode: currentCode),
  );
}

class _PromoCodeSheet extends StatefulWidget {
  const _PromoCodeSheet({this.currentCode});
  final String? currentCode;

  @override
  State<_PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<_PromoCodeSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 50.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 16.h),
                IqText(
                  AppStrings.promoCode,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20.h),
                // Text field
                TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.enterPromoCode,
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: AppColors.grayDate,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkInputBg : AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Buttons row
                Row(
                  children: [
                    // Remove button (only if there's a current code)
                    if (widget.currentCode != null &&
                        widget.currentCode!.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, ''),
                          child: Container(
                            height: 54.h,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppColors.error, width: 1.5),
                              borderRadius: BorderRadius.circular(1000.r),
                            ),
                            alignment: Alignment.center,
                            child: IqText(
                              AppStrings.remove,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.currentCode != null &&
                        widget.currentCode!.isNotEmpty)
                      SizedBox(width: 12.w),
                    // Apply button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final code = _controller.text.trim();
                          if (code.isNotEmpty) {
                            Navigator.pop(context, code);
                          }
                        },
                        child: Container(
                          height: 54.h,
                          decoration: BoxDecoration(
                            color: AppColors.buttonYellow,
                            borderRadius: BorderRadius.circular(1000.r),
                          ),
                          alignment: Alignment.center,
                          child: IqText(
                            AppStrings.apply,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Ride Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a bottom sheet for scheduling a ride.
///
/// Returns a [DateTime] for the scheduled time, or empty string '' to remove.
/// Returns null if dismissed.
Future<Object?> showScheduleRideSheet(
  BuildContext context, {
  DateTime? currentSchedule,
}) {
  return showModalBottomSheet<Object>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (_) => _ScheduleRideSheet(currentSchedule: currentSchedule),
  );
}

class _ScheduleRideSheet extends StatefulWidget {
  const _ScheduleRideSheet({this.currentSchedule});
  final DateTime? currentSchedule;

  @override
  State<_ScheduleRideSheet> createState() => _ScheduleRideSheetState();
}

class _ScheduleRideSheetState extends State<_ScheduleRideSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final initial =
        widget.currentSchedule ?? DateTime.now().add(const Duration(hours: 1));
    _selectedDate = initial;
    _selectedTime = TimeOfDay.fromDateTime(initial);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 16.h),
              IqText(
                AppStrings.scheduleRide,
                style: AppTypography.heading3.copyWith(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24.h),

              // Date picker row
              _SchedulePickerRow(
                label: AppStrings.selectDate,
                value:
                    '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                icon: Icons.calendar_today_rounded,
                onTap: _pickDate,
              ),
              SizedBox(height: 12.h),

              // Time picker row
              _SchedulePickerRow(
                label: AppStrings.selectTime,
                value: _selectedTime.format(context),
                icon: Icons.access_time_rounded,
                onTap: _pickTime,
              ),
              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  if (widget.currentSchedule != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, ''),
                        child: Container(
                          height: 54.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.error, width: 1.5),
                            borderRadius: BorderRadius.circular(1000.r),
                          ),
                          alignment: Alignment.center,
                          child: IqText(
                            AppStrings.removeSchedule,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.currentSchedule != null) SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, _combinedDateTime),
                      child: Container(
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: AppColors.buttonYellow,
                          borderRadius: BorderRadius.circular(1000.r),
                        ),
                        alignment: Alignment.center,
                        child: IqText(
                          AppStrings.confirm,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePickerRow extends StatelessWidget {
  const _SchedulePickerRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.inputFill,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.w, color: isDark ? AppColors.white : AppColors.black),
            SizedBox(width: 12.w),
            Expanded(
              child: IqText(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.grayDate,
                ),
              ),
            ),
            IqText(
              value,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ride Preferences Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows ride preferences + optional driver instructions.
///
/// Returns a map: {'preferences': List<Map>, 'instructions': String?}
/// Returns null if dismissed.
Future<Map<String, dynamic>?> showRidePreferencesSheet(
  BuildContext context, {
  required List<RidePreferenceModel> availablePreferences,
  List<int> selectedIds = const [],
  String? currentInstructions,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (_) => _RidePreferencesSheet(
      availablePreferences: availablePreferences,
      selectedIds: selectedIds,
      currentInstructions: currentInstructions,
    ),
  );
}

class _RidePreferencesSheet extends StatefulWidget {
  const _RidePreferencesSheet({
    required this.availablePreferences,
    required this.selectedIds,
    this.currentInstructions,
  });

  final List<RidePreferenceModel> availablePreferences;
  final List<int> selectedIds;
  final String? currentInstructions;

  @override
  State<_RidePreferencesSheet> createState() => _RidePreferencesSheetState();
}

class _RidePreferencesSheetState extends State<_RidePreferencesSheet> {
  late Set<int> _selectedIds;
  late TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.selectedIds};
    _instructionsController =
        TextEditingController(text: widget.currentInstructions);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final prefs =
        _selectedIds.map((id) => <String, dynamic>{'id': id}).toList();
    Navigator.pop(context, {
      'preferences': prefs,
      'instructions': _instructionsController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 16.h),
                IqText(
                  AppStrings.ridePreferences,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20.h),

                // Preferences list
                if (widget.availablePreferences.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: IqText(
                      AppStrings.noPreferencesAvailable,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.grayDate,
                      ),
                    ),
                  )
                else
                  ...widget.availablePreferences.map(
                    (pref) => _PreferenceTile(
                      preference: pref,
                      isSelected: _selectedIds.contains(pref.id),
                      onTap: () => _toggle(pref.id),
                    ),
                  ),

                SizedBox(height: 16.h),

                // Driver instructions
                IqText(
                  AppStrings.driverInstructions,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _instructionsController,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.enterInstructions,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.grayDate,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkInputBg : AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Confirm button
                GestureDetector(
                  onTap: _confirm,
                  child: Container(
                    width: double.infinity,
                    height: 54.h,
                    decoration: BoxDecoration(
                      color: AppColors.buttonYellow,
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    alignment: Alignment.center,
                    child: IqText(
                      AppStrings.confirm,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
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

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.preference,
    required this.isSelected,
    required this.onTap,
  });

  final RidePreferenceModel preference;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonYellow.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color:
                isSelected ? AppColors.buttonYellow : (isDark ? AppColors.darkDivider : AppColors.inputFill),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.buttonYellow : (isDark ? AppColors.darkCard : AppColors.white),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.buttonYellow
                      : (isDark ? AppColors.darkDivider : AppColors.grayInactive),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16.w, color: AppColors.black)
                  : null,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: IqText(
                preference.name,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (preference.price > 0)
              IqText(
                '+${preference.price.toStringAsFixed(0)}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.grayDate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
