import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/trip_chat_message_entity.dart';

/// Contract for trip chat repository (passenger ↔ driver messaging).
abstract class TripChatRepository {
  /// Load chat history for the given trip request.
  Future<Either<Failure, List<TripChatMessageEntity>>> getChatHistory({
    required String requestId,
  });

  /// Send a message in the trip chat.
  Future<Either<Failure, void>> sendMessage({
    required String requestId,
    required String message,
  });

  /// Mark all messages as seen / read.
  Future<Either<Failure, void>> markSeen({
    required String requestId,
  });
}
