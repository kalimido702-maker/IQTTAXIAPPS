import 'package:equatable/equatable.dart';

/// Lightweight model for ongoing rides shown on the passenger home page.
///
/// Parsed from the `GET api/v1/request/history?on_trip=1` response.
/// Contains only the fields needed for the horizontal carousel card.
class OngoingRideModel extends Equatable {
  const OngoingRideModel({
    required this.id,
    required this.pickAddress,
    this.dropAddress = '',
    required this.pickLat,
    required this.pickLng,
    this.dropLat = 0,
    this.dropLng = 0,
    this.driverName = '',
    this.driverProfilePicture,
    this.carNumber = '',
    this.vehicleTypeName = '',
    this.acceptedAt,
    this.isDriverArrived = false,
    this.isTripStart = false,
    this.isCompleted = false,
    this.isCancelled = false,
    this.isPaid = false,
    this.requestEtaAmount = 0,
    this.acceptedRideFare = 0,
    this.currencySymbol = 'IQD',
    this.paymentTypeString = '',
    this.paymentOpt = 1,
    this.isBidRide = false,
    this.isOutStation = false,
  });

  final String id;
  final String pickAddress;
  final String dropAddress;
  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;

  // Driver info
  final String driverName;
  final String? driverProfilePicture;
  final String carNumber;
  final String vehicleTypeName;

  // Trip status fields
  final String? acceptedAt;
  final bool isDriverArrived;
  final bool isTripStart;
  final bool isCompleted;
  final bool isCancelled;
  final bool isPaid;

  // Payment / fare
  final double requestEtaAmount;
  final double acceptedRideFare;
  final String currencySymbol;
  final String paymentTypeString;
  final int paymentOpt;
  final bool isBidRide;
  final bool isOutStation;

  /// Display amount — bid/outstation uses acceptedRideFare, else requestEtaAmount.
  double get displayAmount =>
      (isBidRide || isOutStation) ? acceptedRideFare : requestEtaAmount;

  /// Status label for the card.
  OngoingRideStatus get rideStatus {
    if (isCancelled) return OngoingRideStatus.cancelled;
    if (isCompleted) return OngoingRideStatus.completed;
    if (isTripStart) return OngoingRideStatus.tripStarted;
    if (isDriverArrived) return OngoingRideStatus.arrived;
    if (acceptedAt != null && acceptedAt!.isNotEmpty) {
      return OngoingRideStatus.accepted;
    }
    return OngoingRideStatus.accepted;
  }

  factory OngoingRideModel.fromJson(Map<String, dynamic> json) {
    // Driver detail is nested: { "data": { ... } }
    final driverDetail = json['driverDetail'] as Map<String, dynamic>?;
    final driverData =
        (driverDetail?['data'] as Map<String, dynamic>?) ?? driverDetail ?? {};

    return OngoingRideModel(
      id: (json['id'] ?? '').toString(),
      pickAddress: (json['pick_address'] ?? '').toString(),
      dropAddress: (json['drop_address'] ?? '').toString(),
      pickLat: _toDouble(json['pick_lat']),
      pickLng: _toDouble(json['pick_lng']),
      dropLat: _toDouble(json['drop_lat']),
      dropLng: _toDouble(json['drop_lng']),
      driverName: (driverData['name'] ?? '').toString(),
      driverProfilePicture: driverData['profile_picture']?.toString(),
      carNumber: (driverData['car_number'] ?? '').toString(),
      vehicleTypeName:
          (driverData['vehicle_type_name'] ?? json['vehicle_type_name'] ?? '')
              .toString(),
      acceptedAt: json['accepted_at']?.toString(),
      isDriverArrived: _toBool(json['is_driver_arrived']),
      isTripStart: _toBool(json['is_trip_start']),
      isCompleted: _toBool(json['is_completed']),
      isCancelled: _toBool(json['is_cancelled']),
      isPaid: _toBool(json['is_paid']),
      requestEtaAmount: _toDouble(json['request_eta_amount']),
      acceptedRideFare: _toDouble(json['accepted_ride_fare']),
      currencySymbol:
          (json['requested_currency_symbol'] ?? 'IQD').toString(),
      paymentTypeString: (json['payment_type_string'] ?? '').toString(),
      paymentOpt: _toInt(json['payment_opt']),
      isBidRide: _toBool(json['is_bid_ride']),
      isOutStation: _toInt(json['is_out_station']) == 1,
    );
  }

  // ── Helpers ──

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [id, rideStatus];
}

/// Status enum for ongoing ride cards.
enum OngoingRideStatus {
  accepted,
  arrived,
  tripStarted,
  completed,
  cancelled,
}
