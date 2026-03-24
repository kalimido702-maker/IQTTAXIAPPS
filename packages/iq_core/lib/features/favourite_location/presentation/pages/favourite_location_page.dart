import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../ride_booking/presentation/pages/passenger/map_picker_page.dart';
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
      appBar: IqAppBar(title: AppStrings.favouriteLocation),
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
                    onDelete: () => _confirmDelete(context, loc.id),
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
                    onDelete: () => _confirmDelete(context, loc.id),
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
                    title: loc.addressName.isNotEmpty
                        ? loc.addressName
                        : loc.address.split(',').first,
                    onDelete: () => _confirmDelete(context, loc.id),
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Add more button ──
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); _addFavouriteLocation(context); },
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

  // ── Confirm delete dialog ──
  void _confirmDelete(BuildContext context, int locationId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        title: IqText(
          AppStrings.deleteFavouriteConfirm,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(dialogCtx).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: IqText(
              AppStrings.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<FavouriteLocationBloc>().add(
                    FavouriteLocationDeleteRequested(locationId),
                  );
            },
            child: IqText(
              AppStrings.delete,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add favourite location flow ──
  Future<void> _addFavouriteLocation(BuildContext context) async {
    // 1. Get current location for map initial position
    final locRepo = sl<LocationRepository>();
    final locResult = await locRepo.getCurrentLocation();
    double initLat = 0;
    double initLng = 0;
    locResult.fold((_) {}, (coords) {
      initLat = coords.$1;
      initLng = coords.$2;
    });

    if (!context.mounted) return;

    // 2. Navigate to map picker
    final result = await Navigator.of(context).push<MapPickResult>(
      MaterialPageRoute<MapPickResult>(
        builder: (_) => MapPickerPage(
          initialLat: initLat,
          initialLng: initLng,
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    // 3. Show name dialog
    final addressName = await _showAddressNameDialog(context);
    if (addressName == null || addressName.isEmpty || !context.mounted) return;

    // 4. Add via BLoC
    context.read<FavouriteLocationBloc>().add(
          FavouriteLocationAddRequested(
            lat: result.lat,
            lng: result.lng,
            address: result.address,
            addressName: addressName,
          ),
        );
  }

  Future<String?> _showAddressNameDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        title: IqText(
          AppStrings.enterAddressName,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(dialogCtx).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(dialogCtx).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.addressNameHint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: IqText(
              AppStrings.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx, name);
            },
            child: IqText(
              AppStrings.add,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
