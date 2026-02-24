import 'package:equatable/equatable.dart';

/// Response from creating a ride request.
///
/// Contains the request ID needed to listen for Firebase updates.
class RideRequestResponseModel extends Equatable {
  const RideRequestResponseModel({
    required this.requestId,
    this.requestNumber,
    this.message,
  });

  final String requestId;
  final String? requestNumber;
  final String? message;

  factory RideRequestResponseModel.fromJson(Map<String, dynamic> json) {
    // The API may nest request_id in different places
    final data = json['data'];
    String reqId = '';
    String? reqNumber;

    if (data is Map<String, dynamic>) {
      reqId = (data['id'] ?? data['request_id'] ?? '').toString();
      reqNumber = data['request_number']?.toString();
    } else {
      reqId = (json['request_id'] ?? json['id'] ?? '').toString();
    }

    return RideRequestResponseModel(
      requestId: reqId,
      requestNumber: reqNumber,
      message: json['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [requestId];
}
