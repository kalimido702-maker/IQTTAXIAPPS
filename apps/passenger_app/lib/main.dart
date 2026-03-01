import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iq_core/iq_core.dart';
import 'package:iq_core/core/services/map_performance.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force RTL & portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI style — transparent bars, dark icons
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      systemNavigationBarColor: AppColors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Initialize Firebase FIRST — must be before any DI registration
  // that might access Firebase services.
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, st) {
    debugPrint('❌ Firebase init failed: $e');
    debugPrint('❌ Stack trace: $st');
  }

  // Initialize core dependencies
  await initCoreDependencies();

  // Use latest Android Maps renderer for smoother performance
  await initMapRenderer();

  // Pre-cache map icons so they're ready before any map page opens
  MapIcons.precache();

  runApp(const PassengerApp());
}
