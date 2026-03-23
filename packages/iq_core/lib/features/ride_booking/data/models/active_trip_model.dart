import 'package:equatable/equatable.dart';

/// An intermediate stop / waypoint within a trip.
class TripStopModel {
  const TripStopModel({
    required this.order,
    required this.lat,
    required this.lng,
    this.address = '',
    this.pocName,
    this.pocMobile,
    this.pocInstruction,
  });

  final int order;
  final double lat;
  final double lng;
  final String address;
  final String? pocName;
  final String? pocMobile;
  final String? pocInstruction;

  factory TripStopModel.fromMap(Map<dynamic, dynamic> data, {int fallbackOrder = 0}) {
    return TripStopModel(
      order: _parseInt(data['order']) ?? _parseInt(data['order_id']) ?? fallbackOrder,
      lat: _parseDouble(data['lat']) ?? _parseDouble(data['latitude']) ?? 0.0,
      lng: _parseDouble(data['lng']) ?? _parseDouble(data['longitude']) ?? 0.0,
      address: data['address']?.toString() ?? '',
      pocName: data['poc_name']?.toString(),
      pocMobile: data['poc_mobile']?.toString(),
      pocInstruction: data['poc_instruction']?.toString(),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Real-time trip state from Firebase RTDB at `requests/{requestId}`.
///
/// Represents the live state of an ongoing trip that both
/// passenger and driver apps listen to.
class ActiveTripModel extends Equatable {
  const ActiveTripModel({
    required this.requestId,
    this.driverId,
    this.driverName,
    this.driverProfilePicture,
    this.driverRating,
    this.driverLat,
    this.driverLng,
    this.driverBearing,
    this.driverMobile,
    this.userMobile,
    this.vehicleTypeIcon,
    this.vehicleNumber,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.transportType,
    this.tripArrived = false,
    this.tripStart = false,
    this.isCancelled = false,
    this.cancelledByUser = false,
    this.cancelledByDriver = false,
    this.isAccepted = false,
    this.isCompleted = false,
    this.isPaid = false,
    this.isUserPaid = false,
    this.isPaymentReceived = false,
    this.paymentMethod,
    this.driverTips,
    this.totalAmount = 0.0,
    this.currencyCode = 'IQD',
    this.tripDistance = 0.0,
    this.distance = 0.0,
    this.duration = 0.0,
    this.pickupDistance = 0.0,
    this.pickupDuration = 0.0,
    this.polyline,
    this.messageByDriver = 0,
    this.messageByUser = 0,
    this.waitingTimeBeforeStart = 0,
    this.waitingTimeAfterStart = 0,
    this.additionalChargesReason,
    this.additionalChargesAmount,
    this.modifiedByDriver,
    this.modifiedByUser,
    this.destinationChange,
    this.arrivedAt,
    this.enableShipmentLoad = false,
    this.enableShipmentUnload = false,
    this.enableDigitalSignature = false,
    this.stops = const [],
  });

  final String requestId;
  final int? driverId;
  final String? driverName;
  final String? driverProfilePicture;
  final String? driverRating;
  final double? driverLat;
  final double? driverLng;
  final double? driverBearing;
  final String? driverMobile;
  final String? userMobile;
  final String? vehicleTypeIcon;
  final String? vehicleNumber;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? transportType;

  /// Trip lifecycle flags
  final bool tripArrived;
  final bool tripStart;
  final bool isCancelled;
  final bool cancelledByUser;
  final bool cancelledByDriver;
  final bool isAccepted;

  /// Whether the trip has been completed by the driver.
  final bool isCompleted;

  /// Payment flags
  final bool isPaid;
  final bool isUserPaid;
  final bool isPaymentReceived;
  final String? paymentMethod;
  final String? driverTips;

  /// Fare amount from Firebase (request_eta_amount / total_amount).
  final double totalAmount;

  /// Currency code/symbol from Firebase.
  final String currencyCode;

  /// Distance & Duration
  final double tripDistance;
  final double distance;
  final double duration;
  final double pickupDistance;
  final double pickupDuration;
  final String? polyline;

  /// Chat message counts
  final int messageByDriver;
  final int messageByUser;

  /// Waiting time
  final int waitingTimeBeforeStart;
  final int waitingTimeAfterStart;

  /// Additional charges
  final String? additionalChargesReason;
  final String? additionalChargesAmount;

  /// Timestamps
  final int? modifiedByDriver;
  final int? modifiedByUser;
  final int? destinationChange;

  /// Epoch millis when the driver marked arrived (written to Firebase).
  final int? arrivedAt;

  /// Delivery feature flags
  final bool enableShipmentLoad;
  final bool enableShipmentUnload;
  final bool enableDigitalSignature;

  /// Intermediate trip stops / waypoints (ordered by [TripStopModel.order]).
  final List<TripStopModel> stops;

  /// Whether this is a delivery-type trip.
  bool get isDelivery => transportType == 'delivery';

  // ─── Convenience getters for UI ───
  /// Short alias for profile picture URL.
  String get driverProfilePic => driverProfilePicture ?? '';

  /// Rating parsed to double.
  double get driverRatingValue =>
      double.tryParse(driverRating ?? '') ?? 0.0;

  /// Combined vehicle name (make + model).
  String get vehicleTypeName =>
      [vehicleMake, vehicleModel].where((e) => e != null).join(' ').trim();

  /// Currency symbol for display.
  String get currencySymbol => currencyCode;

  /// Derived trip phase for UI rendering.
  TripPhase get phase {
    if (isCancelled || cancelledByUser || cancelledByDriver) {
      return TripPhase.cancelled;
    }
    // Trip completed: either paid or driver ended the ride.
    if (isPaid || isUserPaid || isPaymentReceived || isCompleted) {
      return TripPhase.completed;
    }
    if (tripStart) return TripPhase.inProgress;
    if (tripArrived) return TripPhase.driverArrived;
    if (isAccepted) return TripPhase.driverOnWay;
    return TripPhase.searching;
  }

  factory ActiveTripModel.fromFirebase(
    String requestId,
    Map<dynamic, dynamic> data,
  ) {
    return ActiveTripModel(
      requestId: requestId,
      driverId: _parseInt(data['driver_id']),
      driverName: data['driver_name']?.toString() ??
          data['name']?.toString(),
      driverProfilePicture: data['driver_profile_picture']?.toString() ??
          data['profile_picture']?.toString(),
      driverRating: data['driver_rating']?.toString() ??
          data['rating']?.toString(),
      driverLat: _parseDouble(data['lat']),
      driverLng: _parseDouble(data['lng']),
      driverBearing: _parseDouble(data['bearing']),
      driverMobile: data['driver_mobile']?.toString() ??
          data['mobile']?.toString(),
      userMobile: data['user_mobile']?.toString(),
      vehicleTypeIcon: data['vehicle_type_icon']?.toString(),
      vehicleNumber: data['vehicle_number']?.toString() ??
          data['car_number']?.toString() ??
          data['plate_number']?.toString(),
      vehicleMake: data['vehicle_make']?.toString() ??
          data['car_make']?.toString(),
      vehicleModel: data['vehicle_model']?.toString() ??
          data['car_model']?.toString(),
      vehicleColor: data['vehicle_color']?.toString() ??
          data['car_color']?.toString(),
      transportType: data['transport_type']?.toString(),
      tripArrived: _parseBool(data['trip_arrived']),
      tripStart: _parseBool(data['trip_start']),
      isCancelled: _parseBool(data['is_cancelled']),
      cancelledByUser: _parseBool(data['cancelled_by_user']),
      cancelledByDriver: _parseBool(data['cancelled_by_driver']),
      isAccepted: _parseBool(data['is_accept']),
      isCompleted: _parseBool(data['is_completed']),
      isPaid: _parseBool(data['is_paid']),
      isUserPaid: _parseBool(data['is_user_paid']),
      isPaymentReceived: _parseBool(data['is_payment_received']),
      paymentMethod: data['payment_method']?.toString() ??
          data['payment_opt']?.toString(),
      driverTips: data['driver_tips']?.toString(),
      totalAmount: _parseDouble(data['request_eta_amount']) ??
          _parseDouble(data['total_amount']) ??
          _parseDouble(data['estimated_fare']) ??
          0.0,
      currencyCode: data['requested_currency_symbol']?.toString() ??
          data['currency_symbol']?.toString() ??
          data['currency']?.toString() ??
          'IQD',
      tripDistance: _parseDouble(data['trip_distance']) ?? 0.0,
      distance: _parseDouble(data['distance']) ?? 0.0,
      duration: _parseDouble(data['duration']) ?? 0.0,
      pickupDistance: _parseDouble(data['pickup_distance']) ?? 0.0,
      pickupDuration: _parseDouble(data['pickup_duration']) ?? 0.0,
      polyline: data['polyline']?.toString(),
      messageByDriver: _parseInt(data['message_by_driver']) ?? 0,
      messageByUser: _parseInt(data['message_by_user']) ?? 0,
      waitingTimeBeforeStart:
          _parseInt(data['waiting_time_before_start']) ?? 0,
      waitingTimeAfterStart:
          _parseInt(data['waiting_time_after_start']) ?? 0,
      additionalChargesReason:
          data['additional_charges_reason']?.toString(),
      additionalChargesAmount:
          data['additional_charges_amount']?.toString(),
      modifiedByDriver: _parseInt(data['modified_by_driver']),
      modifiedByUser: _parseInt(data['modified_by_user']),
      destinationChange: _parseInt(data['destination_change']),
      arrivedAt: _parseInt(data['arrived_at']),
      enableShipmentLoad:
          data['enable_shipment_load_feature'] == '1' ||
              data['enable_shipment_load_feature'] == 1 ||
              data['enable_shipment_load_feature'] == true,
      enableShipmentUnload:
          data['enable_shipment_unload_feature'] == '1' ||
              data['enable_shipment_unload_feature'] == 1 ||
              data['enable_shipment_unload_feature'] == true,
      enableDigitalSignature:
          data['enable_digital_signature'] == '1' ||
              data['enable_digital_signature'] == 1 ||
              data['enable_digital_signature'] == true,
      stops: _parseStops(data['stops'] ?? data['stop_address_list']),
    );
  }

  /// Parse stops from Firebase — supports List or Map keyed by index.
  static List<TripStopModel> _parseStops(dynamic raw) {
    if (raw == null) return const [];
    final List<TripStopModel> result = [];
    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] is Map) {
          result.add(TripStopModel.fromMap(raw[i] as Map, fallbackOrder: i));
        }
      }
    } else if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result.add(TripStopModel.fromMap(value, fallbackOrder: int.tryParse(key.toString()) ?? 0));
        }
      });
    }
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  ActiveTripModel copyWith({
    int? driverId,
    String? driverName,
    String? driverProfilePicture,
    String? driverRating,
    double? driverLat,
    double? driverLng,
    double? driverBearing,
    String? driverMobile,
    String? vehicleNumber,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    bool? tripArrived,
    bool? tripStart,
    bool? isCancelled,
    bool? cancelledByUser,
    bool? cancelledByDriver,
    bool? isAccepted,
    bool? isPaid,
    bool? isUserPaid,
    bool? isPaymentReceived,
    String? paymentMethod,
    double? totalAmount,
    String? currencyCode,
    int? messageByDriver,
    int? messageByUser,
    double? tripDistance,
    double? distance,
    double? duration,
  }) {
    return ActiveTripModel(
      requestId: requestId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverProfilePicture:
          driverProfilePicture ?? this.driverProfilePicture,
      driverRating: driverRating ?? this.driverRating,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverBearing: driverBearing ?? this.driverBearing,
      driverMobile: driverMobile ?? this.driverMobile,
      userMobile: userMobile,
      vehicleTypeIcon: vehicleTypeIcon,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      transportType: transportType,
      tripArrived: tripArrived ?? this.tripArrived,
      tripStart: tripStart ?? this.tripStart,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledByUser: cancelledByUser ?? this.cancelledByUser,
      cancelledByDriver: cancelledByDriver ?? this.cancelledByDriver,
      isAccepted: isAccepted ?? this.isAccepted,
      isPaid: isPaid ?? this.isPaid,
      isUserPaid: isUserPaid ?? this.isUserPaid,
      isPaymentReceived: isPaymentReceived ?? this.isPaymentReceived,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      driverTips: driverTips,
      totalAmount: totalAmount ?? this.totalAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      tripDistance: tripDistance ?? this.tripDistance,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      pickupDistance: pickupDistance,
      pickupDuration: pickupDuration,
      polyline: polyline,
      messageByDriver: messageByDriver ?? this.messageByDriver,
      messageByUser: messageByUser ?? this.messageByUser,
      waitingTimeBeforeStart: waitingTimeBeforeStart,
      waitingTimeAfterStart: waitingTimeAfterStart,
      additionalChargesReason: additionalChargesReason,
      additionalChargesAmount: additionalChargesAmount,
      modifiedByDriver: modifiedByDriver,
      modifiedByUser: modifiedByUser,
      destinationChange: destinationChange,
      isCompleted: isCompleted,
      arrivedAt: arrivedAt,
      stops: stops,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  @override
  List<Object?> get props => [
        requestId,
        driverId,
        driverName,
        driverProfilePicture,
        driverRating,
        driverMobile,
        driverLat,
        driverLng,
        vehicleNumber,
        vehicleMake,
        vehicleModel,
        vehicleColor,
        tripArrived,
        tripStart,
        isCancelled,
        isAccepted,
        isPaid,
        isPaymentReceived,
        isCompleted,
        paymentMethod,
        messageByDriver,
        messageByUser,
        tripDistance,
        totalAmount,
        currencyCode,
        phase,
        enableShipmentLoad,
        enableShipmentUnload,
        enableDigitalSignature,
        stops,
      ];
}

/// Trip lifecycle phases derived from Firebase state flags.
enum TripPhase {
  /// Waiting for a driver to accept.
  searching,

  /// Driver accepted, on the way to pickup.
  driverOnWay,

  /// Driver arrived at pickup location.
  driverArrived,

  /// Trip is in progress.
  inProgress,

  /// Trip completed, awaiting payment/review.
  completed,

  /// Trip was cancelled.
  cancelled,
}
