import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/package_delivery_data_source.dart';
import '../../data/models/goods_type_model.dart';
import '../../data/models/parcel_request_model.dart';
import '../../domain/repositories/package_delivery_repository.dart';
import '../../../ride_booking/data/models/ride_request_response_model.dart';
import '../../../ride_booking/data/models/vehicle_type_model.dart';

/// Thin delegate forwarding all calls to [PackageDeliveryDataSource].
class PackageDeliveryRepositoryImpl implements PackageDeliveryRepository {
  const PackageDeliveryRepositoryImpl({required this.dataSource});

  final PackageDeliveryDataSource dataSource;

  @override
  Future<Either<Failure, List<GoodsTypeModel>>> getGoodsTypes() =>
      dataSource.getGoodsTypes();

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getDeliveryEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    String? promoCode,
  }) =>
      dataSource.getDeliveryEta(
        pickLat: pickLat,
        pickLng: pickLng,
        dropLat: dropLat,
        dropLng: dropLng,
        promoCode: promoCode,
      );

  @override
  Future<Either<Failure, RideRequestResponseModel>> createDeliveryRequest({
    required ParcelRequestModel request,
  }) =>
      dataSource.createDeliveryRequest(request: request);
}
