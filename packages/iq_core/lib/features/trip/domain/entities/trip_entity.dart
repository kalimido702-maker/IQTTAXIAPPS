import 'package:equatable/equatable.dart';

/// Trip status enum matching backend flags
enum TripStatus { completed, cancelled, upcoming, unknown }

/// Nested driver info for trip detail
class DriverInfo extends Equatable {
  final String name;
  final String? profilePicture;
  final double rating;
  final int noOfRatings;
  final String? carMakeName;
  final String? carModelName;
  final String? carColor;
  final String? carNumber;

  const DriverInfo({
    required this.name,
    this.profilePicture,
    this.rating = 0,
    this.noOfRatings = 0,
    this.carMakeName,
    this.carModelName,
    this.carColor,
    this.carNumber,
  });

  @override
  List<Object?> get props => [name, rating, carMakeName, carNumber];
}

/// Nested fare breakdown
class FareBreakdown extends Equatable {
  final double basePrice;
  final double baseDistance;
  final double distancePrice;
  final double timePrice;
  final double waitingCharge;
  final double serviceTax;
  final double serviceTaxPercentage;
  final double promoDiscount;
  final double totalAmount;
  final double cancellationFee;
  final double driverTips;

  const FareBreakdown({
    this.basePrice = 0,
    this.baseDistance = 0,
    this.distancePrice = 0,
    this.timePrice = 0,
    this.waitingCharge = 0,
    this.serviceTax = 0,
    this.serviceTaxPercentage = 0,
    this.promoDiscount = 0,
    this.totalAmount = 0,
    this.cancellationFee = 0,
    this.driverTips = 0,
  });

  @override
  List<Object?> get props => [totalAmount, basePrice, distancePrice];
}

/// Trip entity - core domain model
class TripEntity extends Equatable {
  final String id;
  final String? requestNumber;
  final String? userId;
  final String? driverId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final TripStatus status;
  final String vehicleTypeName; // تاكسي, مندوب
  final String? transportType; // taxi, delivery
  final double? totalDistance;
  final int? totalTime; // in minutes
  final String? unit; // km / mi
  final String? currencyCode;
  final String? currencySymbol;
  final String paymentMethod;
  final double? userRating;
  final String? polyLine;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Nested objects
  final DriverInfo? driverInfo;
  final FareBreakdown? fareBreakdown;

  const TripEntity({
    required this.id,
    this.requestNumber,
    this.userId,
    this.driverId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.status,
    this.vehicleTypeName = 'تاكسي',
    this.transportType,
    this.totalDistance,
    this.totalTime,
    this.unit = 'km',
    this.currencyCode = 'IQD',
    this.currencySymbol = 'IQD',
    this.paymentMethod = 'cash',
    this.userRating,
    this.polyLine,
    required this.createdAt,
    this.completedAt,
    this.driverInfo,
    this.fareBreakdown,
  });

  /// Whether this is a taxi ride
  bool get isTaxi =>
      transportType == 'taxi' ||
      vehicleTypeName.contains('تاكسي') ||
      vehicleTypeName.toLowerCase().contains('taxi');

  /// Formatted total amount for display
  String get formattedTotal {
    final amount = fareBreakdown?.totalAmount ?? 0;
    final formatted = amount.toStringAsFixed(0);
    // Add thousands separator
    final buffer = StringBuffer();
    final chars = formatted.split('');
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return '$currencySymbol $buffer';
  }

  @override
  List<Object?> get props => [id, status, requestNumber];
}
