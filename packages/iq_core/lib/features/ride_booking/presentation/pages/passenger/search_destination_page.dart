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
  final _pickupFocus = FocusNode();
  final _dropFocus = FocusNode();
  Timer? _debounce;

  /// Controllers and focus nodes for intermediate stops (max 2).
  final List<TextEditingController> _stopControllers = [];
  final List<FocusNode> _stopFocusNodes = [];

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentPlaces = [];
  bool _isSearching = false;
  bool _isLoadingRecents = false;

  /// Tracks which field is active: -1 = pickup, 0..N = stop index, 99 = dropoff.
  int _activeField = 99;

  /// Intermediate stops data. Each: {lat, lng, address}.
  final List<Map<String, dynamic>> _stops = [];

  /// Mutable pickup coordinates — updated when the user picks a new location.
  late double _pickupLat = widget.pickupLat;
  late double _pickupLng = widget.pickupLng;
  late String _pickupAddress = widget.pickupAddress;

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.pickupAddress;
    _loadRecentPlaces();

    // Track which field is focused.
    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus) setState(() => _activeField = -1);
    });
    _dropFocus.addListener(() {
      if (_dropFocus.hasFocus) setState(() => _activeField = 99);
    });

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
    _pickupFocus.dispose();
    _dropFocus.dispose();
    for (final c in _stopControllers) {
      c.dispose();
    }
    for (final f in _stopFocusNodes) {
      f.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _addStopField() {
    if (_stops.length >= 2) return;
    final index = _stops.length;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) setState(() => _activeField = index);
    });
    _stopControllers.add(controller);
    _stopFocusNodes.add(focusNode);
    _stops.add({});
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void _removeStop(int index) {
    if (index < 0 || index >= _stops.length) return;
    _stopControllers[index].dispose();
    _stopFocusNodes[index].dispose();
    _stopControllers.removeAt(index);
    _stopFocusNodes.removeAt(index);
    _stops.removeAt(index);
    // Re-wire focus listeners with correct indices.
    for (var i = 0; i < _stopFocusNodes.length; i++) {
      final fn = _stopFocusNodes[i];
      fn.removeListener(() {});
      final idx = i;
      fn.addListener(() {
        if (fn.hasFocus) setState(() => _activeField = idx);
      });
    }
    setState(() {
      if (_activeField >= _stops.length && _activeField != 99 && _activeField != -1) {
        _activeField = 99;
      }
    });
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
      debugPrint('🔍 [SearchDest] searching for: "${query.trim()}"');
      final repo = sl<LocationRepository>();
      final result = await repo.searchPlaces(query.trim());
      if (!mounted) return;
      result.fold(
        (failure) {
          debugPrint('🔍 [SearchDest] search failed: ${failure.message}');
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        },
        (places) {
          debugPrint('🔍 [SearchDest] search returned ${places.length} results');
          setState(() {
            _searchResults = places;
            _isSearching = false;
          });
        },
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

    // Editing pickup
    if (_activeField == -1) {
      setState(() {
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupAddress = address;
        _pickupController.text = address;
        _searchResults = [];
      });
      _dropFocus.requestFocus();
      return;
    }

    // Editing an intermediate stop
    if (_activeField >= 0 && _activeField < _stops.length) {
      final idx = _activeField;
      setState(() {
        _stops[idx] = {
          'order': idx + 1,
          'lat': lat,
          'lng': lng,
          'address': address,
        };
        _stopControllers[idx].text = address;
        _searchResults = [];
      });
      // Move focus to next empty field or dropoff.
      if (idx + 1 < _stops.length && _stops[idx + 1].isEmpty) {
        _stopFocusNodes[idx + 1].requestFocus();
      } else {
        _dropFocus.requestFocus();
      }
      return;
    }

    // Editing dropoff — navigate to ride selection
    FocusScope.of(context).unfocus();

    // Build stops list with only completed entries.
    final validStops = <Map<String, dynamic>>[];
    for (var i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      if (s.containsKey('lat') && s.containsKey('lng')) {
        validStops.add({
          'order': validStops.length + 1,
          'lat': s['lat'],
          'lng': s['lng'],
          'address': s['address'] ?? '',
        });
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSelectionPage(
          pickupAddress: _pickupAddress,
          pickupLat: _pickupLat,
          pickupLng: _pickupLng,
          dropoffAddress: address,
          dropoffLat: lat,
          dropoffLng: lng,
          stops: validStops,
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
          initialLat: _pickupLat,
          initialLng: _pickupLng,
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
      appBar: IqAppBar(title: AppStrings.toWhere),
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
                // Pickup field (editable — search for a new pickup)
                _AddressField(
                  controller: _pickupController,
                  hint: AppStrings.pickupLocationHint,
                  iconPath: AppAssets.icLocation,
                  focusNode: _pickupFocus,
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 12.h),
                // Intermediate stop fields
                for (var i = 0; i < _stops.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _AddressField(
                          controller: _stopControllers[i],
                          hint: '${AppStrings.stopHint} ${i + 1}',
                          iconPath: AppAssets.icLocation,
                          focusNode: _stopFocusNodes[i],
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () => _removeStop(i),
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18.w,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                // Dropoff field
                _AddressField(
                  controller: _dropController,
                  hint: AppStrings.whereToGo,
                  iconPath: AppAssets.searchIcon,
                  focusNode: _dropFocus,
                  onChanged: _onSearchChanged,
                ),
                // "Add stop" button (max 2)
                if (_stops.length < 2) ...[
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: _addStopField,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IqText(
                          AppStrings.addStop,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.add_circle_outline,
                          size: 18.w,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
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
              onChanged: onChanged,
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
