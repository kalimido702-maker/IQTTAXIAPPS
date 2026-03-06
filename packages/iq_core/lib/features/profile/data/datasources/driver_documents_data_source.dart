import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/needed_document_model.dart';

/// Data source for driver documents API.
abstract class DriverDocumentsDataSource {
  /// GET api/v1/driver/documents/needed
  Future<Either<Failure, List<NeededDocumentModel>>> getNeededDocuments();

  /// POST api/v1/driver/upload/documents
  Future<Either<Failure, bool>> uploadDocument({
    required String documentId,
    required String filePath,
    String? backFilePath,
    String? identifyNumber,
    String? expiryDate,
  });
}

class DriverDocumentsDataSourceImpl implements DriverDocumentsDataSource {
  DriverDocumentsDataSourceImpl({required this.dio});
  final Dio dio;

  @override
  Future<Either<Failure, List<NeededDocumentModel>>>
      getNeededDocuments() async {
    try {
      final response = await dio.get('api/v1/driver/documents/needed');
      final data = response.data;

      if (data['success'] == true || data['success'] == 1) {
        final List rawList = data['data'] ?? [];
        final docs =
            rawList.map((e) => NeededDocumentModel.fromJson(e)).toList();
        return Right(docs);
      }
      return Left(ServerFailure(
        message: data['message']?.toString() ?? 'Failed to load documents',
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error',
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> uploadDocument({
    required String documentId,
    required String filePath,
    String? backFilePath,
    String? identifyNumber,
    String? expiryDate,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_id': documentId,
        if (identifyNumber != null) 'identify_number': identifyNumber,
        if (expiryDate != null) 'expiry_date': expiryDate,
      });

      formData.files.add(MapEntry(
        'document',
        await MultipartFile.fromFile(filePath),
      ));

      if (backFilePath != null) {
        formData.files.add(MapEntry(
          'back_image',
          await MultipartFile.fromFile(backFilePath),
        ));
      }

      final response = await dio.post(
        'api/v1/driver/upload/documents',
        data: formData,
      );
      final data = response.data;
      return Right(data['success'] == true || data['success'] == 1);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Upload failed',
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
