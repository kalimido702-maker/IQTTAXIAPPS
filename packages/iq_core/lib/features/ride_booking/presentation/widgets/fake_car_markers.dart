import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Manages a set of 3–6 "ghost" car markers that randomly appear and
/// disappear on the map around a central point while the passenger is
/// waiting for a driver.
///
/// Usage:
/// ```dart
/// final controller = FakeCarMarkersController(center: pickupLatLng);
/// controller.start((markers) => setState(() => _fakeMarkers = markers));
/// // …later
/// controller.stop();
/// ```
class FakeCarMarkersController {
  FakeCarMarkersController({required this.center});

  /// The pickup location around which ghost cars appear.
  final LatLng center;

  Timer? _timer;
  final _random = math.Random();

  /// Current visible fake car markers.
  final Set<Marker> markers = {};

  /// Total ghost car slots (each slot can be visible or hidden).
  static const _maxCars = 6;

  /// How often to toggle a random car on/off.
  static const _interval = Duration(milliseconds: 2000);

  /// Radius in degrees (~0.005 ≈ 500m) for random positions around center.
  static const _radiusDeg = 0.005;

  /// The marker icon for ghost cars — generated once.
  static BitmapDescriptor? _carIcon;
  static bool _iconLoading = false;

  /// Callback invoked whenever the visible markers set changes.
  void Function(Set<Marker>)? _onChange;

  /// Start cycling ghost cars on/off. Calls [onChange] on every change.
  Future<void> start(void Function(Set<Marker>) onChange) async {
    _onChange = onChange;

    // Ensure icon is ready
    await _ensureIcon();

    // Seed 3 initial cars
    for (int i = 0; i < 3; i++) {
      _addRandomCar();
    }
    _onChange?.call(Set.of(markers));

    // Periodically toggle random car visibility
    _timer = Timer.periodic(_interval, (_) {
      _toggleRandomCar();
      _onChange?.call(Set.of(markers));
    });
  }

  /// Stop and clear all ghost markers.
  void stop() {
    _timer?.cancel();
    _timer = null;
    markers.clear();
    _onChange?.call({});
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Internal ────────────────────────────────────────────────────

  void _toggleRandomCar() {
    final action = _random.nextDouble();

    if (markers.length <= 2) {
      // Too few — always add
      _addRandomCar();
    } else if (markers.length >= _maxCars) {
      // Max reached — always remove
      _removeRandomCar();
    } else if (action < 0.45) {
      // ~45% chance to add
      _addRandomCar();
    } else if (action < 0.85) {
      // ~40% chance to remove & re-add at different spot
      _removeRandomCar();
      _addRandomCar();
    } else {
      // ~15% chance to just remove
      _removeRandomCar();
    }
  }

  void _addRandomCar() {
    final id = 'fake_car_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}';
    final lat = center.latitude + (_random.nextDouble() - 0.5) * 2 * _radiusDeg;
    final lng = center.longitude + (_random.nextDouble() - 0.5) * 2 * _radiusDeg;
    final rotation = _random.nextDouble() * 360;

    markers.add(Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      rotation: rotation,
      anchor: const Offset(0.5, 0.5),
      flat: true,
    ));
  }

  void _removeRandomCar() {
    if (markers.isEmpty) return;
    final idx = _random.nextInt(markers.length);
    markers.remove(markers.elementAt(idx));
  }

  static Future<void> _ensureIcon() async {
    if (_carIcon != null || _iconLoading) return;
    _iconLoading = true;

    try {
      _carIcon = await _createCarIcon();
    } catch (_) {
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    _iconLoading = false;
  }

  /// Renders a simple white car icon with shadow.
  static Future<BitmapDescriptor> _createCarIcon() async {
    const size = 56.0;
    const halfSize = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(halfSize, halfSize + 2),
          width: size * 0.8,
          height: size * 0.42,
        ),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Car body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(halfSize, halfSize),
          width: size * 0.75,
          height: size * 0.38,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white,
    );

    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(halfSize + size * 0.12, halfSize),
          width: size * 0.22,
          height: size * 0.28,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF242E42),
    );

    // Rear window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(halfSize - size * 0.18, halfSize),
          width: size * 0.18,
          height: size * 0.26,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF242E42),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
