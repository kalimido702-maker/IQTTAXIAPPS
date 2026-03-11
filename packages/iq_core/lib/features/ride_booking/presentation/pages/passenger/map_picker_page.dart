import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_app_bar.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../location/domain/repositories/location_repository.dart';

class MapPickResult {
  const MapPickResult({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;
}

/// Full-screen map picker used by "اختر من الخريطة".
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  final double initialLat;
  final double initialLng;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _mapKey = GlobalKey<IqMapViewState>();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  late LatLng _target;
  bool _isResolving = false;
  String _currentAddress = '';
  bool _isAddressLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _target = LatLng(widget.initialLat, widget.initialLng);
    _resolveAddress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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

  void _onSearchPlaceSelected(Map<String, dynamic> place) {
    final lat = (place['lat'] as num?)?.toDouble() ?? 0;
    final lng = (place['lng'] as num?)?.toDouble() ?? 0;
    final address = place['address'] as String? ?? place['name'] as String? ?? '';
    if (lat == 0 || lng == 0) return;

    setState(() {
      _target = LatLng(lat, lng);
      _currentAddress = address;
      _isAddressLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocus.unfocus();
    _mapKey.currentState?.animateTo(LatLng(lat, lng), zoom: 16);
  }

  /// Resolve the address for the current [_target] position.
  Future<void> _resolveAddress() async {
    setState(() => _isAddressLoading = true);

    final repo = sl<LocationRepository>();
    final result = await repo.getAddressFromCoordinates(
      latitude: _target.latitude,
      longitude: _target.longitude,
    );

    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isAddressLoading = false),
      (address) => setState(() {
        _currentAddress = address;
        _isAddressLoading = false;
      }),
    );
  }

  Future<void> _confirm() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    // If we already have the address resolved, use it directly.
    if (_currentAddress.isNotEmpty && !_isAddressLoading) {
      Navigator.of(context).pop(
        MapPickResult(
          address: _currentAddress,
          lat: _target.latitude,
          lng: _target.longitude,
        ),
      );
      return;
    }

    final repo = sl<LocationRepository>();
    final result = await repo.getAddressFromCoordinates(
      latitude: _target.latitude,
      longitude: _target.longitude,
    );

    if (!mounted) return;
    result.fold(
      (_) {
        setState(() => _isResolving = false);
      },
      (address) {
        Navigator.of(context).pop(
          MapPickResult(
            address: address,
            lat: _target.latitude,
            lng: _target.longitude,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: IqAppBar(title: AppStrings.selectLocation),
      body: Stack(
        children: [
          Positioned.fill(
            child: IqMapView(
              key: _mapKey,
              initialTarget: _target,
              myLocationButtonEnabled: false,
              onCameraMove: (pos) => _target = pos.target,
              onCameraIdle: _resolveAddress,
            ),
          ),
          // Search bar at top
          Positioned(
            top: 12.h,
            left: AppDimens.screenPaddingH,
            right: AppDimens.screenPaddingH,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16.w),
                      Icon(Icons.search, size: 22.w, color: AppColors.textMuted),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          style: AppTypography.bodyMedium,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchPlaceholder,
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grayPlaceholder,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Icon(Icons.close, size: 20.w, color: AppColors.textMuted),
                          ),
                        )
                      else
                        SizedBox(width: 16.w),
                    ],
                  ),
                ),
                // Search results dropdown
                if (_isSearching)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    constraints: BoxConstraints(maxHeight: 250.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on_outlined,
                            size: 20.w,
                            color: AppColors.textMuted,
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
                            _onSearchPlaceSelected(place);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Center pin
          Center(
            child: Icon(
              Icons.location_pin,
              color: AppColors.markerRed,
              size: 44.w,
            ),
          ),
          // Bottom section: address + button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.screenPaddingH,
                    16.h,
                    AppDimens.screenPaddingH,
                    12.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Address row
                      Row(
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 18.w,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _isAddressLoading
                                ? IqText(
                                    AppStrings.resolvingLocation,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                  )
                                : IqText(
                                    _currentAddress.isNotEmpty
                                        ? _currentAddress
                                        : AppStrings.unknownLocation,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 2,
                                  ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      // Confirm button
                      IqPrimaryButton(
                        text: _isResolving
                            ? AppStrings.resolvingLocation
                            : AppStrings.confirmLocation,
                        onPressed: _isResolving ? null : _confirm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
