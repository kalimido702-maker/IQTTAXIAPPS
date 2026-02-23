import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Attaches the Bearer token from [SharedPreferences] to every request.
/// 
/// On 401 → clears token, queues pending requests, and emits
/// [UnauthorizedEvent] via [AuthService] for the BLoC to handle logout.
class AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;
  final AuthService authService;

  static const _tokenKey = 'auth_token';

  AuthInterceptor({
    required this.prefs,
    required this.authService,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // If a refresh is in progress, queue this request
    if (authService.isRefreshing) {
      authService.queueRequest(options);
      // Don't proceed now; wait for refresh to complete
      return;
    }

    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      // 1. Clear the stored token
      prefs.remove(_tokenKey);

      // 2. Set refreshing flag to queue any new requests
      authService.setRefreshing(true);

      // 3. Emit unauthorized event so BLoC can trigger logout
      authService.emitUnauthorized();

      // 4. Don't retry; let the BLoC handle logout
    }

    handler.next(err);
  }
}

/// Debug-only request / response logger.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log(
      '→ ${options.method} ${options.uri}',
      name: 'API',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'API',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      '✖ ${err.response?.statusCode ?? 'UNKNOWN'} ${err.requestOptions.uri}\n'
      '  ${err.message}',
      name: 'API',
    );
    handler.next(err);
  }
}
