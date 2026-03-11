import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/incentive_model.dart';
import '../bloc/incentive_bloc.dart';
import '../bloc/incentive_event.dart';
import '../bloc/incentive_state.dart';



/// Driver incentives page — daily / weekly tabs with date selector
/// and milestone list. All loading states use shimmer placeholders.
class IncentivePage extends StatelessWidget {
  const IncentivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.incentiveHeaderDark,
      body: BlocBuilder<IncentiveBloc, IncentiveState>(
        builder: (context, state) {
          // Resolve the "loaded" activeTab (or default 0 for loading/initial).
          final int activeTab =
              state is IncentiveLoaded ? state.activeTab : 0;
          final topPadding = MediaQuery.of(context).padding.top;

          return Column(
            children: [
              // ── Fixed header: safe area + back + title + tabs ──
              _Header(topPadding: topPadding, activeTab: activeTab),

              // ── Body: shimmer / error / loaded (animated transition) ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildBody(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, IncentiveState state) {
    if (state is IncentiveLoading || state is IncentiveInitial) {
      return const _ShimmerBody(key: ValueKey('shimmer'));
    }

    if (state is IncentiveError) {
      return _ErrorBody(key: const ValueKey('error'), message: state.message);
    }

    if (state is IncentiveLoaded) {
      return _LoadedBody(
          key: ValueKey('loaded_${state.activeTab}'), state: state);
    }

    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────
// Header (always visible — back, title, tabs)
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPadding;
  final int activeTab;
  const _Header({required this.topPadding, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.incentiveHeaderDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding),

          // Back + title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 22.w),
                ),
                const Spacer(),
                IqText(
                  AppStrings.incentives,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 42.w),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Tabs
          _TabBar(activeTab: activeTab),

          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int activeTab;
  const _TabBar({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabItem(
          label: AppStrings.daily,
          isActive: activeTab == 0,
          onTap: () {
            if (activeTab != 0) {
              context
                  .read<IncentiveBloc>()
                  .add(const IncentiveLoadRequested(type: 0));
            }
          },
        ),
        _TabItem(
          label: AppStrings.weekly,
          isActive: activeTab == 1,
          onTap: () {
            if (activeTab != 1) {
              context
                  .read<IncentiveBloc>()
                  .add(const IncentiveLoadRequested(type: 1));
            }
          },
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: IqText(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.white.withAlpha(160),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer body — loading placeholder
// ─────────────────────────────────────────────

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final baseColor = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
    final highlightColor =
        isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

    return Column(
      children: [
        // ── Date strip shimmer ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 90.h,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // ── Milestone area shimmer ──
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  children: [
                    // Earn-up-to card placeholder
                    Container(
                      width: double.infinity,
                      height: 130.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Milestone rows placeholder
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Row(
                          children: [
                            // Dot
                            Container(
                              width: 18.w,
                              height: 18.w,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Text lines
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 180.w,
                                    height: 14.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius:
                                          BorderRadius.circular(4.r),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Container(
                                    width: 100.w,
                                    height: 10.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius:
                                          BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Amount placeholder
                            Container(
                              width: 60.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: AppColors.white.withValues(alpha: 0.7)),
            SizedBox(height: 16.h),
            IqText(
              message,
              style:
                  AppTypography.bodyLarge.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: () => context
                  .read<IncentiveBloc>()
                  .add(const IncentiveLoadRequested(type: 0)),
              icon: Icon(Icons.refresh, color: AppColors.white),
              label: IqText(
                AppStrings.retry,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loaded body (date strip + milestones)
// ─────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  final IncentiveLoaded state;
  const _LoadedBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<IncentiveBloc>();

    if (state.dates.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 56.w, color: AppColors.primary),
              SizedBox(height: 16.h),
              IqText(
                AppStrings.completeFirstTripForIncentive,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Date strip ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _DateStrip(
            dates: state.dates,
            selectedIndex: state.selectedDateIndex,
            activeTab: state.activeTab,
            bloc: bloc,
          ),
        ),

        SizedBox(height: 16.h),

        // ── Milestones (animated) ──
        Expanded(
          child: state.selectedDate != null
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _MilestoneContent(
                    key: ValueKey(state.selectedDateIndex),
                    date: state.selectedDate!,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Date strip (floating card)
// ─────────────────────────────────────────────

class _DateStrip extends StatefulWidget {
  final List<IncentiveDate> dates;
  final int selectedIndex;
  final int activeTab;
  final IncentiveBloc bloc;

  const _DateStrip({
    required this.dates,
    required this.selectedIndex,
    required this.activeTab,
    required this.bloc,
  });

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.activeTab != widget.activeTab) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    if (widget.selectedIndex < 0 || !_scrollCtrl.hasClients) return;
    final itemWidth = widget.activeTab == 0 ? 56.0.w : 66.0.w;
    final offset = (widget.selectedIndex * itemWidth) -
        (_scrollCtrl.position.viewportDimension / 2) +
        (itemWidth / 2);
    _scrollCtrl.animateTo(
      offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.white;

    return Container(
      height: 90.h,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.dates.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final d = widget.dates[index];
          final isSelected = index == widget.selectedIndex;
          final label =
              widget.bloc.formatDateLabel(d.date, widget.activeTab);

          // For daily mode, disable future dates.
          bool isFuture = false;
          if (widget.activeTab == 0) {
            try {
              final dt = DateFormat('dd-MMM-yy').parse(d.date);
              isFuture = dt.isAfter(DateTime.now());
            } catch (_) {}
          }

          final onSurface = Theme.of(context).colorScheme.onSurface;

          return GestureDetector(
            onTap: isFuture
                ? null
                : () => widget.bloc
                    .add(IncentiveDateSelected(dateIndex: index)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IqText(
                  d.day,
                  style: AppTypography.caption.copyWith(
                    color: isFuture
                        ? AppColors.grayPlaceholder
                        : isSelected
                            ? onSurface
                            : onSurface.withAlpha(180),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.activeTab == 0 ? 38.w : 48.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.incentiveHeaderDark
                        : Colors.transparent,
                    border: Border.all(
                      color: isFuture
                          ? Colors.transparent
                          : isSelected
                              ? AppColors.incentiveHeaderDark
                              : onSurface.withAlpha(80),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: IqText(
                    label,
                    style: AppTypography.numberSmall.copyWith(
                      fontSize:
                          widget.activeTab == 0 ? 16.sp : 10.sp,
                      color: isFuture
                          ? AppColors.grayPlaceholder
                          : isSelected
                              ? AppColors.white
                              : onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    dir: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Milestone content (bottom card)
// ─────────────────────────────────────────────

class _MilestoneContent extends StatelessWidget {
  final IncentiveDate date;
  const _MilestoneContent({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final hasIncentives = date.upcomingIncentives.isNotEmpty;
    final allCompleted = hasIncentives &&
        date.upcomingIncentives.every((i) => i.isCompleted);
    final noneCompleted = !hasIncentives ||
        date.upcomingIncentives.every((i) => !i.isCompleted);

    // Green if all completed, red if none, amber/orange if partial.
    final Color headerColor;
    final String headerText;
    if (!hasIncentives) {
      headerColor = AppColors.incentiveHeaderDark;
      headerText = AppStrings.noIncentivesAvailable;
    } else if (allCompleted) {
      headerColor = AppColors.incentiveSuccess;
      headerText = AppStrings.gotIncentive;
    } else if (noneCompleted) {
      headerColor = AppColors.error;
      headerText = AppStrings.didNotGetIncentive;
    } else {
      headerColor = AppColors.incentivePartial;
      headerText = AppStrings.completeMoreForIncentive;
    }

    // ── Empty / no-data state ──
    if (!hasIncentives) {
      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.grayDivider,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 44.w,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 20.h),
                IqText(
                  AppStrings.noIncentivesAvailable,
                  style: AppTypography.heading3.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                IqText(
                  AppStrings.completeFirstTripForIncentive,
                  style: AppTypography.bodyMedium.copyWith(
                    color: onSurface.withAlpha(140),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: 32.h,
        ),
        child: Column(
          children: [
            // ── Earn-up-to card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    headerColor,
                    headerColor.withAlpha(200),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: headerColor.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  IqText(
                    AppStrings.earnUpTo,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withAlpha(210),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  IqText(
                    '${date.earnUpto} ${AppStrings.currencyIQD}',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28.sp,
                    ),
                    dir: TextDirection.ltr,
                  ),
                  SizedBox(height: 6.h),
                  IqText(
                    '${AppStrings.byCompletingTrips} ${date.totalRides} ${AppStrings.totalRidesCount}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withAlpha(200),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: IqText(
                      headerText,
                      style: AppTypography.bodySmall.copyWith(
                        color: headerColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // ── Milestone list ──
            ...List.generate(date.upcomingIncentives.length, (i) {
              final milestone = date.upcomingIncentives[i];
              final isLast =
                  i == date.upcomingIncentives.length - 1;
              final completed = milestone.isCompleted;

              final dotColor = completed
                  ? AppColors.incentiveSuccess
                  : AppColors.error;
              final textColor = completed
                  ? AppColors.incentiveSuccess
                  : AppColors.error;
              final subtitleColor = onSurface.withAlpha(140);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline: dot + connector
                    SizedBox(
                      width: 28.w,
                      child: Column(
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: completed
                                  ? dotColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dotColor,
                                width: completed ? 0 : 2.5,
                              ),
                            ),
                            child: completed
                                ? Icon(Icons.check,
                                    size: 13.w,
                                    color: AppColors.white)
                                : null,
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDark
                                    ? AppColors.white.withValues(alpha: 0.24)
                                    : AppColors.shimmerBase,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Text
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 22.h),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                IqText(
                                  '${AppStrings.completeTrips} ${milestone.rideCount} ${AppStrings.totalRidesCount}',
                                  style: AppTypography.bodyLarge
                                      .copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                IqText(
                                  '${milestone.incentiveAmount.toStringAsFixed(0)} ${AppStrings.currencyIQD}',
                                  style: AppTypography.bodyLarge
                                      .copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  dir: TextDirection.ltr,
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            IqText(
                              completed
                                  ? AppStrings.achievedGoal
                                  : AppStrings.didNotCompleteGoal,
                              style: AppTypography.caption.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
