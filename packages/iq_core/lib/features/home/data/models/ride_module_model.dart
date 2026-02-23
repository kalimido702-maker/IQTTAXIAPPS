import 'package:equatable/equatable.dart';

/// A ride module / service category from `GET api/v1/common/ride_modules`.
///
/// Each module represents a service type (Taxi, Delivery, etc.) with
/// its icon URL from the backend.
class RideModuleModel extends Equatable {
  final int id;
  final String name;
  final String? icon;
  final bool enabled;

  const RideModuleModel({
    required this.id,
    required this.name,
    this.icon,
    this.enabled = true,
  });

  factory RideModuleModel.fromJson(Map<String, dynamic> json) {
    return RideModuleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      icon: json['icon'] as String?,
      enabled: json['enabled'] == true || json['enabled'] == 1,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, enabled];
}
