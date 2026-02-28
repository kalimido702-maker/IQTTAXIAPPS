import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iq_core/core/core.dart';
import '../../../../location/domain/repositories/location_repository.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import 'map_picker_page.dart';
import 'ride_selection_page.dart';

/// Search destination page (Figma 7:827).
/// Pickup + dropoff fields, recent places, favourites.
class SearchDestinationPage extends StatelessWidget {
  const SearchDestinationPage({
    super.key,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    this.quickPlaces = const [],
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final List<Map<String, dynamic>> quickPlaces;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<PassengerTripBloc>(),
      child: _Body(
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        quickPlaces: quickPlaces,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.quickPlaces,
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final List<Map<String, dynamic>> quickPlaces;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _searchController = TextEditingController();
  final _dropFocus = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentPlaces = [];
  bool _isSearching = false;
  bool _isLoadingRecents = false;

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.pickupAddress;
    _loadRecentPlaces();
    // Auto-focus dropoff field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _searchController.dispose();
    _dropFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final repo = sl<LocationRepository>();
      final result = await repo.searchPlaces(query.trim());
      if (!mounted) return;
      result.fold(
        (_) => setState(() {
          _searchResults = [];
          _isSearching = false;
        }),
        (places) => setState(() {
          _searchResults = places;
          _isSearching = false;
        }),
      );
    });
  }

  Future<void> _loadRecentPlaces() async {
    setState(() => _isLoadingRecents = true);
    final repo = sl<BookingRepository>();
    final result = await repo.getRecentSearches();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoadingRecents = false),
      (list) {
        final places = list.map((item) {
          final dropLat = (item['drop_lat'] as num?)?.toDouble() ?? 0.0;
          final dropLng = (item['drop_lng'] as num?)?.toDouble() ?? 0.0;
          final pickLat = (item['pick_lat'] as num?)?.toDouble() ?? 0.0;
          final pickLng = (item['pick_lng'] as num?)?.toDouble() ?? 0.0;
          final useDrop = dropLat != 0 && dropLng != 0;
          final address = (useDrop
                  ? item['drop_address']
                  : item['pick_address'])
              ?.toString();
          final name = (address ?? '').split(',').first.trim();
          return {
            'name': name.isNotEmpty ? name : (address ?? ''),
            'address': address ?? '',
            'lat': useDrop ? dropLat : pickLat,
            'lng': useDrop ? dropLng : pickLng,
          };
        }).where((p) => (p['lat'] as double? ?? 0) != 0).toList();

        setState(() {
          _recentPlaces = places;
          _isLoadingRecents = false;
        });
      },
    );
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    final name = place['name'] as String? ?? '';
    final address = place['address'] as String? ?? name;
    final lat = (place['lat'] as num?)?.toDouble() ?? 0;
    final lng = (place['lng'] as num?)?.toDouble() ?? 0;

    if (lat == 0 || lng == 0) return;

    // Unfocus text fields to prevent SystemContextMenu crash
    FocusScope.of(context).unfocus();

    // Navigate to ride selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSelectionPage(
          pickupAddress: widget.pickupAddress,
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          dropoffAddress: address,
          dropoffLat: lat,
          dropoffLng: lng,
        ),
      ),
    );
  }

  Future<void> _pickFromMap() async {
    // Unfocus text fields to prevent SystemContextMenu crash
    FocusScope.of(context).unfocus();

    final result = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: widget.pickupLat,
          initialLng: widget.pickupLng,
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Update the dropoff field text so the user sees the selected address
    setState(() {
      _dropController.text = result.address;
    });

    _onPlaceSelected({
      'name': result.address,
      'address': result.address,
      'lat': result.lat,
      'lng': result.lng,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const IqAppBar(title: AppStrings.toWhere),
      body: Column(
        children: [
          // ── Address fields ──
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.paddingLG,
              vertical: AppDimens.paddingMD,
            ),
            child: Column(
              children: [
                // Pickup field
                _AddressField(
                  controller: _pickupController,
                  hint: AppStrings.pickupLocationHint,
                  iconPath: AppAssets.icLocation,
                  readOnly: true,
                ),
                SizedBox(height: 12.h),
                // Dropoff field
                _AddressField(
                  controller: _dropController,
                  hint: AppStrings.whereToGo,
                  iconPath: AppAssets.searchIcon,
                  focusNode: _dropFocus,
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),

          // ── Search results / recent places ──
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _searchResults.isNotEmpty
                    ? _SearchResultsList(
                        results: _searchResults,
                        onSelected: _onPlaceSelected,
                      )
                    : _QuickPlaces(
                        isLoading: _isLoadingRecents,
                        recentPlaces: _recentPlaces,
                        savedPlaces: widget.quickPlaces,
                        onPlaceSelected: _onPlaceSelected,
                        onPickFromMap: _pickFromMap,
                      ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.hint,
    required this.iconPath,
    this.focusNode,
    this.readOnly = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.black.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 16.w),
          SizedBox(width: 10.w),
          IqImage(
            iconPath,
            width: 20.w,
            height: 20.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              onChanged: onChanged,
              contextMenuBuilder: readOnly
                  ? (context, editableTextState) =>
                      const SizedBox.shrink()
                  : null,
              enableInteractiveSelection: !readOnly,
              style: AppTypography.bodyMedium,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.grayPlaceholder,
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                fillColor: AppColors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> results;
  final ValueChanged<Map<String, dynamic>> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLG,
        vertical: AppDimens.paddingMD,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final place = results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              color: AppColors.grayLightBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 20.w,
              color: AppColors.textMuted,
            ),
          ),
          title: IqText(
            place['name'] as String? ?? '',
            style: AppTypography.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: IqText(
            place['address'] as String? ?? '',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(place);
          },
        );
      },
    );
  }
}

class _QuickPlaces extends StatelessWidget {
  const _QuickPlaces({
    required this.onPlaceSelected,
    required this.onPickFromMap,
    required this.recentPlaces,
    required this.savedPlaces,
    this.isLoading = false,
  });
  final ValueChanged<Map<String, dynamic>> onPlaceSelected;
  final VoidCallback onPickFromMap;
  final List<Map<String, dynamic>> recentPlaces;
  final List<Map<String, dynamic>> savedPlaces;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLG,
        vertical: AppDimens.paddingMD,
      ),
      children: [
        // Recent places
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        if (!isLoading && recentPlaces.isNotEmpty) ...[
          IqText(
            AppStrings.recentPlaces,
            style: AppTypography.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...recentPlaces.map((place) {
            return Column(
              children: [
                _QuickPlaceTile(
                  icon: Icons.history,
                  title: place['name'] as String? ?? '',
                  subtitle: place['address'] as String? ?? '',
                  onTap: () => onPlaceSelected(place),
                ),
                const Divider(height: 1),
              ],
            );
          }),
          SizedBox(height: 16.h),
        ],

        // Saved places (favourites)
        if (savedPlaces.isNotEmpty) ...[
          IqText(
            AppStrings.savedPlaces,
            style: AppTypography.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...savedPlaces.map((place) {
            return Column(
              children: [
                _QuickPlaceTile(
                  icon: Icons.star_border,
                  title: place['name'] as String? ?? '',
                  subtitle: place['address'] as String? ?? '',
                  onTap: () => onPlaceSelected(place),
                ),
                const Divider(height: 1),
              ],
            );
          }),
          SizedBox(height: 16.h),
        ],

        // Choose from map
        _QuickPlaceTile(
          icon: Icons.map_outlined,
          title: AppStrings.chooseFromMap,
          subtitle: AppStrings.selectDestinationFromMap,
          onTap: onPickFromMap,
        ),
      ],
    );
  }
}

class _QuickPlaceTile extends StatelessWidget {
  const _QuickPlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkInputBg
              : AppColors.grayLightBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22.w, color: onSurface),
      ),
      title: IqText(
        title,
        style: AppTypography.labelMedium.copyWith(color: onSurface),
      ),
      subtitle: IqText(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}
