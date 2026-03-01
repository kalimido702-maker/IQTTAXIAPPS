import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';

/// Incoming ride request for the driver, from Firebase `request-meta`.
class IncomingRequestModel extends Equatable {
  const IncomingRequestModel({
    required this.requestId,
    this.userId,
    this.userName,
    this.userImage,
    this.userRating,
    this.totalRides,
    required this.pickLat,
    required this.pickLng,
    required this.dropLat,
    required this.dropLng,
    required this.pickAddress,
    required this.dropAddress,
    required this.vehicleTypeName,
    required this.vehicleTypeIcon,
    required this.rideType,
    required this.paymentMethod,
    required this.totalAmount,
    required this.currency,
    required this.currencySymbol,
    required this.distance,
    this.transportType = 'taxi',
    this.isBidRide = false,
    this.offerAmount,
    this.expiresAt,
  });

  final String requestId;
  final String? userId;
  final String? userName;
  final String? userImage;
  final String? userRating;
  final String? totalRides;
  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;
  final String pickAddress;
  final String dropAddress;
  final String vehicleTypeName;
  final String vehicleTypeIcon;
  final String rideType;
  final int paymentMethod;
  final double totalAmount;
  final String currency;
  final String currencySymbol;
  final double distance;
  final String transportType;
  final bool isBidRide;
  final double? offerAmount;

  /// Timestamp when the request expires for this driver.
  final int? expiresAt;

  factory IncomingRequestModel.fromFirebase(
    String requestId,
    Map<dynamic, dynamic> data,
  ) {
    return IncomingRequestModel(
      requestId: requestId,
      userId: data['user_id']?.toString(),
      userName: data['user_name']?.toString() ?? data['name']?.toString(),
      userImage: data['user_image']?.toString() ??
          data['profile_picture']?.toString(),
      userRating: data['user_rating']?.toString() ??
          data['rating']?.toString(),
      totalRides: data['total_rides']?.toString(),
      pickLat: _d(data['pick_lat']) ?? 0.0,
      pickLng: _d(data['pick_lng']) ?? 0.0,
      dropLat: _d(data['drop_lat']) ?? 0.0,
      dropLng: _d(data['drop_lng']) ?? 0.0,
      pickAddress: (data['pick_address'] ?? '').toString(),
      dropAddress: (data['drop_address'] ?? '').toString(),
      vehicleTypeName: (data['vehicle_type_name'] ?? '').toString(),
      vehicleTypeIcon: (data['vehicle_type_icon'] ?? '').toString(),
      rideType: (data['ride_type'] ?? '').toString(),
      paymentMethod: _i(data['payment_opt']) ?? 1,
      totalAmount: _d(data['total_amount']) ??
          _d(data['request_eta_amount']) ??
          0.0,
      currency: (data['currency'] ?? 'IQD').toString(),
      currencySymbol: (data['currency_symbol'] ?? AppStrings.currencyIQD).toString(),
      distance: _d(data['distance']) ?? 0.0,
      transportType: (data['transport_type'] ?? 'taxi').toString(),
      isBidRide: data['is_bid_ride'] == 1 || data['is_bid_ride'] == true,
      offerAmount: _d(data['offer_amount']),
      expiresAt: _i(data['expires_at']),
    );
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Parse from API `GET api/v1/user` → `response.data['metaRequest']['data']`.
  ///
  /// The backend returns full ride details here when a request is pending
  /// for this driver. Field names match the old app's MetaData model.
  factory IncomingRequestModel.fromApi(Map<String, dynamic> json) {
    final userDetail =
        json['userDetail']?['data'] as Map<String, dynamic>? ?? {};
    return IncomingRequestModel(
      requestId: (json['id'] ?? '').toString(),
      userId: userDetail['id']?.toString(),
      userName: (userDetail['name'] ?? '').toString(),
      userImage: userDetail['profile_picture']?.toString(),
      userRating: userDetail['rating']?.toString(),
      totalRides: userDetail['completed_ride_count']?.toString(),
      pickLat: _d(json['pick_lat']) ?? 0.0,
      pickLng: _d(json['pick_lng']) ?? 0.0,
      dropLat: _d(json['drop_lat']) ?? 0.0,
      dropLng: _d(json['drop_lng']) ?? 0.0,
      pickAddress: (json['pick_address'] ?? '').toString(),
      dropAddress: (json['drop_address'] ?? '').toString(),
      vehicleTypeName: (json['vehicle_type_name'] ?? '').toString(),
      vehicleTypeIcon: (json['vehicle_type_image'] ?? '').toString(),
      rideType: (json['ride_type'] ?? '').toString(),
      paymentMethod: _i(json['payment_opt']) ?? 1,
      totalAmount:
          _d(json['request_eta_amount']) ?? _d(json['total_amount']) ?? 0.0,
      currency: (json['currency'] ?? 'IQD').toString(),
      currencySymbol:
          (json['requested_currency_symbol'] ?? AppStrings.currencyIQD)
              .toString(),
      distance: _d(json['total_distance']) ?? 0.0,
      transportType: (json['transport_type'] ?? 'taxi').toString(),
      isBidRide: json['is_bid_ride'] == 1 || json['is_bid_ride'] == true,
      offerAmount: _d(json['offer_amount']),
      // API does not return expiresAt — overlay will use default 60s timer.
    );
  }

  @override
  List<Object?> get props => [requestId];
}
