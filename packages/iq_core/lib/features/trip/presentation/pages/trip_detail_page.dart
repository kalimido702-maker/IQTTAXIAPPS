import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iq_core/core/theme/app_dimens.dart';
import 'package:iq_core/core/utils/utils.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../domain/entities/trip_entity.dart';

/// تفاصيل الرحلة — Trip Detail page.
///
/// Displays: map preview, driver info, trip info card,
/// addresses, fare breakdown, and rating.
///
/// Shared between passenger & driver apps.
/// 100% StatelessWidget — receives [TripEntity] from caller.
class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const IqAppBar(title: AppStrings.tripDetailsTitle),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),

            // ── Map Preview ──
            _MapPreview(trip: trip),
            SizedBox(height: 16.h),

            // ── Driver Info Section ──
            _DriverInfoSection(trip: trip, isDark: isDark),
            SizedBox(height: 20.h),

            // ── Trip Info Card ──
            _TripInfoCard(trip: trip, isDark: isDark),
            SizedBox(height: 16.h),

            // ── Address Pills ──
            _AddressPill(
              address: trip.pickupAddress,
              markerColor: AppColors.markerRed,
            ),
            SizedBox(height: 8.h),
            _AddressPill(
              address: trip.dropoffAddress,
              markerColor: AppColors.markerBlue,
            ),
            SizedBox(height: 20.h),

            // ── Fare Breakdown Section ──
            _FareBreakdownSection(trip: trip, isDark: isDark),
            SizedBox(height: 20.h),

            // ── Rating Section ──
            _RatingSection(trip: trip),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

// ── Map Preview ───────────────────────────────────────────────

class _MapPreview extends StatefulWidget {
  const _MapPreview({required this.trip});

  final TripEntity trip;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  Set<Marker> _markers = {};
  bool _iconsReady = false;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
  }

  Future<void> _createCustomMarkers() async {
    final pickupIcon = await _drawCircleMarker(
      innerColor: AppColors.error,
      outerColor: AppColors.error.withValues(alpha: 0.25),
    );
    final dropoffIcon = await _drawCircleMarker(
      innerColor: AppColors.circleBlue,
      outerColor: AppColors.circleBlue.withValues(alpha: 0.25),
    );

    if (!mounted) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.trip.pickupLat, widget.trip.pickupLng),
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.5),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.trip.dropoffLat, widget.trip.dropoffLng),
          icon: dropoffIcon,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      _iconsReady = true;
    });
  }

  /// Draws a circular marker: a solid inner circle + a semi-transparent outer ring.
  /// Matches the Figma design exactly.
  static Future<BitmapDescriptor> _drawCircleMarker({
    required Color innerColor,
    required Color outerColor,
    double outerRadius = 15,
    double innerRadius = 4,
  }) async {
    final size = outerRadius * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(outerRadius, outerRadius);

    // Outer translucent circle
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()..color = outerColor,
    );

    // Inner solid circle
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = innerColor,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickup = LatLng(trip.pickupLat, trip.pickupLng);
    final dropoff = LatLng(trip.dropoffLat, trip.dropoffLng);

    // Decode the encoded polyline from the backend if available
    final polylinePoints = trip.polyLine != null && trip.polyLine!.isNotEmpty
        ? _decodePolyline(trip.polyLine!)
        : <LatLng>[pickup, dropoff];

    // Calculate bounds to fit the route
    final bounds = _calculateBounds(polylinePoints);

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: AppColors.gray3, // dark gray matching Figma
        width: 4,
      ),
    };

    return Container(
      height: 206.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grayDivider,
        borderRadius: BorderRadius.circular(10.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: _iconsReady
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (pickup.latitude + dropoff.latitude) / 2,
                  (pickup.longitude + dropoff.longitude) / 2,
                ),
                zoom: 5,
              ),
              markers: _markers,
              polylines: polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                // Fit the camera to show the full route with padding
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 50),
                  );
                });
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: false,
              indoorViewEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              liteModeEnabled: true,
              minMaxZoomPreference: const MinMaxZoomPreference(5.0, 18.0),
            )
          : Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
    );
  }

  /// Decode a Google-encoded polyline string into a list of [LatLng].
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Calculate [LatLngBounds] that contain all the given [points].
  static LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

// ── Driver Info Section ───────────────────────────────────────

class _DriverInfoSection extends StatelessWidget {
  const _DriverInfoSection({required this.trip, required this.isDark});

  final TripEntity trip;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final driver = trip.driverInfo;
    if (driver == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row: "بيانات السائق" <-> Vehicle type
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IqText(
              AppStrings.driverData,
              style: AppTypography.heading3,
            ),
            _VehicleTypeChip(trip: trip),
          ],
        ),
        SizedBox(height: 12.h),

        // Driver details row
        Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 27.5.w,
              backgroundColor: AppColors.gray1,
              backgroundImage: driver.profilePicture != null
                  ? NetworkImage(driver.profilePicture!)
                  : null,
              child: driver.profilePicture == null
                  ? Icon(Icons.person, size: 28.w, color: AppColors.white)
                  : null,
            ),
            SizedBox(width: 12.w),

            // Name + rating + car info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    children: [
                      Flexible(
                        child: IqText(
                          driver.name,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.star_rounded,
                          color: AppColors.starFilled, size: 16.w),
                      SizedBox(width: 2.w),
                      IqText(
                        driver.rating.toStringAsFixed(1),
                        style: AppTypography.numberSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // Car make + number + color
                  Row(
                    children: [
                      if (driver.carMakeName != null) ...[
                        IqText(
                          driver.carMakeName!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSubtitle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (driver.carNumber != null) ...[
                        IqText(
                          driver.carNumber!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSubtitle,
                            fontFamily: AppTypography.fontFamilyLatin,
                            fontWeight: FontWeight.w600,
                          ),
                          
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (driver.carColor != null) ...[
                        IqText(
                          '${AppStrings.color} :',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSubtitle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: BoxDecoration(
                            color: _parseColor(driver.carColor!),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: AppColors.grayBorder,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Order number badge
        if (trip.requestNumber != null) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              IqText(
                AppStrings.orderNumber,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSubtitle,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.statusCompletedBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IqText(
                  trip.requestNumber!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.statusCompletedText,
                    fontFamily: AppTypography.fontFamilyLatin,
                    fontSize: 11.sp,
                  ),
                  
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Try to parse a color name or hex string.
  Color _parseColor(String colorStr) {
    final lower = colorStr.toLowerCase().trim();
    const colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'white': Colors.white,
      'black': Colors.black,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'silver': Color(0xFFC0C0C0),
      'brown': Colors.brown,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'أحمر': Colors.red,
      'أزرق': Colors.blue,
      'أخضر': Colors.green,
      'أبيض': Colors.white,
      'أسود': Colors.black,
      'أصفر': Colors.yellow,
      'برتقالي': Colors.orange,
      'رمادي': Colors.grey,
      'فضي': Color(0xFFC0C0C0),
      'بني': Colors.brown,
    };
    if (colorMap.containsKey(lower)) return colorMap[lower]!;
    // Try hex
    if (lower.startsWith('#') && lower.length >= 7) {
      final hex = lower.replaceFirst('#', '');
      final parsed = int.tryParse('FF$hex', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Colors.grey;
  }
}

// ── Vehicle Type Chip ─────────────────────────────────────────

class _VehicleTypeChip extends StatelessWidget {
  const _VehicleTypeChip({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final isTaxi = trip.isTaxi;
    final color = isTaxi ? AppColors.taxiBadge : AppColors.deliveryBadge;
    final label = isTaxi ? 'تاكسي' : trip.vehicleTypeName;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_car_filled_outlined, size: 18.w, color: color),
        SizedBox(width: 4.w),
        IqText(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

// ── Trip Info Card ────────────────────────────────────────────

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip, required this.isDark});

  final TripEntity trip;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          AppStrings.tripInfo,
          style: AppTypography.heading3,
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.starRating,
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: context.screenWidth.w * 0.2,
            runSpacing: 10.h,
            children: [
              // Duration
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: AppStrings.duration,
                value: '${trip.totalTime ?? 0} ${AppStrings.minute}',
              ),

              // Distance
              _InfoRow(
                icon: Icons.route_outlined,
                label: AppStrings.distance,
                value:
                    '${trip.totalDistance?.toStringAsFixed(2) ?? '0'} ${AppStrings.km}',
              ),

              // Trip type
              _InfoRow(
                icon: Icons.directions_car_filled_outlined,
                label: AppStrings.tripType,
                value: AppStrings.normal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20.w, color: AppColors.gray3),
        SizedBox(width: 6.w),
        IqText(
          '$label :',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSubtitle,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(width: 4.w),
        IqText(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

// ── Address Pill ──────────────────────────────────────────────

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.address,
    required this.markerColor,
  });

  final String address;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: isDark ? AppColors.white.withValues(alpha: 0.24) : AppColors.grayBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 25.w,
            height: 25.h,
            child: Icon(
              Icons.location_on,
              size: 25.w,
              color: markerColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: IqText(
              address,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.white.withValues(alpha: 0.70) : AppColors.textAddress,
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fare Breakdown Section ────────────────────────────────────

class _FareBreakdownSection extends StatelessWidget {
  const _FareBreakdownSection({required this.trip, required this.isDark});

  final TripEntity trip;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fare = trip.fareBreakdown;
    final currency = trip.currencySymbol ?? 'IQD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          AppStrings.fareDetails,
          style: AppTypography.heading3,
        ),
        SizedBox(height: 12.h),

        // Base distance price
        _FareRow(
          label: '${AppStrings.baseDistancePrice} :',
          value: 'KM ${fare?.baseDistance.toStringAsFixed(1) ?? '0.0'}',
        ),
        SizedBox(height: 8.h),

        // Extra distance price
        _FareRow(
          label: '${AppStrings.extraDistancePrice} :',
          value: 'KM ${fare?.distancePrice.toStringAsFixed(1) ?? '0.0'}',
        ),
        SizedBox(height: 8.h),

        // Tax
        _FareRow(
          label: '${AppStrings.taxes} :',
          value: '${fare?.serviceTaxPercentage.toStringAsFixed(0) ?? '0'}%',
        ),
        SizedBox(height: 8.h),

        // Amount
        _FareRow(
          label: '${AppStrings.amount} ($currency) :',
          value: fare?.totalAmount.toStringAsFixed(2) ?? '0.00',
        ),
        SizedBox(height: 12.h),

        // Divider
        Divider(
          height: 1,
          color: isDark ? AppColors.white.withValues(alpha: 0.12) : AppColors.grayBorder,
        ),
        SizedBox(height: 12.h),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IqText(
              '${AppStrings.total} :',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSubtitle,
              ),
            ),
            IqText(
              trip.formattedTotal,
              style: AppTypography.heading1.copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IqText(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSubtitle,
          ),
        ),
        IqText(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontFamily: AppTypography.fontFamilyLatin,
            fontWeight: FontWeight.w600,
          ),
          
        ),
      ],
    );
  }
}

// ── Rating Section ────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final rating = trip.userRating ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          AppStrings.tripRating,
          style: AppTypography.heading3,
        ),
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            return Padding(
              padding: EdgeInsetsDirectional.only(end: 4.w),
              child: Icon(
                index < rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: index < rating.round()
                    ? AppColors.starFilled
                    : AppColors.starEmpty,
                size: 32.w,
              ),
            );
          }),
        ),
      ],
    );
  }
}
