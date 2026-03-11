import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/weekly_earnings_model.dart';
import '../bloc/earnings_bloc.dart';
import '../bloc/earnings_event.dart';
import '../bloc/earnings_state.dart';
import '../widgets/day_selector.dart';
import '../widgets/earnings_bar_chart.dart';
import '../widgets/total_earnings_card.dart';

/// Earnings page (driver only) — 100% StatelessWidget + BLoC.
///
/// Displays weekly earnings with:
/// - Total earnings black card
/// - Date range and login time
/// - Day-of-week selector
/// - Daily stats (trips, cash, wallet)
/// - Bar chart
/// - Summary card
///
/// All data from `GET api/v1/driver/weekly-earnings`.
class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(title: AppStrings.earnings),
      body: BlocBuilder<EarningsBloc, EarningsState>(
        builder: (context, state) {
          if (state is EarningsLoading || state is EarningsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is EarningsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IqText(
                    state.message,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => context.read<EarningsBloc>().add(
                      const EarningsLoadRequested(),
                    ),
                    child: IqText(
                      AppStrings.retry,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is! EarningsLoaded) {
            return const SizedBox.shrink();
          }

          final e = state.earnings;
          final selectedDay = state.selectedDayIndex;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 29.w, vertical: 20.h),
            child: Column(
              children: [
                // ── Total Earnings Card ──
                TotalEarningsCard(
                  totalEarnings: e.totalEarnings,
                  currencySymbol: e.currencySymbol,
                  title: AppStrings.totalEarnings,
                ),
                SizedBox(height: 15.h),

                // ── Date range ──
                IqText(
                  '${e.startOfWeek} - ${e.endOfWeek}',
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15.h),

                // ── Hours worked ──
                IqText(
                  '${AppStrings.loginTime} : ${e.totalHoursWorked}',
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),

                // ── Day Selector ──
                DaySelector(
                  selectedIndex: selectedDay,
                  disablePrevious: e.disablePreviousWeek,
                  disableNext: e.disableNextWeek,
                  onDaySelected: (i) =>
                      context.read<EarningsBloc>().add(EarningsDaySelected(i)),
                  onPrevious: () => context.read<EarningsBloc>().add(
                    EarningsWeekChanged(e.currentWeekNumber - 1),
                  ),
                  onNext: () => context.read<EarningsBloc>().add(
                    EarningsWeekChanged(e.currentWeekNumber + 1),
                  ),
                ),
                SizedBox(height: 30.h),

                // ── Trips / Cash / Wallet row ──
                _buildStatsSection(context, e),
                SizedBox(height: 30.h),

                // ── Bar Chart ──
                EarningsBarChart(
                  earnings: e,
                  selectedDayIndex: selectedDay,
                  onBarTap: (i) =>
                      context.read<EarningsBloc>().add(EarningsDaySelected(i)),
                ),
                SizedBox(height: 30.h),

                // ── Daily summary card ──
                _buildDaySummaryCard(context, e),
                SizedBox(height: 30.h),

                // ── Empty state (when selected day has no data) ──
                if (selectedDay >= 0 && e.earningsForDay(selectedDay) <= 0) ...[
                  SizedBox(height: 10.h),
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 80.w,
                    color: AppColors.gray1,
                  ),
                  SizedBox(height: 10.h),
                  IqText(
                    AppStrings.noSummaryForDay,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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

  /// Builds the trips count + cash/wallet amounts section.
  Widget _buildStatsSection(BuildContext context, WeeklyEarningsModel e) {
    return Column(
      children: [
        IqText(
          '${AppStrings.trips} : ${e.totalTripsCount}',
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cash
            Row(
              children: [
                IqText(
                  '${e.currencySymbol} ${NumberFormat('#,###').format(e.totalCashTripAmount.toInt())}',
                  style: AppTypography.heading2.copyWith(
                    fontFamily: AppTypography.fontFamilyLatin,
                  ),
                  dir: TextDirection.ltr,
                ),
                SizedBox(width: 10.w),
                IqText(
                  '${AppStrings.cashLabel} :',
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
            // Wallet
            Row(
              children: [
                IqText(
                  '${e.currencySymbol} ${NumberFormat('#,###').format(e.totalWalletTripAmount.toInt())}',
                  style: AppTypography.heading2.copyWith(
                    fontFamily: AppTypography.fontFamilyLatin,
                  ),
                  dir: TextDirection.ltr,
                ),
                SizedBox(width: 10.w),
                IqText(
                  '${AppStrings.wallet} :',
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Summary card with login time and distance, bordered in yellow.
  Widget _buildDaySummaryCard(BuildContext context, WeeklyEarningsModel e) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.primaryDark, width: 1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          IqText(
            '${AppStrings.loginTime} : ${e.totalHoursWorked}',
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IqText(
                '${e.totalTripKms.toStringAsFixed(0)} ${AppStrings.km}',
                style: AppTypography.heading2.copyWith(
                  fontFamily: AppTypography.fontFamilyLatin,
                ),
                dir: TextDirection.ltr,
              ),
              SizedBox(width: 10.w),
              IqText(
                '${AppStrings.distanceTraveled} :',
                style: AppTypography.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
