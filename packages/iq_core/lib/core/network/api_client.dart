import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_interceptors.dart';
import 'auth_service.dart';

/// Central HTTP client wrapping [Dio].
///
/// Provides a pre-configured Dio instance with:
///  - Base URL: `https://taxi-new.elnoorphp.com/`
///  - Auth interceptor (Bearer token from SharedPreferences)
///  - Logging interceptor (debug only)
///  - 30 s connect / receive timeouts
class ApiClient {
  final Dio dio;

  ApiClient._({required this.dio});

  /// Factory that builds a production-ready [ApiClient].
  static Future<ApiClient> create({
    String baseUrl = 'https://taxi-new.elnoorphp.com/',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(prefs: prefs, authService: authService),
      LoggingInterceptor(),
    ]);

    return ApiClient._(dio: dio);
  }
}
