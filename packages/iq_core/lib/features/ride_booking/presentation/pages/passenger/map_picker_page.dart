import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_app_bar.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../location/domain/repositories/location_repository.dart';

class MapPickResult {
  const MapPickResult({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;
}

/// Full-screen map picker used by "اختر من الخريطة".
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  final double initialLat;
  final double initialLng;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _mapKey = GlobalKey<IqMapViewState>();
  late LatLng _target;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _target = LatLng(widget.initialLat, widget.initialLng);
  }

  Future<void> _confirm() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    final repo = sl<LocationRepository>();
    final result = await repo.getAddressFromCoordinates(
      latitude: _target.latitude,
      longitude: _target.longitude,
    );

    if (!mounted) return;
    result.fold(
      (_) {
        setState(() => _isResolving = false);
      },
      (address) {
        Navigator.of(context).pop(
          MapPickResult(
            address: address,
            lat: _target.latitude,
            lng: _target.longitude,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const IqAppBar(title: 'حدد الموقع'),
      body: Stack(
        children: [
          Positioned.fill(
            child: IqMapView(
              key: _mapKey,
              initialTarget: _target,
              myLocationButtonEnabled: false,
              onCameraMove: (pos) => _target = pos.target,
            ),
          ),
          // Center pin
          Center(
            child: Icon(
              Icons.location_pin,
              color: AppColors.markerRed,
              size: 44.w,
            ),
          ),
          // Confirm button
          Positioned(
            left: AppDimens.screenPaddingH,
            right: AppDimens.screenPaddingH,
            bottom: AppDimens.paddingLG,
            child: IqPrimaryButton(
              text: _isResolving ? 'جارٍ التحديد...' : 'تأكيد الموقع',
              onPressed: _isResolving ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}
