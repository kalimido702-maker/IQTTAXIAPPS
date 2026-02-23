import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Centralized API client using Dio
/// Configures base URL, interceptors, and timeouts
class ApiClient {
  late final Dio dio;

  ApiClient({
    required String baseUrl,
    required SharedPreferences prefs,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(prefs),
      LoggingInterceptor(),
    ]);
  }
}
