import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/favourite_location_bloc.dart';
import '../bloc/favourite_location_event.dart';
import '../bloc/favourite_location_state.dart';
import '../widgets/location_tile.dart';

/// Favourite Location page (passenger only) — 100% StatelessWidget + BLoC.
///
/// Shows Home, Work, and starred favourite locations.
/// All data and actions go through [FavouriteLocationBloc].
/// Zero hardcoded strings/colors.
class FavouriteLocationPage extends StatelessWidget {
  const FavouriteLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IqAppBar(title: AppStrings.favouriteLocation),
      body: BlocBuilder<FavouriteLocationBloc, FavouriteLocationState>(
        builder: (context, state) {
          if (state is FavouriteLocationLoading ||
              state is FavouriteLocationInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is FavouriteLocationError) {
            return Center(
              child: IqText(
                state.message,
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.error),
              ),
            );
          }

          if (state is! FavouriteLocationLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 16.h),
            child: Column(
              children: [
                // ── Home locations ──
                ...state.homeLocations.map(
                  (loc) => LocationTile.fromModel(
                    model: loc,
                    icon: Icons.home_outlined,
                    title: AppStrings.home,
                    onDelete: () => context
                        .read<FavouriteLocationBloc>()
                        .add(FavouriteLocationDeleteRequested(loc.id)),
                  ),
                ),
                if (state.homeLocations.isEmpty)
                  LocationTile(
                    icon: Icons.home_outlined,
                    title: AppStrings.home,
                    address: AppStrings.locationNotSet,
                    showDelete: false,
                  ),

                // ── Work locations ──
                ...state.workLocations.map(
                  (loc) => LocationTile.fromModel(
                    model: loc,
                    icon: Icons.work_outline,
                    title: AppStrings.work,
                    onDelete: () => context
                        .read<FavouriteLocationBloc>()
                        .add(FavouriteLocationDeleteRequested(loc.id)),
                  ),
                ),
                if (state.workLocations.isEmpty)
                  LocationTile(
                    icon: Icons.work_outline,
                    title: AppStrings.work,
                    address: AppStrings.locationNotSet,
                    showDelete: false,
                  ),

                // ── Other (starred) locations ──
                ...state.otherLocations.map(
                  (loc) => LocationTile.fromModel(
                    model: loc,
                    icon: Icons.star,
                    iconColor: AppColors.starFilled,
                    title: loc.address.split(',').first,
                    onDelete: () => context
                        .read<FavouriteLocationBloc>()
                        .add(FavouriteLocationDeleteRequested(loc.id)),
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Add more button ──
                GestureDetector(
                  onTap: () {
                    // TODO: navigate to add favourite location
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IqText(
                        AppStrings.addMorePlaces,
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.textMuted),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.buttonYellow,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: IqText(
                            '+',
                            style: AppTypography.heading1.copyWith(
                              color: AppColors.buttonYellow,
                              fontFamily: AppTypography.fontFamilyLatin,
                            ),
                            dir: TextDirection.ltr,
                          ),
                        ),
                      ),
                    ],
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
