import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/data/models/user_model.dart';
import 'profile_data_source.dart';

/// Production implementation of [ProfileDataSource].
class ProfileDataSourceImpl implements ProfileDataSource {
  final Dio dio;

  /// Whether this is for a driver app.
  /// Drivers use `api/v1/user/driver-profile`, passengers use `api/v1/user/profile`.
  final bool isDriver;

  ProfileDataSourceImpl({
    required this.dio,
    this.isDriver = false,
  });

  @override
  Future<Either<Failure, UserModel>> getProfile() async {
    try {
      // Server uses one unified endpoint — role is determined from token.
      final response = await dio.get('api/v1/user');

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'استجابة غير صالحة'));
      }

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return Right(UserModel.fromJson(data));
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? 'فشل تحميل البروفايل',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? profilePicturePath,
  }) async {
    try {
      final endpoint = isDriver
          ? 'api/v1/user/driver-profile'
          : 'api/v1/user/profile';

      // Use FormData for multipart (supports file upload)
      final formData = FormData();

      if (name != null && name.isNotEmpty) {
        formData.fields.add(MapEntry('name', name));
      }
      if (email != null && email.isNotEmpty) {
        formData.fields.add(MapEntry('email', email));
      }
      if (gender != null && gender.isNotEmpty) {
        formData.fields.add(MapEntry('gender', gender));
      }
      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        formData.files.add(MapEntry(
          'profile_picture',
          await MultipartFile.fromFile(
            profilePicturePath,
            filename: 'profile_picture.jpg',
          ),
        ));
      }

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'استجابة غير صالحة'));
      }

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return Right(UserModel.fromJson(data));
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? 'فشل تحديث البروفايل',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Extract error message from API response.
  String? _extractMessage(Map<String, dynamic> body) {
    final msg = body['message'];
    if (msg == null) return null;
    if (msg is String) return msg;
    if (msg is List) return msg.join(', ');
    return msg.toString();
  }

  ServerFailure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ServerFailure(message: 'انتهت مهلة الاتصال');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ServerFailure(
          message: data['message']?.toString() ?? 'حدث خطأ في الخادم',
          statusCode: e.response!.statusCode,
        );
      }
    }
    return ServerFailure(message: e.message ?? 'حدث خطأ غير متوقع');
  }
}
