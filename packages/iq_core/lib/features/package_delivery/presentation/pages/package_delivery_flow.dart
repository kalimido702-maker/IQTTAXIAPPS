import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../ride_booking/presentation/bloc/passenger/passenger_trip_bloc.dart';
import '../../../ride_booking/presentation/bloc/passenger/passenger_trip_event.dart';
import '../../../ride_booking/presentation/pages/passenger/passenger_active_trip_page.dart';
import '../bloc/package_delivery_bloc.dart';
import 'parcel_address_page.dart';
import 'parcel_booking_page.dart';
import 'parcel_landing_page.dart';
import 'parcel_recipient_page.dart';

/// Entry-point widget for the entire package delivery flow.
///
/// Wraps a [PackageDeliveryBloc] in a [BlocProvider] so all child pages
/// share the same bloc instance. Each step pushes the next route.
///
/// Flow order (matches Figma):
///   1. Address selection  (Figma 7:4013)
///   2. Landing / mode     (Figma 7:1472) — send or receive
///   3. Recipient details
///   4. Booking confirmation
class PackageDeliveryFlow extends StatelessWidget {
  const PackageDeliveryFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PackageDeliveryBloc>(),
      child: const _AddressStep(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Step 1 — Address selection (Figma 7:4013)
// ─────────────────────────────────────────────────────────────────

class _AddressStep extends StatefulWidget {
  const _AddressStep();

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> {
  double? _lat;
  double? _lng;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }

      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );

      _lat = pos.latitude;
      _lng = pos.longitude;

      try {
        final result = await sl<LocationRepository>()
            .getAddressFromCoordinates(latitude: _lat!, longitude: _lng!);
        result.fold((_) {}, (addr) => _address = addr);
      } catch (_) {}

      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParcelAddressPage(
      initialPickupAddress: _address.isNotEmpty ? _address : null,
      initialPickupLat: _lat,
      initialPickupLng: _lng,
      onAddressesConfirmed: () => _pushLandingPage(context),
    );
  }

  void _pushLandingPage(BuildContext ctx) {
    final bloc = ctx.read<PackageDeliveryBloc>();
    final req = bloc.state.parcelRequest;

    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _LandingStep(
            initialLat: req.pickLat != 0 ? req.pickLat : _lat,
            initialLng: req.pickLng != 0 ? req.pickLng : _lng,
            dropoffLat: req.dropLat != 0 ? req.dropLat : null,
            dropoffLng: req.dropLng != 0 ? req.dropLng : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Step 2 — Landing / mode selection (Figma 7:1472)
// ─────────────────────────────────────────────────────────────────

class _LandingStep extends StatelessWidget {
  const _LandingStep({
    this.initialLat,
    this.initialLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  final double? initialLat;
  final double? initialLng;
  final double? dropoffLat;
  final double? dropoffLng;

  @override
  Widget build(BuildContext context) {
    return ParcelLandingPage(
      initialLat: initialLat,
      initialLng: initialLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      onSendTapped: () => _pushRecipientStep(context),
      onReceiveTapped: () => _pushRecipientStep(context),
    );
  }

  void _pushRecipientStep(BuildContext ctx) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: ctx.read<PackageDeliveryBloc>(),
          child: const _RecipientStep(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Step 3 — Recipient
// ─────────────────────────────────────────────────────────────────

class _RecipientStep extends StatelessWidget {
  const _RecipientStep();

  @override
  Widget build(BuildContext context) {
    return ParcelRecipientPage(
      onConfirmed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<PackageDeliveryBloc>(),
              child: const _BookingStep(),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Step 4 — Booking
// ─────────────────────────────────────────────────────────────────

class _BookingStep extends StatelessWidget {
  const _BookingStep();

  @override
  Widget build(BuildContext context) {
    return ParcelBookingPage(
      onRequestCreated: (requestId) {
        final deliveryBloc = context.read<PackageDeliveryBloc>();
        final req = deliveryBloc.state.parcelRequest;

        // Hand off to the PassengerTripBloc so it starts listening
        // on Firebase for driver acceptance / trip updates — exactly
        // the same flow as regular rides.
        sl<PassengerTripBloc>().add(
          PassengerTripRestoreOngoing(
            requestId: requestId,
            pickAddress: req.pickAddress,
            dropAddress: req.dropAddress,
            pickLat: req.pickLat,
            pickLng: req.pickLng,
            dropLat: req.dropLat,
            dropLng: req.dropLng,
          ),
        );

        // Pop the entire delivery flow and push the active trip page.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PassengerActiveTripPage(),
          ),
          (route) => route.isFirst,
        );
      },
    );
  }
}
