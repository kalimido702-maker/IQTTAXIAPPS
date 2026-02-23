import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Initializes the latest Google Maps renderer on Android for improved
/// performance and smoother map interactions.
///
/// Must be called **before** `runApp()` and **after**
/// `WidgetsFlutterBinding.ensureInitialized()`.
///
/// On iOS this is a no-op. Safe to call multiple times (including hot restart).
Future<void> initMapRenderer() async {
  if (!Platform.isAndroid) return;

  final platform = GoogleMapsFlutterPlatform.instance;
  if (platform is GoogleMapsFlutterAndroid) {
    try {
      await platform.initializeWithRenderer(AndroidMapRenderer.latest);
    } on PlatformException catch (_) {
      // Already initialized on the native side (e.g. after hot restart).
    }
  }
}
