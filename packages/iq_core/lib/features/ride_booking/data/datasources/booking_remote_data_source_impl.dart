import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/cancel_reason_model.dart';
import '../models/incoming_request_model.dart';
import '../models/invoice_model.dart';
import '../models/ride_request_response_model.dart';
import '../models/vehicle_type_model.dart';
import 'booking_remote_data_source.dart';

/// Dio implementation of [BookingRemoteDataSource].
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  // ─── Passenger APIs ───

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
    double? distance,
    double? duration,
    String? polyline,
    String? pickAddress,
    String? dropAddress,
  }) async {
    try {
      final requestData = {
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'ride_type': rideType,
          'transport_type': transportType,
          if (promoCode != null) 'promo_code': promoCode,
          // Distance-based fare — mirrors old app behaviour:
          // distance in METRES, duration in MINUTES.
          // Without these the server falls back to the minimum fare.
          if (distance != null) 'distance': distance.toStringAsFixed(0),
          if (duration != null) 'duration': duration.toStringAsFixed(0),
          if (polyline != null) 'polyline': polyline,
          if (pickAddress != null) 'pick_address': pickAddress,
          if (pickAddress != null)
            'pick_short_address': pickAddress.split(',')[0],
          if (dropAddress != null) 'drop_address': dropAddress,
          if (dropAddress != null)
            'drop_short_address': dropAddress.split(',')[0],
      };
      debugPrint('🚕 [RideETA] REQUEST: $requestData');
      final response = await dio.post(
        'api/v1/request/eta',
        data: FormData.fromMap(requestData),
      );
      final body = response.data as Map<String, dynamic>;
      debugPrint('🚕 [RideETA] RESPONSE: $body');
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeModel.fromJson)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToGetPrices,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideRequestResponseModel>> createRideRequest({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    required String pickAddress,
    required String dropAddress,
    required String vehicleType,
    required int paymentOpt,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
    String? polyline,
    double? requestEtaAmount,
    String? instructions,
    int isBidRide = 0,
    double? offerAmount,
    int isLater = 0,
    String? tripStartTime,
    List<Map<String, dynamic>>? selectedPreferences,
    String? distance,
    String? duration,
    String? promocodeId,
    double? discountedTotal,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/create',
        data: FormData.fromMap({
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'pick_address': pickAddress,
          'drop_address': dropAddress,
          'vehicle_type': vehicleType,
          'type_id': vehicleType,
          'payment_opt': paymentOpt,
          'ride_type': rideType,
          'transport_type': transportType,
          if (promocodeId != null) 'promocode_id': promocodeId,
          if (discountedTotal != null && discountedTotal > 0)
            'discounted_total': discountedTotal,
          if (polyline != null) 'poly_line': polyline,
          if (requestEtaAmount != null) 'request_eta_amount': requestEtaAmount,
          if (instructions != null) 'pickup_poc_instruction': instructions,
          'is_bid_ride': isBidRide,
          if (offerAmount != null) 'offer_amount': offerAmount,
          if (isLater == 1) 'is_later': 1,
          if (tripStartTime != null) 'trip_start_time': tripStartTime,
          if (selectedPreferences != null)
            'preferences': jsonEncode(selectedPreferences),
          if (distance != null) 'distance': distance,
          if (duration != null) 'duration': duration,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Right(RideRequestResponseModel.fromJson(body));
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToCreateRequest,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
    int? cancelMethod,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/cancel',
        data: FormData.fromMap({
          'request_id': requestId,
          'reason': reason,
          if (customReason != null) 'custom_reason': customReason,
          if (cancelMethod != null) 'cancel_method': cancelMethod,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToCancelRequest,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CancelReasonModel>>> getCancelReasons() async {
    try {
      final response = await dio.get('api/v1/common/cancallation/reasons');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CancelReasonModel.fromJson)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToFetchCancelReasons,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentSearches() async {
    try {
      final response = await dio.get('api/v1/request/list-recent-searches');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((item) {
          return {
            'pick_address': item['pick_address'],
            'pick_lat': item['pick_lat'],
            'pick_lng': item['pick_lng'],
            'drop_address': item['drop_address'],
            'drop_lat': item['drop_lat'],
            'drop_lng': item['drop_lng'],
          };
        }).toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToLoadRecentPlaces,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitRating({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/rating',
        data: FormData.fromMap({
          'request_id': requestId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToSubmitRating,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changeDropLocation({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String? polyline,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/change-drop-location',
        data: FormData.fromMap({
          'request_id': requestId,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'drop_address': dropAddress,
          if (polyline != null) 'poly_line': polyline,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? AppStrings.failedToChangeDropoff,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changePaymentMethod({
    required String requestId,
    required int paymentOpt,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/user/payment-method',
        data: FormData.fromMap({
          'request_id': requestId,
          'payment_opt': paymentOpt,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? AppStrings.failedToChangePayment,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvoiceModel>> getTripInvoice({
    required String requestId,
  }) async {
    try {
      // Use the specific request endpoint with requestBill include
      // for full fare breakdown data.
      final response = await dio.get(
        'api/v1/request/history/$requestId',
        queryParameters: {'include': 'driverDetail,userDetail,requestBill'},
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final tripData = body['data'] as Map<String, dynamic>? ?? {};
        debugPrint('📄 [Invoice] keys: ${tripData.keys.toList()}');

        // Merge requestBill into the trip data for InvoiceModel parsing
        final bill = tripData['requestBill'];
        if (bill is Map) {
          final billData = bill['data'] is Map ? bill['data'] as Map<String, dynamic> : bill as Map<String, dynamic>;
          debugPrint('📄 [Invoice] bill keys: ${billData.keys.toList()}');
          // Copy bill fields into tripData so fromJson picks them up
          for (final e in billData.entries) {
            if (tripData[e.key] == null || tripData[e.key] == 0 || tripData[e.key] == '0') {
              tripData[e.key] = e.value;
            }
          }
        }

        // Merge driverDetail into the trip data
        final driver = tripData['driverDetail'];
        if (driver is Map) {
          final driverData = driver['data'] is Map ? driver['data'] as Map<String, dynamic> : driver as Map<String, dynamic>;
          tripData['driver_detail'] = driverData;
        }

        // Merge userDetail into the trip data
        final user = tripData['userDetail'];
        if (user is Map) {
          final userData = user['data'] is Map ? user['data'] as Map<String, dynamic> : user as Map<String, dynamic>;
          tripData['user_detail'] = userData;
        }

        return Right(InvoiceModel.fromJson(tripData));
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? AppStrings.failedToFetchTripDetails,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Driver APIs ───

  @override
  Future<Either<Failure, bool>> respondToRequest({
    required String requestId,
    required bool isAccept,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/respond',
        data: FormData.fromMap({
          'request_id': requestId,
          'is_accept': isAccept ? 1 : 0,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToRespondToRequest,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markArrived({
    required String requestId,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/arrived',
        data: FormData.fromMap({'request_id': requestId}),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToConfirmArrival,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> startRide({
    required String requestId,
    required double pickLat,
    required double pickLng,
    String? otp,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/started',
        data: FormData.fromMap({
          'request_id': requestId,
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          if (otp != null) 'otp': otp,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToStartTrip,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> endRide({
    required String requestId,
    required double dropLat,
    required double dropLng,
    String dropAddress = '',
    String polyLine = '',
    required double distance,
    int beforeTripWaitingTime = 0,
    int afterTripWaitingTime = 0,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/end',
        data: FormData.fromMap({
          'request_id': requestId,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'drop_address': dropAddress,
          'distance': distance,
          'before_trip_start_waiting_time': beforeTripWaitingTime,
          'after_trip_start_waiting_time': afterTripWaitingTime,
          if (polyLine.isNotEmpty) 'poly_line': polyLine,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToEndTrip,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createRidePayment({
    required String requestId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/payment/qicard/create-payment',
        data: {
          'amount': amount,
          'request_id': requestId,
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final paymentUrl = data['payment_url']?.toString() ?? '';
        if (paymentUrl.isEmpty) {
          return const Left(
            ServerFailure(message: 'لم يتم استلام رابط الدفع'),
          );
        }
        return Right(paymentUrl);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.paymentFailed,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> confirmPayment({
    required String requestId,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/payment-confirm',
        data: FormData.fromMap({'request_id': requestId}),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToConfirmPayment,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelByDriver({
    required String requestId,
    required String reason,
    String? customReason,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/cancel/by-driver',
        data: FormData.fromMap({
          'request_id': requestId,
          'reason': reason,
          if (customReason != null) 'custom_reason': customReason,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToCancelTrip,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncomingRequestModel?>> fetchPendingRequest() async {
    try {
      final response = await dio.get('api/v1/user');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final metaRaw = data['metaRequest'];
        if (metaRaw == null) return const Right(null);
        final metaData =
            (metaRaw is Map ? metaRaw['data'] : null) as Map<String, dynamic>?;
        if (metaData == null) return const Right(null);
        return Right(IncomingRequestModel.fromApi(metaData));
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'Failed to fetch user details',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncomingRequestModel?>> fetchOnTripRequest() async {
    try {
      final response = await dio.get('api/v1/user');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final onTripRaw = data['onTripRequest'];
        if (onTripRaw == null) return const Right(null);
        final tripData =
            (onTripRaw is Map ? onTripRaw['data'] : null) as Map<String, dynamic>?;
        if (tripData == null) return const Right(null);
        return Right(IncomingRequestModel.fromApi(tripData));
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'Failed to fetch user details',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      fetchPassengerActiveTripDetails({required String requestId}) async {
    try {
      debugPrint('🔍 [TripAPI] GET api/v1/request/history/$requestId');
      final response = await dio.get(
        'api/v1/request/history/$requestId',
        queryParameters: {'include': 'driverDetail,requestBill'},
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        // The response wraps in { "data": { ... } }
        final tripData = body['data'] as Map<String, dynamic>? ?? {};
        
        // Log all driver-related keys
        final driverKeys = tripData.keys
            .where((k) => k.toLowerCase().contains('driver'))
            .toList();
        debugPrint('🔍 [TripAPI] driver-related keys: $driverKeys');
        for (final k in driverKeys) {
          debugPrint('🔍 [TripAPI] $k = ${tripData[k]}');
        }
        debugPrint('🔍 [TripAPI] raw driverDetail = ${tripData['driverDetail']}');
        debugPrint('🔍 [TripAPI] raw driver_detail = ${tripData['driver_detail']}');

        // Parse driverDetail — might be nested under 'data' or flat
        final driverDetailRaw =
            tripData['driverDetail'] ?? tripData['driver_detail'];
        Map<String, dynamic> driverDetail = {};
        if (driverDetailRaw is Map) {
          if (driverDetailRaw.containsKey('data') &&
              driverDetailRaw['data'] is Map) {
            driverDetail =
                Map<String, dynamic>.from(driverDetailRaw['data'] as Map);
          } else {
            driverDetail = Map<String, dynamic>.from(driverDetailRaw);
          }
        }
        debugPrint(
            '🔍 [TripAPI] driverDetail keys: ${driverDetail.keys.toList()}');
        debugPrint('🔍 [TripAPI] driverDetail name: ${driverDetail['name']}');

        // Parse requestBill — might be nested under 'data' or flat
        final requestBillRaw =
            tripData['requestBill'] ?? tripData['request_bill'];
        Map<String, dynamic> requestBill = {};
        if (requestBillRaw is Map) {
          if (requestBillRaw.containsKey('data') &&
              requestBillRaw['data'] is Map) {
            requestBill =
                Map<String, dynamic>.from(requestBillRaw['data'] as Map);
          } else {
            requestBill = Map<String, dynamic>.from(requestBillRaw);
          }
        }
        debugPrint(
            '🔍 [TripAPI] requestBill keys: ${requestBill.keys.toList()}');

        final enrichment = <String, dynamic>{
          // Driver info from driverDetail or flat tripData
          'driver_name': driverDetail['name'] ??
              tripData['driver_name'] ??
              tripData['driverName'],
          'driver_profile_picture': driverDetail['profile_picture'] ??
              driverDetail['profilePicture'] ??
              tripData['driver_profile_picture'] ??
              tripData['driverProfilePicture'],
          'driver_rating': (driverDetail['rating'] ??
                  tripData['driver_rating'] ??
                  tripData['driverRating'])
              ?.toString(),
          'driver_mobile': driverDetail['mobile'] ??
              driverDetail['phone'] ??
              tripData['driver_mobile'] ??
              tripData['driverMobile'],
          'driver_id': driverDetail['id'] ??
              tripData['driver_id'] ??
              tripData['driverId'],
          // Vehicle info
          'vehicle_number': driverDetail['car_number'] ??
              tripData['car_number'] ??
              tripData['vehicle_number'],
          'vehicle_make': driverDetail['car_make_name'] ??
              tripData['car_make_name'] ??
              tripData['vehicle_make'],
          'vehicle_model': driverDetail['car_model_name'] ??
              tripData['car_model_name'] ??
              tripData['vehicle_model'],
          'vehicle_color': driverDetail['car_color'] ??
              tripData['car_color'] ??
              tripData['vehicle_color'],
          // Fare from trip level or bill
          'total_amount': tripData['request_eta_amount'] ??
              tripData['accepted_ride_fare'] ??
              tripData['total_amount'] ??
              requestBill['total_amount'] ??
              requestBill['base_price'],
          // Payment & currency
          'payment_method': tripData['payment_opt']?.toString() ??
              tripData['payment_method']?.toString(),
          'currency_code': tripData['requested_currency_symbol'] ??
              requestBill['requested_currency_symbol'] ??
              'IQD',
        };

        debugPrint('✅ [TripAPI] Final enrichment: $enrichment');

        return Right(enrichment);
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? 'Failed to fetch trip details',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Delivery / Shipment APIs ───

  @override
  Future<Either<Failure, bool>> uploadShipmentProof({
    required String requestId,
    required String imagePath,
    required bool isBefore,
  }) async {
    try {
      final formData = FormData.fromMap({
        'request_id': requestId,
        if (isBefore) 'before_load': 1,
        if (!isBefore) 'after_load': 1,
      });

      formData.files.add(MapEntry(
        'proof_image',
        await MultipartFile.fromFile(imagePath),
      ));

      final response = await dio.post(
        'api/v1/request/upload-proof',
        data: formData,
      );
      final body = response.data;
      return Right(body['success'] == true || body['success'] == 1);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(message: AppStrings.connectionTimeout);
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure(message: AppStrings.noInternetConnection);
    }
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final message = body is Map ? body['message']?.toString() : null;

    if (statusCode == 401) {
      return AuthFailure(message: message ?? AppStrings.unauthorized);
    }
    if (statusCode == 422) {
      return ValidationFailure(message: message ?? AppStrings.invalidData);
    }
    return ServerFailure(message: message ?? AppStrings.serverError);
  }
}
