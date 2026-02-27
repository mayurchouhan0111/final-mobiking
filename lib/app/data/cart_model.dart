class CartModel {
  final String productId;
  final String variantName; // You might want to add this too for completeness
  final int quantity;
  final double price;
  // You could also add other fields if you need to display them directly from the cart item
  // e.g., final String productName;
  // final String? imageUrl;

  CartModel({
    required this.productId,
    required this.variantName, // Add to constructor
    this.quantity = 1,
    required this.price,
    // this.productName,
    // this.imageUrl,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      productId:
          json['productId']['_id'] as String, // CORRECTED: Access nested _id
      variantName: json['variantName'] as String, // Add variantName parsing
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num).toDouble(),
      // productName: json['productId']['name'] as String?, // If you add productName
      // imageUrl: (json['productId']['images'] as List?)?.isNotEmpty == true
      //     ? (json['productId']['images'] as List).first as String
      //     : null, // If you add imageUrl
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId':
          productId, // This would send just the ID back to backend if needed
      'variantName': variantName,
      'quantity': quantity,
      'price': price,
    };
  }
}
