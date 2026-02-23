import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';
import '../widgets/date_picker_card.dart';
import '../widgets/detail_row.dart';
import '../widgets/summary_card.dart';

/// Reports page (driver only) — 100% StatelessWidget + BLoC.
///
/// Allows drivers to select a date range, filter, and view
/// trip/earnings report data.
///
/// All state (dates, loading, data) managed by [ReportsBloc].
/// Zero hardcoded strings/colors. Zero StatefulWidget. Zero setState.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IqAppBar(title: AppStrings.reports),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          final dates = _extractDates(state);
          final isLoading = state is ReportsLoading;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
            child: Column(
              children: [
                // ── Section title ──
                IqText(
                  AppStrings.createReport,
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),

                // ── Date pickers row ──
                Row(
                  children: [
                    Expanded(
                      child: DatePickerCard(
                        label: _formatDate(dates.$2),
                        onTap: () => _pickDate(
                          context: context,
                          initial: dates.$2,
                          onPicked: (d) => context
                              .read<ReportsBloc>()
                              .add(ReportsToDateChanged(d)),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: DatePickerCard(
                        label: _formatDate(dates.$1),
                        onTap: () => _pickDate(
                          context: context,
                          initial: dates.$1,
                          onPicked: (d) => context
                              .read<ReportsBloc>()
                              .add(ReportsFromDateChanged(d)),
                        ),
                      ),
                    ),
                  ].reversed.toList(), // Reverse for RTL
                ),
                SizedBox(height: 30.h),

                // ── Filter button ──
                IqPrimaryButton(
                  text: AppStrings.filter,
                  isLoading: isLoading,
                  onPressed: () => context
                      .read<ReportsBloc>()
                      .add(const ReportsFilterRequested()),
                ),

                // ── Report data ──
                if (state is ReportsLoaded) ...[
                  SizedBox(height: 30.h),

                  // Period display
                  IqText(
                    AppStrings.selectedPeriod,
                    style: AppTypography.heading3,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5.h),
                  IqText(
                    '${_formatDate(state.fromDate)} - ${_formatDate(state.toDate)}',
                    style: AppTypography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: AppStrings.trips,
                          value: '${state.report.totalTrips}',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SummaryCard(
                          title: AppStrings.wallet,
                          value:
                              '${state.report.totalWalletAmount.toInt()}',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SummaryCard(
                          title: AppStrings.cashLabel,
                          value:
                              '${state.report.totalCashAmount.toInt()}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),

                  // Report details
                  Align(
                    alignment: Alignment.centerRight,
                    child: IqText(
                      AppStrings.reportDetailsList,
                      style: AppTypography.labelLarge,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  DetailRow(
                    label: AppStrings.totalTripKm,
                    value:
                        '${state.report.totalTripKms.toStringAsFixed(0)} km',
                  ),
                  SizedBox(height: 15.h),
                  DetailRow(
                    label: AppStrings.walletInstallment,
                    value:
                        '${state.report.currencySymbol} ${state.report.walletInstallment.toInt()}',
                  ),
                  SizedBox(height: 15.h),
                  DetailRow(
                    label: AppStrings.cashInstallment,
                    value:
                        '${state.report.currencySymbol} ${NumberFormat('#,###').format(state.report.cashInstallment.toInt())}',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: Divider(
                        color: AppColors.grayBorder, height: 1.h),
                  ),
                  DetailRow(
                    label: AppStrings.netEarnings,
                    value:
                        '${state.report.currencySymbol} ${NumberFormat('#,###').format(state.report.netEarnings.toInt())}',
                    isTotal: true,
                  ),
                ],

                // ── Error ──
                if (state is ReportsError) ...[
                  SizedBox(height: 20.h),
                  IqText(
                    state.message,
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.error),
                  ),
                ],

                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Format a [DateTime] to Arabic date string using [AppStrings.arabicMonths].
  String _formatDate(DateTime date) {
    return '${date.day} ${AppStrings.arabicMonths[date.month - 1]} , ${date.year}';
  }

  /// Extract (fromDate, toDate) from any [ReportsState].
  (DateTime, DateTime) _extractDates(ReportsState state) {
    if (state is ReportsIdle) return (state.fromDate, state.toDate);
    if (state is ReportsLoading) return (state.fromDate, state.toDate);
    if (state is ReportsLoaded) return (state.fromDate, state.toDate);
    if (state is ReportsError) return (state.fromDate, state.toDate);
    final now = DateTime.now();
    return (now.subtract(const Duration(days: 30)), now);
  }

  /// Show platform date picker and dispatch the selected date.
  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }
}
