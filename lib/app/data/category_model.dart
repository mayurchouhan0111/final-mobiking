import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 5)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  @HiveField(3)
  final bool active;

  @HiveField(4)
  final String? image;

  @HiveField(5)
  final List<String> subCategoryIds;

  @HiveField(6)
  final double deliveryCharge;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
    this.image,
    required this.subCategoryIds,
    this.deliveryCharge = 0.0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<String> subCategoryIds = [];
    if (json['subCategories'] != null) {
      subCategoryIds = List<String>.from(
        (json['subCategories'] as List).map(
              (e) => e is String ? e : e['_id']?.toString() ?? '',
        ),
      );
      subCategoryIds.removeWhere((id) => id.isEmpty);
    }

    return CategoryModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      active: json['active'] ?? false,
      image: json['image']?.toString(),
      subCategoryIds: subCategoryIds,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'slug': slug,
    'active': active,
    'image': image,
    'subCategories': subCategoryIds,
    'deliveryCharge': deliveryCharge,
  };
}