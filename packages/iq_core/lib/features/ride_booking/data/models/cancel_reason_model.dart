import 'package:equatable/equatable.dart';

/// A cancellation reason option from the API.
class CancelReasonModel extends Equatable {
  const CancelReasonModel({
    required this.id,
    required this.reason,
    required this.userType,
    required this.arrivalStatus,
  });

  final int id;
  final String reason;

  /// "user" or "driver"
  final String userType;

  /// "before" or "after" driver arrival.
  final String arrivalStatus;

  factory CancelReasonModel.fromJson(Map<String, dynamic> json) {
    return CancelReasonModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] ?? '').toString(),
      userType: (json['user_type'] ?? 'user').toString(),
      arrivalStatus: (json['arrival_status'] ?? 'before').toString(),
    );
  }

  @override
  List<Object?> get props => [id, reason];
}
