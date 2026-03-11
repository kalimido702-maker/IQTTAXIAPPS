import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Production implementation of [AuthDataSource].
///
/// Calls the real IQ Taxi REST API (base URL configured in [Dio]).
class AuthDataSourceImpl implements AuthDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';

  AuthDataSourceImpl({required this.dio, required this.prefs});

  // ──────────────────────────────────────────────
  //  SEND OTP
  //
  //  The server's OTP store is tied to the login/register controller.
  //  `mobile-otp` creates OTPs in a DIFFERENT store that
  //  `validate-mobile` cannot verify.
  //
  //  Passenger: POST user/login       → triggers OTP
  //  Driver:    POST driver/register   → triggers OTP
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String role = 'passenger',
  }) async {
    try {
      final deviceToken = await _getDeviceToken();

      if (role == 'driver') {
        // Driver app: always calls register (handles both new & existing)
        final formData = FormData.fromMap({
          'mobile': phone,
          'device_token': deviceToken,
          'country': '+964',
          'login_by': Platform.isIOS ? 'ios' : 'android',
          'lang': 'ar',
        });

        final response = await dio.post(
          'api/v1/driver/register',
          data: formData,
        );

        final data = _parseJson(response.data);

        // ── Old-app compat: check active/mode/whatsapp_deeplink ──
        final active = data['active'];
        final mode = data['mode']?.toString() ?? '';
        final whatsappLink = data['whatsapp_deeplink']?.toString() ?? '';
        final serverMsg = data['message']?.toString() ?? '';

        // New / unapproved driver → redirect to WhatsApp
        if ((active == 0 || active == '0') &&
            mode == 'register' &&
            whatsappLink.isNotEmpty) {
          return Left(
            RegistrationRedirectFailure(
              whatsappLink: whatsappLink,
              displayMessage: serverMsg.isNotEmpty
                  ? serverMsg
                  : AppStrings.registrationPending,
            ),
          );
        }

        // uuid present → OTP was sent
        if (response.statusCode == 200 &&
            data['uuid'] != null &&
            (data['uuid'] as String).isNotEmpty) {
          return const Right(true);
        }

        return Left(
          ServerFailure(
            message: serverMsg.isNotEmpty
                ? serverMsg
                : '\u0641\u0634\u0644 \u0625\u0631\u0633\u0627\u0644 \u0631\u0645\u0632 \u0627\u0644\u062A\u062D\u0642\u0642',
          ),
        );
      } else {
        // Passenger app: call user/login → server sends OTP
        final formData = FormData.fromMap({
          'mobile': phone,
          'device_token': deviceToken,
          'login_by': Platform.isIOS ? 'ios' : 'android',
        });

        final response = await dio.post(
          'api/v1/user/login',
          data: formData,
        );

        final data = _parseJson(response.data);

        if (response.statusCode == 200 && data['success'] == true) {
          return const Right(true);
        }

        return Left(
          ServerFailure(
            message: data['message']?.toString() ??
                '\u0641\u0634\u0644 \u0625\u0631\u0633\u0627\u0644 \u0631\u0645\u0632 \u0627\u0644\u062A\u062D\u0642\u0642',
          ),
        );
      }
    } on DioException catch (e) {
      // User/driver not found → needs registration
      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          final msg = (body['message'] ?? '').toString().toLowerCase();
          // Server says user not found / not registered
          if (msg.contains('not found') ||
              msg.contains('not register') ||
              msg.contains('not exist') ||
              msg.contains('no user')) {
            return Left(AuthFailure(message: 'needs_registration'));
          }
          // Other 422 (validation errors) — show actual message
          final errors = body['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstErrors = errors.values.first;
            if (firstErrors is List && firstErrors.isNotEmpty) {
              return Left(
                  ServerFailure(message: firstErrors.first.toString()));
            }
          }
          return Left(ServerFailure(
            message: body['message']?.toString() ??
                '\u0641\u0634\u0644 \u0625\u0631\u0633\u0627\u0644 \u0631\u0645\u0632 \u0627\u0644\u062A\u062D\u0642\u0642',
          ));
        }
        // Fallback for 404 without structured body
        if (e.response?.statusCode == 404) {
          return Left(AuthFailure(message: 'needs_registration'));
        }
      }

      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  VERIFY OTP  (user / driver)
  //
  //  Flow (matches old app behaviour):
  //  1. POST {prefix}/validate-mobile  with { otp } only
  //  2a. Response has access_token → existing user → save & fetch profile
  //  2b. Response success, no token → new user   → needs_registration
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String role = 'passenger',
  }) async {
    final prefix = role == 'driver' ? 'driver' : 'user';

    try {
      final response = await dio.post(
        'api/v1/$prefix/validate-mobile',
        data: {'otp': otp},
      );

      final data = _parseJson(response.data);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['access_token']?.toString();

        if (token != null && token.isNotEmpty) {
          // ── Existing user: token received → save & fetch profile ──
          final cleanToken =
              token.startsWith('Bearer ') ? token.substring(7) : token;
          await prefs.setString(_tokenKey, cleanToken);
          return _fetchAndCacheUser(role: role);
        }

        // ── No token → new user → needs registration ──
        return Left(AuthFailure(message: 'needs_registration'));
      }

      // Server returned success:false or unexpected shape
      return Left(
        ServerFailure(
          message: data['message']?.toString() ??
              '\u0641\u0634\u0644 \u0627\u0644\u062A\u062D\u0642\u0642 \u0645\u0646 \u0627\u0644\u0631\u0645\u0632',
        ),
      );
    } on DioException catch (e) {
      // 404 → user not found → needs registration
      if (e.response?.statusCode == 404) {
        return Left(AuthFailure(message: 'needs_registration'));
      }

      // 422 → validation error (wrong/expired OTP)
      if (e.response?.statusCode == 422) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          // Try extracting first validation error
          final errors = responseData['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstErrors = errors.values.first;
            if (firstErrors is List && firstErrors.isNotEmpty) {
              return Left(
                  ServerFailure(message: firstErrors.first.toString()));
            }
          }
          final msg = responseData['message']?.toString() ?? '';
          return Left(ServerFailure(
            message: msg.isNotEmpty
                ? msg
                : '\u0631\u0645\u0632 \u0627\u0644\u062A\u062D\u0642\u0642 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D',
          ));
        }
      }

      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  REGISTER
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    String? email,
    String? gender,
    required String role,
  }) async {
    try {
      final endpoint = role == 'driver'
          ? 'api/v1/driver/register'
          : 'api/v1/user/register';

      final deviceToken = await _getDeviceToken();

      final formData = FormData.fromMap({
        'mobile': phone,
        'device_token': deviceToken,
        'country': '+964',
        'login_by': Platform.isIOS ? 'ios' : 'android',
        'lang': 'ar',
        if (name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      });

      final response = await dio.post(endpoint, data: formData);
      final data = _parseJson(response.data);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          // Remove leading "Bearer " if the server already prefixes it
          final cleanToken =
              token.startsWith('Bearer ') ? token.substring(7) : token;
          await prefs.setString(_tokenKey, cleanToken);

          return _fetchAndCacheUser(role: role);
        }

        // Registration succeeded but needs OTP verification first.
        // The API returned success without an access_token.
        return const Left(
          ServerFailure(message: 'needs_otp'),
        );
      }

      return Left(
        ServerFailure(
          message: data['message']?.toString() ?? AppStrings.failedToRegister,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  LOGOUT
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove('skipSubscription');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  IS LOGGED IN
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = prefs.getString(_tokenKey);
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  GET CACHED USER
  // ──────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> getCachedUser() async {
    try {
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        return const Left(CacheFailure(message: 'No cached user'));
      }
      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ──────────────────────────────────────────────

  /// Returns the FCM device token for push notifications.
  /// Falls back to a placeholder if retrieval fails (e.g. simulator).
  Future<String> _getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {
      // FCM not available (simulator, missing config, etc.)
    }
    return 'no_fcm_token';
  }

  /// Fetches full user profile from `GET api/v1/user` (or driver)
  /// and caches it in SharedPreferences.
  Future<Either<Failure, UserEntity>> _fetchAndCacheUser({
    required String role,
  }) async {
    try {
      // Server uses one unified endpoint — the role is determined
      // from the Bearer token automatically.
      final response = await dio.get('api/v1/user');
      final data = _parseJson(response.data);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = _parseJson(data['data']);
        final user = UserModel.fromJson(userData);

        // Cache for offline access
        await prefs.setString(_userKey, jsonEncode(user.toJson()));

        return Right(user);
      }

      return Left(
        ServerFailure(
          message:
              data['message']?.toString() ?? AppStrings.failedToLoadUserData,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Safely parses [response.data] whether Dio already decoded it
  /// to a [Map] or left it as a raw JSON [String].
  Map<String, dynamic> _parseJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    throw FormatException('Unexpected response type: ${data.runtimeType}');
  }

  /// Maps [DioException] to a user-friendly [Failure].
  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: AppStrings.connectionTimeoutRetry,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        String message = AppStrings.serverError;

        if (body is Map<String, dynamic>) {
          message = body['message']?.toString() ?? message;
        }

        if (statusCode == 401) {
          return AuthFailure(message: message);
        }
        return ServerFailure(message: message, statusCode: statusCode);
      default:
        return ServerFailure(
          message: e.message ?? AppStrings.unexpectedError,
        );
    }
  }
}
