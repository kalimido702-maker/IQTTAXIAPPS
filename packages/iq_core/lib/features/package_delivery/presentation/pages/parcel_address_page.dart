import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../favourite_location/domain/repositories/favourite_location_repository.dart';
import '../../../home/data/models/home_data_model.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../ride_booking/presentation/pages/passenger/map_picker_page.dart';
import '../bloc/package_delivery_bloc.dart';
import '../bloc/package_delivery_event.dart';
import '../bloc/package_delivery_state.dart';

/// Address selection for parcel delivery — Figma node 7:4013.
class ParcelAddressPage extends StatefulWidget {
  const ParcelAddressPage({
    super.key,
    this.initialPickupAddress,
    this.initialPickupLat,
    this.initialPickupLng,
    required this.onAddressesConfirmed,
  });

  final String? initialPickupAddress;
  final double? initialPickupLat;
  final double? initialPickupLng;
  final VoidCallback onAddressesConfirmed;

  @override
  State<ParcelAddressPage> createState() => _ParcelAddressPageState();
}

class _ParcelAddressPageState extends State<ParcelAddressPage> {
  String _pickupAddress = '';
  double _pickupLat = 0;
  double _pickupLng = 0;

  String _dropAddress = '';
  double _dropLat = 0;
  double _dropLng = 0;

  // Search
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingPickup = true;
  bool _showSearch = false;
  Timer? _debounce;

  // Favourite locations from backend
  FavouriteLocationModel? _homeLocation;
  FavouriteLocationModel? _workLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialPickupAddress != null) {
      _pickupAddress = widget.initialPickupAddress!;
      _pickupLat = widget.initialPickupLat ?? 0;
      _pickupLng = widget.initialPickupLng ?? 0;
    }
    _loadFavouriteLocations();
  }

  Future<void> _loadFavouriteLocations() async {
    try {
      final result =
          await sl<FavouriteLocationRepository>().listFavouriteLocations();
      if (!mounted) return;
      result.fold(
        (_) {},
        (locations) {
          FavouriteLocationModel? home;
          FavouriteLocationModel? work;
          for (final loc in locations) {
            final name = loc.addressName.toLowerCase().trim();
            if (name == 'home' && home == null) home = loc;
            if (name == 'work' && work == null) work = loc;
          }
          setState(() {
            _homeLocation = home;
            _workLocation = work;
          });
        },
      );
    } catch (_) {
      // Silently fail — tiles will show "location not set"
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
      listenWhen: (prev, curr) =>
          curr.status == PackageDeliveryStatus.selectingMode,
      listener: (_, __) => widget.onAddressesConfirmed(),
      child: Scaffold(
        appBar: IqAppBar(title: AppStrings.sendReceivePackage),
        body: Column(
          children: [
            // ── Address fields ──
            _buildAddressFields(),

            // ── Divider ──
            Divider(height: 1, color: AppColors.grayInactive.withValues(alpha: 0.5)),

            // ── Content below ──
            Expanded(
              child: _showSearch
                  ? _buildSearchResults()
                  : _buildDefaultContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Address fields — matching Figma (location pin icons, pill borders)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAddressFields() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Column(
        children: [
          // ── Pickup ──
          _buildAddressField(
            icon: Icons.location_on,
            iconColor: const Color(0xFF34A853),
            label: AppStrings.pickupAddress,
            address: _pickupAddress,
            onTap: () => _startSearch(isPickup: true),
          ),

          SizedBox(height: 10.h),

          // ── Drop-off ──
          _buildAddressField(
            icon: Icons.location_on,
            iconColor: const Color(0xFFEA4335),
            label: AppStrings.deliveryAddress,
            address: _dropAddress,
            onTap: () => _startSearch(isPickup: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(1000.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grayInactive.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22.w),
            SizedBox(width: 12.w),
            Expanded(
              child: IqText(
                address.isEmpty ? label : address,
                style: AppTypography.bodyLarge.copyWith(
                  color: address.isEmpty ? AppColors.black : null,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Default content: quick places + search field + map button
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "أماكن سريعة" header (only if at least one saved) ──
          if (_homeLocation != null || _workLocation != null) ...[
            IqText(
              AppStrings.quickPlaces,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12.h),
          ],

          // ── Home (only if saved) ──
          if (_homeLocation != null) ...[
            _QuickPlaceTile(
              icon: Icons.home_rounded,
              title: AppStrings.home,
              subtitle: _homeLocation!.address,
              onTap: () => _onFavouriteTapped(_homeLocation),
            ),
            if (_workLocation != null)
              Divider(height: 1, color: AppColors.grayInactive.withValues(alpha: 0.4)),
          ],

          // ── Work (only if saved) ──
          if (_workLocation != null)
            _QuickPlaceTile(
              icon: Icons.work_rounded,
              title: AppStrings.work,
              subtitle: _workLocation!.address,
              onTap: () => _onFavouriteTapped(_workLocation),
            ),

          SizedBox(height: 20.h),

          // ── Search field (always visible) ──
          InkWell(
            onTap: () {
              // Open search for whichever field is empty, default to pickup
              _startSearch(isPickup: _pickupAddress.isEmpty);
            },
            borderRadius: BorderRadius.circular(1000.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.grayInactive.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(1000.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 22.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: IqText(
                      AppStrings.searchPlaceholder,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.grayInactive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // ── Choose from map ──
          IqPrimaryButton(
            text: AppStrings.chooseFromMap,
            onPressed: () => _pickFromMap(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Search overlay
  // ═══════════════════════════════════════════════════════════════════

  void _startSearch({required bool isPickup}) {
    setState(() {
      _isSearchingPickup = isPickup;
      _showSearch = true;
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocus.requestFocus();
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // ── Search text field ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: AppStrings.searchPlaceholder,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.grayInactive,
              ),
              prefixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _showSearch = false;
                  _searchController.clear();
                }),
              ),
              suffixIcon: Icon(
                Icons.search,
                color: AppColors.grayInactive,
                size: 22.w,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1000.r),
                borderSide: BorderSide(color: AppColors.grayInactive.withValues(alpha: 0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1000.r),
                borderSide: BorderSide(color: AppColors.grayInactive.withValues(alpha: 0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1000.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // ── Results list ──
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: IqText(
                    'ابحث عن مكان...',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.grayInactive),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.grayInactive.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.grayInactive,
                        size: 24.w,
                      ),
                      title: IqText(
                        place['name']?.toString() ?? '',
                        style: AppTypography.bodyLarge,
                        maxLines: 1,
                      ),
                      subtitle: IqText(
                        place['address']?.toString() ?? '',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grayInactive,
                        ),
                        maxLines: 1,
                      ),
                      onTap: () => _onPlaceSelected(place),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _onSearchChanged(String query) async {
    _debounce?.cancel();
    debugPrint('🔍 [ParcelAddress] _onSearchChanged query="$query"');
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await sl<LocationRepository>().searchPlaces(query);
        if (mounted && _searchController.text == query) {
          result.fold(
            (failure) {
              debugPrint('🔍 [ParcelAddress] search failed: ${failure.message}');
              setState(() => _searchResults = []);
            },
            (places) {
              debugPrint('🔍 [ParcelAddress] search returned ${places.length} results');
              setState(() => _searchResults = places);
            },
          );
        }
      } catch (e) {
        debugPrint('🔍 [ParcelAddress] search exception: $e');
      }
    });
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    final lat = (place['lat'] as num?)?.toDouble() ?? 0;
    final lng = (place['lng'] as num?)?.toDouble() ?? 0;
    final address =
        place['address']?.toString() ?? place['name']?.toString() ?? '';

    setState(() {
      _showSearch = false;
      _searchController.clear();
      if (_isSearchingPickup) {
        _pickupAddress = address;
        _pickupLat = lat;
        _pickupLng = lng;
      } else {
        _dropAddress = address;
        _dropLat = lat;
        _dropLng = lng;
      }
    });

    _tryConfirm();
  }

  // ═══════════════════════════════════════════════════════════════════
  // Map picker
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pickFromMap() async {
    final lat = _isSearchingPickup || _pickupLat == 0
        ? (_pickupLat != 0 ? _pickupLat : 33.3152)
        : (_dropLat != 0 ? _dropLat : 33.3152);
    final lng = _isSearchingPickup || _pickupLng == 0
        ? (_pickupLng != 0 ? _pickupLng : 44.3661)
        : (_dropLng != 0 ? _dropLng : 44.3661);

    final result = await Navigator.of(context).push<MapPickResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialLat: lat, initialLng: lng),
      ),
    );

    if (result != null && mounted) {
      final fillPickup = _pickupAddress.isEmpty;
      setState(() {
        if (fillPickup) {
          _pickupAddress = result.address;
          _pickupLat = result.lat;
          _pickupLng = result.lng;
        } else {
          _dropAddress = result.address;
          _dropLat = result.lat;
          _dropLng = result.lng;
        }
      });
      _tryConfirm();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Favourite place tapped → fill the next empty address field
  // ═══════════════════════════════════════════════════════════════════

  void _onFavouriteTapped(FavouriteLocationModel? loc) {
    if (loc == null) return;
    setState(() {
      if (_pickupAddress.isEmpty) {
        _pickupAddress = loc.address;
        _pickupLat = loc.lat;
        _pickupLng = loc.lng;
      } else {
        _dropAddress = loc.address;
        _dropLat = loc.lat;
        _dropLng = loc.lng;
      }
    });
    _tryConfirm();
  }

  // ═══════════════════════════════════════════════════════════════════
  // Auto-confirm when both addresses are set
  // ═══════════════════════════════════════════════════════════════════

  void _tryConfirm() {
    if (_pickupAddress.isNotEmpty &&
        _dropAddress.isNotEmpty &&
        _pickupLat != 0 &&
        _dropLat != 0) {
      context.read<PackageDeliveryBloc>().add(
            PackageDeliveryAddressesConfirmed(
              pickLat: _pickupLat,
              pickLng: _pickupLng,
              dropLat: _dropLat,
              dropLng: _dropLng,
              pickAddress: _pickupAddress,
              dropAddress: _dropAddress,
            ),
          );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick place tile — matches Figma (icon + title + subtitle + star)
// ═══════════════════════════════════════════════════════════════════

class _QuickPlaceTile extends StatelessWidget {
  const _QuickPlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            // ── Favorite star ──
            Icon(
              Icons.star_border_rounded,
              size: 24.w,
              color: AppColors.grayInactive,
            ),

            const Spacer(),

            // ── Title + subtitle ──
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IqText(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  IqText(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grayInactive,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // ── Icon container ──
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.grayInactive.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 22.w, color: AppColors.gray3),
            ),
          ],
        ),
      ),
    );
  }
}
