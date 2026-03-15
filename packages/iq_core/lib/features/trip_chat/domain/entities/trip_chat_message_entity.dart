import 'package:equatable/equatable.dart';

/// A single message in the trip chat between passenger and driver.
class TripChatMessageEntity extends Equatable {
  final String id;
  final String message;

  /// 1 = passenger sent, 2 = driver sent.
  final int fromType;
  final String convertedCreatedAt;

  const TripChatMessageEntity({
    required this.id,
    required this.message,
    required this.fromType,
    required this.convertedCreatedAt,
  });

  @override
  List<Object?> get props => [id, message, fromType, convertedCreatedAt];
}
