import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/trip_chat_message_entity.dart';
import '../../domain/repositories/trip_chat_repository.dart';
import '../datasources/trip_chat_data_source.dart';

/// Production implementation of [TripChatRepository].
class TripChatRepositoryImpl implements TripChatRepository {
  final TripChatDataSource dataSource;

  TripChatRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<TripChatMessageEntity>>> getChatHistory({
    required String requestId,
  }) async {
    final result = await dataSource.getChatHistory(requestId: requestId);
    return result.map(
      (models) => models.cast<TripChatMessageEntity>(),
    );
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String requestId,
    required String message,
  }) {
    return dataSource.sendMessage(requestId: requestId, message: message);
  }

  @override
  Future<Either<Failure, void>> markSeen({
    required String requestId,
  }) {
    return dataSource.markSeen(requestId: requestId);
  }
}
