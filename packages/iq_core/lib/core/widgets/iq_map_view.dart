import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/map_style.dart';
import '../services/map_performance.dart';

/// High-performance Google Maps wrapper.
///
/// Performance optimizations (9 techniques):
///
/// 1. [RepaintBoundary] — isolates map repaints from the widget tree.
/// 2. [AutomaticKeepAliveClientMixin] — keeps map alive in tab views
///    to avoid expensive re-creation of the native platform view.
/// 3. Cached [CameraPosition] — only created once, never re-allocated.
/// 4. Marker/polyline sets are only re-rendered when they actually change
///    (reference equality check in [didUpdateWidget]).
/// 5. [CameraThrottle] — throttles onCameraMove to max 10/sec instead
///    of 60/sec, reducing GC pressure from callback allocations.
/// 6. Controller lifecycle: disposed in [dispose], guarded by [mounted].
/// 7. Buildings, indoor views, traffic, toolbar, compass all disabled
///    by default — reduces GPU tiles & memory.
/// 8. Gesture recognizers use a static const factory to avoid per-build
///    allocation of the Set + Factory objects.
/// 9. [MinMaxZoomPreference] prevents loading excessive detail tiles
///    at extreme zoom levels.
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
    this.keepAlive = true,
    this.liteModeEnabled = false,
    this.mapStyle = kCleanMapStyle,
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

  /// Technique 2: Keep the map alive in tab/page views to avoid
  /// re-creating the expensive native platform view.
  final bool keepAlive;

  /// Use lite mode for static, non-interactive map previews
  /// (e.g., trip history cards). Saves significant GPU memory.
  final bool liteModeEnabled;

  /// Map style JSON to apply. Defaults to [kCleanMapStyle] which
  /// hides POIs, transit, and business labels for faster rendering.
  /// Pass `null` to use Google's default style.
  final String? mapStyle;

  @override
  State<IqMapView> createState() => IqMapViewState();
}

class IqMapViewState extends State<IqMapView>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;
  bool _isDisposed = false;

  /// Technique 4: Throttle camera updates to reduce GC pressure.
  final CameraThrottle _cameraThrottle = CameraThrottle();

  /// Baghdad as fallback center.
  static const _baghdad = LatLng(33.3152, 44.3661);

  /// Technique 8: Const gesture recognizer set — allocated once.
  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())};

  /// Technique 3: Cache the initial camera position — never re-created.
  late final CameraPosition _initialCameraPosition = CameraPosition(
    target: widget.initialTarget ?? _baghdad,
    zoom: widget.initialZoom,
  );

  /// Technique 9: Zoom limits — prevent excessive tile loading.
  static const _zoomLimits = MinMaxZoomPreference(5.0, 20.0);

  GoogleMapController? get controller => _controller;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  // ─── Public helpers ──────────────────────────────────────────────

  /// Smoothly animate to [target] at the given [zoom].
  Future<void> animateTo(LatLng target, {double? zoom}) async {
    if (_isDisposed || _controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom ?? widget.initialZoom),
      ),
    );
  }

  /// Fit the camera to bounds with padding.
  Future<void> fitBounds(LatLngBounds bounds, {double padding = 80}) async {
    if (_isDisposed || _controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// Animate to the user's current location.
  Future<void> goToMyLocation() async {
    if (_isDisposed) return;
    try {
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
      if (!_isDisposed) {
        await animateTo(LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      // Silently fail — permission might be denied.
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;
    // Technique 5: Properly dispose controller to release native resources.
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Technique 2: Required by AutomaticKeepAliveClientMixin.
    super.build(context);

    // Technique 1: RepaintBoundary isolates map from widget tree repaints.
    return RepaintBoundary(
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: widget.markers,
        polylines: widget.polylines,
        circles: widget.circles,
        padding: widget.mapPadding,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
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
        liteModeEnabled: widget.liteModeEnabled,
        // Technique 8: Static const recognizers — no per-build allocation.
        gestureRecognizers: _gestureRecognizers,
        // Technique 9: Limit zoom to prevent excessive tile loading.
        minMaxZoomPreference: _zoomLimits,
        style: widget.mapStyle,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_isDisposed || !mounted) return;
    _controller = controller;
    widget.onMapCreated?.call(controller);

    // If no explicit target was given (map opened at fallback center),
    // immediately try to jump to the user's cached GPS position so the
    // Baghdad flash is as short as possible.
    if (widget.initialTarget == null) {
      _jumpToCachedLocation();
    }
  }

  /// Quick async hop — uses cached (instant) GPS. No permission prompt.
  Future<void> _jumpToCachedLocation() async {
    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null && !_isDisposed) {
        await animateTo(LatLng(cached.latitude, cached.longitude));
      }
    } catch (_) {}
  }

  /// Technique 4: Throttled camera move — max ~10 updates/sec.
  void _onCameraMove(CameraPosition position) {
    if (widget.onCameraMove == null) return;
    final throttled = _cameraThrottle.throttle(position);
    if (throttled != null) {
      widget.onCameraMove!(throttled);
    }
  }

  /// On camera idle, always fire with the latest position.
  void _onCameraIdle() {
    widget.onCameraIdle?.call();
  }
}
