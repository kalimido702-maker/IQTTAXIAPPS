import 'package:equatable/equatable.dart';

/// A ride module / service category from `GET api/v1/common/ride_modules`.
///
/// Each module represents a service type (Taxi, Delivery, etc.) with
/// its icon URL from the backend.
class RideModuleModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final bool enabled;

  /// `"taxi"` or `"delivery"` — determines the transport mode.
  final String transportType;

  /// `"normal"`, `"rental"`, or `"outstation"`.
  final String serviceType;

  const RideModuleModel({
    required this.id,
    required this.name,
    this.icon,
    this.enabled = true,
    this.transportType = 'taxi',
    this.serviceType = 'normal',
  });

  /// Whether this module represents a delivery/parcel service.
  bool get isDelivery => transportType == 'delivery';

  factory RideModuleModel.fromJson(Map<String, dynamic> json) {
    return RideModuleModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['menu_icon'] ?? json['icon']) as String?,
      // API may omit `enabled`; treat absent as true (module is active).
      enabled: json.containsKey('enabled')
          ? (json['enabled'] == true || json['enabled'] == 1)
          : true,
      transportType: (json['transport_type'] ?? 'taxi').toString(),
      serviceType: (json['service_type'] ?? 'normal').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, icon, enabled, transportType, serviceType];
}
