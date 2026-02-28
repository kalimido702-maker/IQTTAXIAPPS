import 'package:equatable/equatable.dart';

/// A ride preference option returned from the ETA API.
///
/// Example: {"id": 1, "name": "Pet Friendly", "price": 500}
class RidePreferenceModel extends Equatable {
  const RidePreferenceModel({
    required this.id,
    required this.name,
    required this.price,
  });

  final int id;
  final String name;
  final double price;

  factory RidePreferenceModel.fromJson(Map<String, dynamic> json) {
    return RidePreferenceModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id};

  @override
  List<Object?> get props => [id, name, price];
}
