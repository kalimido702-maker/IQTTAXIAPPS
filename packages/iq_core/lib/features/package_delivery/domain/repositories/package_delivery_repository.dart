import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/goods_type_model.dart';
import '../../data/models/parcel_request_model.dart';
import '../../../ride_booking/data/models/ride_request_response_model.dart';
import '../../../ride_booking/data/models/vehicle_type_model.dart';

/// Repository contract for the package delivery feature.
abstract class PackageDeliveryRepository {
  /// Fetch goods types from the API.
  Future<Either<Failure, List<GoodsTypeModel>>> getGoodsTypes();

  /// Fetch ETA / vehicle types for a delivery trip.
  Future<Either<Failure, List<VehicleTypeModel>>> getDeliveryEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    String? promoCode,
  });

  /// Create a delivery request.
  Future<Either<Failure, RideRequestResponseModel>> createDeliveryRequest({
    required ParcelRequestModel request,
  });
}
