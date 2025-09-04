import 'package:hive/hive.dart';

part 'selling_price.g.dart';

@HiveType(typeId: 4)
class SellingPrice extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final int price;

  @HiveField(2)
  final DateTime? createdAt;

  @HiveField(3)
  final DateTime? updatedAt;

  @HiveField(4)
  final String? variantName;

  SellingPrice({
    this.id,
    required this.price,
    this.createdAt,
    this.updatedAt,
    this.variantName,
  });

  factory SellingPrice.fromJson(Map<String, dynamic> json) {
    return SellingPrice(
      id: json['_id'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      variantName: json['variantName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'price': price,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (variantName != null) 'variantName': variantName,
  };
}