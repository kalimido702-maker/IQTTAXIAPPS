import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/trip_chat_message_model.dart';

/// Contract for trip chat API calls.
abstract class TripChatDataSource {
  /// Fetch the chat history for the given trip request.
  Future<Either<Failure, List<TripChatMessageModel>>> getChatHistory({
    required String requestId,
  });

  /// Send a message in the trip chat.
  Future<Either<Failure, void>> sendMessage({
    required String requestId,
    required String message,
  });

  /// Mark all trip chat messages as seen / read.
  Future<Either<Failure, void>> markSeen({
    required String requestId,
  });
}
