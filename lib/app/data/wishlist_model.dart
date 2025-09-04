import 'package:mobiking/app/data/product_model.dart';

class Wishlist {
  final String id;
  final List<ProductModel> products;

  Wishlist({required this.id, required this.products});

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['_id'] ?? '',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => ProductModel.fromJson(e))
          .toList(),
    );
  }
}
