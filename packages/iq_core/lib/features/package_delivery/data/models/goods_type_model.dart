import 'package:equatable/equatable.dart';

/// A single goods-type option returned by the API.
///
/// Displayed in a radio-list so the user can pick what kind of parcel
/// they are sending/receiving.
class GoodsTypeModel extends Equatable {
  const GoodsTypeModel({
    required this.id,
    required this.name,
    this.category = '',
    this.active = true,
  });

  final int id;
  final String name;
  final String category;
  final bool active;

  factory GoodsTypeModel.fromJson(Map<String, dynamic> json) {
    return GoodsTypeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['goods_type_name'] as String?) ?? '',
      category: (json['goods_types_for'] as String?) ?? '',
      active: (json['active'] as num?)?.toInt() == 1,
    );
  }

  @override
  List<Object?> get props => [id, name, category, active];
}
