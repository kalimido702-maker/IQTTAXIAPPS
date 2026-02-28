import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_tile.dart';

/// Notifications listing page — 100% StatelessWidget + BLoC.
///
/// Matches the Figma design: IqAppBar with "الاشعارات" title,
/// "مسح الكل" action, and a scrollable list of notification cards.
///
/// All data comes from [NotificationBloc] — zero hardcoded strings/colors.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(
        title: AppStrings.notifications,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded &&
                  state.notifications.isNotEmpty) {
                return TextButton(
                  onPressed: () => context
                      .read<NotificationBloc>()
                      .add(const NotificationClearAllRequested()),
                  child: IqText(
                    AppStrings.clearAll,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is NotificationError) {
            return Center(
              child: IqText(
                state.message,
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: IqText(
                  AppStrings.noNotifications,
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.gray3),
                ),
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
                  context
                      .read<NotificationBloc>()
                      .add(const NotificationLoadMoreRequested());
                }
                return false;
              },
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: 30.w, vertical: 16.h),
                itemCount: state.notifications.length +
                    (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (context, __) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Divider(
                      color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
                      height: 1.h,
                    );
                  },
                itemBuilder: (_, index) {
                  if (index >= state.notifications.length) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    );
                  }

                  final item = state.notifications[index];
                  return NotificationTile(
                    notification: item,
                    onDelete: () => context
                        .read<NotificationBloc>()
                        .add(NotificationDeleteRequested(item.id)),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
