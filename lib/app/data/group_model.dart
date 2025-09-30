import 'package:mobiking/app/data/parent_category_model.dart';
import 'package:mobiking/app/data/product_model.dart';

class GroupModel {
  final String id;
  final String name;
  final int sequenceNo;
  final String banner;
  final String? bannerLink;
  final bool isBannerLinkActive;
  final bool active;
  final bool isBannerVisible;
  final bool isSpecial;
  final List<ProductModel> products;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backgroundColor;
  final bool isBackgroundColorVisible;
  final List<String> categories;
  final List<ParentCategoryModel> parentCategories;

  GroupModel({
    required this.id,
    required this.name,
    required this.sequenceNo,
    required this.banner,
    this.bannerLink,
    required this.isBannerLinkActive,
    required this.active,
    required this.isBannerVisible,
    required this.isSpecial,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColor,
    required this.isBackgroundColorVisible,
    required this.categories,
    required this.parentCategories,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    String? safeString(dynamic value) {
      if (value is String) {
        return value;
      }
      return null;
    }

    List<String> safeStringList(dynamic value) {
      if (value is List) {
        List<String> result = [];
        for (var item in value) {
          if (item is String) {
            result.add(item);
          } else if (item is Map<String, dynamic> && item.containsKey('_id')) {
            result.add(item['_id']);
          }
        }
        return result;
      }
      return [];
    }

    List<ParentCategoryModel> parentCategoriesList = [];
    if (json['parentCategories'] != null && json['parentCategories'] is List) {
      parentCategoriesList = (json['parentCategories'] as List)
          .map((e) => ParentCategoryModel.fromJson(e))
          .toList();
    }

    return GroupModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      sequenceNo: json['sequenceNo'] ?? 0,
      banner: json['banner'] ?? '',
      bannerLink: safeString(json['bannerLink']),
      isBannerLinkActive: json['isBannerLinkActive'] ?? false,
      active: json['active'] ?? true,
      isBannerVisible: json['isBannerVisble'] ?? false, // Note: backend typo 'isBannerVisble'
      isSpecial: json['isSpecial'] ?? false,
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => e is Map<String, dynamic> ? ProductModel.fromJson(e) : ProductModel.fromJson({})) // Handle potential non-map items
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      backgroundColor: safeString(json['backgroundColor']),
      isBackgroundColorVisible: json['isBackgroundColorVisible'] ?? false,
      categories: safeStringList(json['categories']),
      parentCategories: parentCategoriesList,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'sequenceNo': sequenceNo,
    'banner': banner,
    'bannerLink': bannerLink,
    'isBannerLinkActive': isBannerLinkActive,
    'active': active,
    'isBannerVisible': isBannerVisible,
    'isSpecial': isSpecial,
    'products': products.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'backgroundColor': backgroundColor,
    'isBackgroundColorVisible': isBackgroundColorVisible,
    'categories': categories,
    'parentCategories': parentCategories.map((e) => e.toJson()).toList(),
  };}