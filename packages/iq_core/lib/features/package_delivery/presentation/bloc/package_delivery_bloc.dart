import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../ride_booking/data/models/vehicle_type_model.dart';
import '../../data/models/goods_type_model.dart';
import '../../domain/repositories/package_delivery_repository.dart';
import 'package_delivery_event.dart';
import 'package_delivery_state.dart';

/// Manages the package delivery flow:
/// landing → addresses → recipient → booking confirmation → create request.
class PackageDeliveryBloc
    extends Bloc<PackageDeliveryEvent, PackageDeliveryState> {
  PackageDeliveryBloc({required this.repository})
      : super(const PackageDeliveryState()) {
    on<PackageDeliveryModeSelected>(_onModeSelected);
    on<PackageDeliveryAddressesConfirmed>(_onAddressesConfirmed);
    on<PackageDeliveryRecipientConfirmed>(_onRecipientConfirmed);
    on<PackageDeliveryGoodsTypesRequested>(_onGoodsTypesRequested);
    on<PackageDeliveryGoodsTypeSelected>(_onGoodsTypeSelected);
    on<PackageDeliveryPaidByChanged>(_onPaidByChanged);
    on<PackageDeliveryPaymentChanged>(_onPaymentChanged);
    on<PackageDeliveryVehicleSelected>(_onVehicleSelected);
    on<PackageDeliveryPromoApplied>(_onPromoApplied);
    on<PackageDeliveryCreateRequested>(_onCreateRequested);
    on<PackageDeliveryReset>(_onReset);
  }

  final PackageDeliveryRepository repository;

  void _onModeSelected(
    PackageDeliveryModeSelected event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(state.copyWith(
      status: PackageDeliveryStatus.enteringRecipient,
      parcelRequest: state.parcelRequest.copyWith(parcelType: event.parcelType),
    ));
  }

  void _onAddressesConfirmed(
    PackageDeliveryAddressesConfirmed event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(state.copyWith(
      status: PackageDeliveryStatus.selectingMode,
      parcelRequest: state.parcelRequest.copyWith(
        pickLat: event.pickLat,
        pickLng: event.pickLng,
        dropLat: event.dropLat,
        dropLng: event.dropLng,
        pickAddress: event.pickAddress,
        dropAddress: event.dropAddress,
      ),
    ));
  }

  /// After recipient info is confirmed → fetch ETA + goods types in parallel.
  Future<void> _onRecipientConfirmed(
    PackageDeliveryRecipientConfirmed event,
    Emitter<PackageDeliveryState> emit,
  ) async {
    final updatedRequest = state.parcelRequest.copyWith(
      recipientName: event.name,
      recipientMobile: event.mobile,
      instructions: event.instructions,
      receiveSelf: event.receiveSelf,
    );

    emit(state.copyWith(
      status: PackageDeliveryStatus.loadingBooking,
      parcelRequest: updatedRequest,
    ));

    // Fetch ETA and goods types in parallel.
    final results = await Future.wait([
      repository.getDeliveryEta(
        pickLat: updatedRequest.pickLat,
        pickLng: updatedRequest.pickLng,
        dropLat: updatedRequest.dropLat,
        dropLng: updatedRequest.dropLng,
      ),
      repository.getGoodsTypes(),
    ]);

    final etaResult = results[0];
    final goodsResult = results[1];

    // Check ETA result.
    if (etaResult.isLeft()) {
      final err = etaResult.fold((l) => l.message, (_) => '');
      emit(state.copyWith(
        status: PackageDeliveryStatus.error,
        errorMessage: err,
      ));
      return;
    }

    final vehicleTypes =
        etaResult.fold((_) => <VehicleTypeModel>[], (r) => r as List<VehicleTypeModel>);

    // Goods types — non-critical; continue even if it fails.
    final goodsTypes = goodsResult.fold(
      (failure) {
        debugPrint('⚠️ PackageDeliveryBloc: getGoodsTypes failed: ${failure.message}');
        return <GoodsTypeModel>[];
      },
      (r) => r as List<GoodsTypeModel>,
    );

    if (vehicleTypes.isEmpty) {
      emit(state.copyWith(
        status: PackageDeliveryStatus.error,
        errorMessage: AppStrings.noVehiclesAvailable,
      ));
      return;
    }

    // Auto-select the first vehicle and set its fare.
    final firstVehicle = vehicleTypes.first;
    debugPrint('📦 [DeliveryBLoC] Coords sent: '
        'pick(${updatedRequest.pickLat}, ${updatedRequest.pickLng}) '
        'drop(${updatedRequest.dropLat}, ${updatedRequest.dropLng})');
    debugPrint('📦 [DeliveryBLoC] Vehicles: ${vehicleTypes.map((v) => '${v.name}: ${v.total} ${v.currencySymbol}').toList()}');
    emit(state.copyWith(
      status: PackageDeliveryStatus.bookingReady,
      vehicleTypes: vehicleTypes,
      selectedVehicleIndex: 0,
      goodsTypes: goodsTypes,
      parcelRequest: updatedRequest.copyWith(
        vehicleType: firstVehicle.typeId,
        requestEtaAmount: firstVehicle.total,
      ),
    ));
  }

  Future<void> _onGoodsTypesRequested(
    PackageDeliveryGoodsTypesRequested event,
    Emitter<PackageDeliveryState> emit,
  ) async {
    if (state.goodsTypes.isNotEmpty) {
      // Already loaded.
      emit(state.copyWith(status: PackageDeliveryStatus.selectingGoodsType));
      return;
    }

    final result = await repository.getGoodsTypes();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (goods) => emit(state.copyWith(
        status: PackageDeliveryStatus.selectingGoodsType,
        goodsTypes: goods,
      )),
    );
  }

  void _onGoodsTypeSelected(
    PackageDeliveryGoodsTypeSelected event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(state.copyWith(
      status: PackageDeliveryStatus.bookingReady,
      parcelRequest: state.parcelRequest.copyWith(
        goodsTypeId: event.goodsTypeId,
        goodsTypeName: event.goodsTypeName,
        goodsQuantity: event.quantity,
      ),
    ));
  }

  void _onPaidByChanged(
    PackageDeliveryPaidByChanged event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(state.copyWith(
      parcelRequest: state.parcelRequest.copyWith(paidBy: event.paidBy),
    ));
  }

  void _onPaymentChanged(
    PackageDeliveryPaymentChanged event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(state.copyWith(
      parcelRequest:
          state.parcelRequest.copyWith(paymentOpt: event.paymentOpt),
    ));
  }

  void _onVehicleSelected(
    PackageDeliveryVehicleSelected event,
    Emitter<PackageDeliveryState> emit,
  ) {
    final vehicle = state.vehicleTypes[event.vehicleIndex];
    emit(state.copyWith(
      selectedVehicleIndex: event.vehicleIndex,
      parcelRequest: state.parcelRequest.copyWith(
        vehicleType: vehicle.typeId,
        requestEtaAmount: vehicle.total,
      ),
    ));
  }

  Future<void> _onPromoApplied(
    PackageDeliveryPromoApplied event,
    Emitter<PackageDeliveryState> emit,
  ) async {
    final promo = event.promoCode;

    // If user clears the promo code, just remove it and re-fetch without promo.
    if (promo == null || promo.isEmpty) {
      emit(state.copyWith(
        status: PackageDeliveryStatus.validatingPromo,
        parcelRequest: state.parcelRequest.copyWith(promoCode: null),
      ));

      final result = await repository.getDeliveryEta(
        pickLat: state.parcelRequest.pickLat,
        pickLng: state.parcelRequest.pickLng,
        dropLat: state.parcelRequest.dropLat,
        dropLng: state.parcelRequest.dropLng,
      );

      result.fold(
        (failure) => emit(state.copyWith(
          status: PackageDeliveryStatus.bookingReady,
        )),
        (vehicles) {
          if (vehicles.isNotEmpty) {
            final idx = state.selectedVehicleIndex < vehicles.length
                ? state.selectedVehicleIndex
                : 0;
            emit(state.copyWith(
              status: PackageDeliveryStatus.bookingReady,
              vehicleTypes: vehicles,
              selectedVehicleIndex: idx,
              parcelRequest: state.parcelRequest.copyWith(
                promoCode: null,
                vehicleType: vehicles[idx].typeId,
                requestEtaAmount: vehicles[idx].total,
              ),
            ));
          } else {
            emit(state.copyWith(
              status: PackageDeliveryStatus.bookingReady,
            ));
          }
        },
      );
      return;
    }

    // Validate promo by re-fetching ETA with the code.
    emit(state.copyWith(status: PackageDeliveryStatus.validatingPromo));

    final result = await repository.getDeliveryEta(
      pickLat: state.parcelRequest.pickLat,
      pickLng: state.parcelRequest.pickLng,
      dropLat: state.parcelRequest.dropLat,
      dropLng: state.parcelRequest.dropLng,
      promoCode: promo,
    );

    result.fold(
      (failure) {
        // Promo invalid — show error and keep old prices.
        emit(state.copyWith(
          status: PackageDeliveryStatus.error,
          errorMessage: failure.message.isNotEmpty
              ? failure.message
              : AppStrings.invalidPromoCode,
        ));
        // Revert to bookingReady so the page stays usable.
        emit(state.copyWith(status: PackageDeliveryStatus.bookingReady));
      },
      (vehicles) {
        if (vehicles.isNotEmpty) {
          final idx = state.selectedVehicleIndex < vehicles.length
              ? state.selectedVehicleIndex
              : 0;
          emit(state.copyWith(
            status: PackageDeliveryStatus.promoApplied,
            vehicleTypes: vehicles,
            selectedVehicleIndex: idx,
            parcelRequest: state.parcelRequest.copyWith(
              promoCode: promo,
              vehicleType: vehicles[idx].typeId,
              requestEtaAmount: vehicles[idx].total,
            ),
          ));
        } else {
          emit(state.copyWith(
            status: PackageDeliveryStatus.error,
            errorMessage: AppStrings.invalidPromoCode,
          ));
          emit(state.copyWith(status: PackageDeliveryStatus.bookingReady));
        }
      },
    );
  }

  Future<void> _onCreateRequested(
    PackageDeliveryCreateRequested event,
    Emitter<PackageDeliveryState> emit,
  ) async {
    emit(state.copyWith(status: PackageDeliveryStatus.creatingRequest));

    final result = await repository.createDeliveryRequest(
      request: state.parcelRequest,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PackageDeliveryStatus.error,
          errorMessage: failure.message,
        ));
        // Revert to bookingReady so the page stays usable.
        emit(state.copyWith(status: PackageDeliveryStatus.bookingReady));
      },
      (response) => emit(state.copyWith(
        status: PackageDeliveryStatus.requestCreated,
        requestId: response.requestId,
      )),
    );
  }

  void _onReset(
    PackageDeliveryReset event,
    Emitter<PackageDeliveryState> emit,
  ) {
    emit(const PackageDeliveryState());
  }
}
