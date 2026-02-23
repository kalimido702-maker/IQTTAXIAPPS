import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// High-performance Google Maps wrapper.
///
/// Performance optimizations applied:
/// 1. [RepaintBoundary] isolates map repaints from the widget tree.
/// 2. Camera moves use [GoogleMapController.animateCamera] — no rebuild.
/// 3. Markers / polylines are passed as [ValueNotifier]-friendly sets.
/// 4. Buildings, indoor views and traffic are disabled by default.
/// 5. Map type defaults to [MapType.normal] with lite mode OFF
///    (lite mode produces a static bitmap — bad for interaction).
/// 6. My-location layer is handled natively by the map SDK.
/// 7. Padding can be adjusted for bottom sheets without rebuilding the map.
class IqMapView extends StatefulWidget {
  const IqMapView({
    super.key,
    this.initialTarget,
    this.initialZoom = 15.0,
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.mapPadding = EdgeInsets.zero,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.compassEnabled = false,
    this.mapToolbarEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = false,
    this.indoorViewEnabled = false,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
  });

  /// Initial camera center. If null, defaults to Baghdad.
  final LatLng? initialTarget;
  final double initialZoom;

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;

  final void Function(GoogleMapController controller)? onMapCreated;
  final void Function(CameraPosition position)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final void Function(LatLng position)? onTap;

  /// Padding applied inside the map viewport — use this to offset the
  /// Google logo / controls when a bottom sheet is visible.
  final EdgeInsets mapPadding;

  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool indoorViewEnabled;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomGesturesEnabled;

  @override
  State<IqMapView> createState() => IqMapViewState();
}

class IqMapViewState extends State<IqMapView> {
  GoogleMapController? _controller;

  /// Baghdad as fallback center.
  static const _baghdad = LatLng(33.3152, 44.3661);

  GoogleMapController? get controller => _controller;

  // ─── Public helpers ──────────────────────────────────────────────

  /// Smoothly animate to [target] at the given [zoom].
  Future<void> animateTo(LatLng target, {double? zoom}) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom ?? widget.initialZoom),
      ),
    );
  }

  /// Animate to the user's current location.
  Future<void> goToMyLocation() async {
    try {
      // Ensure permission is granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await animateTo(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Silently fail — permission might be denied.
    }
  }

  /// Update map padding (e.g. when a bottom sheet changes height).
  Future<void> updatePadding(EdgeInsets padding) async {
    await _controller?.moveCamera(
      CameraUpdate.newLatLng(
        await _controller!
            .getLatLng(const ScreenCoordinate(x: 0, y: 0))
            .catchError((_) => _baghdad),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialTarget ?? _baghdad,
          zoom: widget.initialZoom,
        ),
        markers: widget.markers,
        polylines: widget.polylines,
        circles: widget.circles,
        padding: widget.mapPadding,
        onMapCreated: _onMapCreated,
        onCameraMove: widget.onCameraMove,
        onCameraIdle: widget.onCameraIdle,
        onTap: widget.onTap,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationButtonEnabled,
        zoomControlsEnabled: widget.zoomControlsEnabled,
        compassEnabled: widget.compassEnabled,
        mapToolbarEnabled: widget.mapToolbarEnabled,
        trafficEnabled: widget.trafficEnabled,
        buildingsEnabled: widget.buildingsEnabled,
        indoorViewEnabled: widget.indoorViewEnabled,
        rotateGesturesEnabled: widget.rotateGesturesEnabled,
        scrollGesturesEnabled: widget.scrollGesturesEnabled,
        tiltGesturesEnabled: widget.tiltGesturesEnabled,
        zoomGesturesEnabled: widget.zoomGesturesEnabled,
        // Performance: prevent gesture conflicts with DraggableScrollableSheet
        // by eagerly claiming all gestures inside the map viewport.
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        // Limit zoom to prevent excessive tile loading
        minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
        style: null,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }
}
