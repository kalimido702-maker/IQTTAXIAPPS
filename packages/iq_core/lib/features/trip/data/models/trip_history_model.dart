import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/trip_entity.dart';

/// Response wrapper for `GET api/v1/request/history`
class TripHistoryResponse {
  final List<TripEntity> trips;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const TripHistoryResponse({
    required this.trips,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  factory TripHistoryResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>?;
    final pagination = meta?['pagination'] as Map<String, dynamic>?;

    final currentPage = pagination?['current_page'] as int? ?? 1;
    final totalPages = pagination?['total_pages'] as int? ?? 1;

    final trips = dataList.map((item) {
      return TripHistoryModel.fromJson(item as Map<String, dynamic>);
    }).toList();

    return TripHistoryResponse(
      trips: trips,
      currentPage: currentPage,
      totalPages: totalPages,
      hasMore: currentPage < totalPages,
    );
  }
}

/// Parses a single trip from the backend `HistoryData` JSON.
///
/// Backend returns a massive object with ~120+ fields; we extract
/// only what the UI needs.
class TripHistoryModel {
  TripHistoryModel._();

  static TripEntity fromJson(Map<String, dynamic> json) {
    // ── Status ──
    // Priority: cancelled > completed > upcoming.
    // The backend may return both is_completed AND is_cancelled as true
    // (e.g. a trip that started but was later cancelled). In that case
    // we must show it as cancelled.
    final isCompleted = _toBool(json['is_completed']);
    final isCancelled = _toBool(json['is_cancelled']);
    final isLater = _toBool(json['is_later']);
    final isTripStart = _toBool(json['is_trip_start']);

    TripStatus status;
    if (isCancelled) {
      status = TripStatus.cancelled;
    } else if (isCompleted) {
      status = TripStatus.completed;
    } else if (isLater || !isTripStart) {
      status = TripStatus.upcoming;
    } else {
      status = TripStatus.unknown;
    }

    // ── Driver Info ──
    // The API may wrap driver data inside `driverDetail.data`, or it may
    // place car/driver fields directly at the top-level of the trip JSON.
    // We try the nested object first, then fall back to top-level fields.
    DriverInfo? driverInfo;
    final driverDetail = json['driverDetail'] as Map<String, dynamic>?;
    final driverData =
        driverDetail?['data'] as Map<String, dynamic>? ?? driverDetail;

    if (driverData != null && driverData.isNotEmpty) {
      // Nested driverDetail present
      driverInfo = DriverInfo(
        name: (driverData['name'] ?? '').toString(),
        profilePicture: driverData['profile_picture']?.toString(),
        rating: _toDouble(driverData['rating']),
        noOfRatings: _toInt(driverData['no_of_ratings']),
        carMakeName: driverData['car_make_name']?.toString(),
        carModelName: driverData['car_model_name']?.toString(),
        carColor: driverData['car_color']?.toString(),
        carNumber: driverData['car_number']?.toString(),
      );
    } else {
      // Fallback: car info lives at the top level of the trip object
      final carMake = json['car_make_name']?.toString();
      final carNumber = json['car_number']?.toString();
      if ((carMake != null && carMake.isNotEmpty) ||
          (carNumber != null && carNumber.isNotEmpty)) {
        driverInfo = DriverInfo(
          name: (json['driver_name'] ?? '').toString(),
          profilePicture: json['driver_profile_picture']?.toString(),
          rating: _toDouble(json['ride_driver_rating']),
          noOfRatings: _toInt(json['no_of_ratings']),
          carMakeName: carMake,
          carModelName: json['car_model_name']?.toString(),
          carColor: json['car_color']?.toString(),
          carNumber: carNumber,
        );
      }
    }

    // ── Fare Breakdown ──
    FareBreakdown? fareBreakdown;
    final requestBill = json['requestBill'] as Map<String, dynamic>?;
    final billData =
        requestBill?['data'] as Map<String, dynamic>? ?? requestBill;
    if (billData != null && billData.isNotEmpty) {
      fareBreakdown = FareBreakdown(
        basePrice: _toDouble(billData['base_price']),
        baseDistance: _toDouble(billData['base_distance']),
        distancePrice: _toDouble(billData['distance_price']),
        timePrice: _toDouble(billData['time_price']),
        waitingCharge: _toDouble(billData['waiting_charge']),
        serviceTax: _toDouble(billData['service_tax']),
        serviceTaxPercentage: _toDouble(billData['service_tax_percentage']),
        promoDiscount: _toDouble(billData['promo_discount']),
        totalAmount: _toDouble(billData['total_amount']),
        cancellationFee: _toDouble(billData['cancellation_fee']),
        driverTips: _toDouble(billData['driver_tips']),
      );
    }

    // ── Fallback total from top-level fields ──
    if (fareBreakdown == null) {
      final topAmount = _toDouble(json['accepted_ride_fare']) > 0
          ? _toDouble(json['accepted_ride_fare'])
          : _toDouble(json['request_eta_amount']);
      if (topAmount > 0) {
        fareBreakdown = FareBreakdown(totalAmount: topAmount);
      }
    }

    return TripEntity(
      id: (json['id'] ?? '').toString(),
      requestNumber: json['request_number']?.toString(),
      userId: json['user_id']?.toString(),
      driverId: json['driver_id']?.toString(),
      pickupAddress: (json['pick_address'] ?? '').toString(),
      pickupLat: _toDouble(json['pick_lat']),
      pickupLng: _toDouble(json['pick_lng']),
      dropoffAddress: (json['drop_address'] ?? '').toString(),
      dropoffLat: _toDouble(json['drop_lat']),
      dropoffLng: _toDouble(json['drop_lng']),
      status: status,
      vehicleTypeName: (json['vehicle_type_name'] ?? AppStrings.defaultVehicleType).toString(),
      transportType: json['transport_type']?.toString(),
      totalDistance: _toDouble(json['total_distance']),
      totalTime: _toInt(json['total_time']),
      unit: (json['unit'] ?? 'km').toString(),
      currencyCode:
          (json['requested_currency_code'] ?? 'IQD').toString(),
      currencySymbol:
          (json['requested_currency_symbol'] ?? 'IQD').toString(),
      paymentMethod: (json['payment_opt'] ?? 'cash').toString(),
      userRating: _toDouble(json['user_rating'] ?? json['ride_user_rating']),
      polyLine: json['poly_line']?.toString(),
      createdAt: _parseDate(json['cv_created_at'] ?? json['created_at']),
      completedAt: json['cv_completed_at'] != null
          ? _tryParseDate(json['cv_completed_at'].toString())
          : null,
      driverInfo: driverInfo,
      fareBreakdown: fareBreakdown,
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

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return _tryParseDate(value.toString()) ?? DateTime.now();
  }

  static DateTime? _tryParseDate(String value) {
    return DateTime.tryParse(value);
  }
}
