import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_empty_state.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/trip_history_bloc.dart';
import '../bloc/trip_history_event.dart';
import '../bloc/trip_history_state.dart';
import '../widgets/trip_history_card.dart';
import 'trip_detail_page.dart';

/// سجل الرحلات — Trip History page shared between passenger & driver.
///
/// 100% StatelessWidget. Tab switching and data loading managed by [TripHistoryBloc].
class TripHistoryPage extends StatelessWidget {
  const TripHistoryPage({super.key});

  static final _tabs = [
    AppStrings.completed,
    AppStrings.upcoming,
    AppStrings.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: IqAppBar(title: AppStrings.tripHistoryTitle),
      body: Column(
        children: [
          // ── Tab Bar ──
          _TabBar(tabs: _tabs),
          SizedBox(height: 8.h),

          // ── Content ──
          Expanded(
            child: BlocBuilder<TripHistoryBloc, TripHistoryState>(
              builder: (context, state) {
                if (state is TripHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (state is TripHistoryError) {
                  return IqEmptyState(
                    icon: Icons.error_outline,
                    message: state.message,
                    actionText: AppStrings.retry,
                    onAction: () => context
                        .read<TripHistoryBloc>()
                        .add(const TripHistoryRefreshRequested()),
                  );
                }

                if (state is TripHistoryLoaded) {
                  if (state.trips.isEmpty) {
                    return IqEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: AppStrings.noTripsFound,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context
                          .read<TripHistoryBloc>()
                          .add(const TripHistoryRefreshRequested());
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200 &&
                            state.hasMore &&
                            !state.isLoadingMore) {
                          context
                              .read<TripHistoryBloc>()
                              .add(const TripHistoryLoadMoreRequested());
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        itemCount:
                            state.trips.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          if (index == state.trips.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: const CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final trip = state.trips[index];
                          return TripHistoryCard(
                            trip: trip,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TripDetailPage(trip: trip),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                }

                // Initial state
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Tab Bar ────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TripHistoryBloc, TripHistoryState>(
      buildWhen: (prev, curr) => prev.activeTab != curr.activeTab,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.white.withValues(alpha: 0.12) : AppColors.grayBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isActive = state.activeTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context
                        .read<TripHistoryBloc>()
                        .add(TripHistoryTabChanged(index));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: IqText(
                          tabs[index],
                          style: AppTypography.labelMedium.copyWith(
                            color: isActive
                                ? (isDark ? AppColors.white : AppColors.black)
                                : AppColors.gray2,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Active indicator line
                      Container(
                        height: 3.h,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
