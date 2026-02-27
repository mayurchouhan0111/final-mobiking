import 'cart_model.dart';
import 'product_model.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNo;
  final String? role;
  final String? profilePicture;
  final List<String>? departments;
  final List<String>? documents;
  final List<CartModel> cart;
  final List<ProductModel> wishlist;
  final Map<String, dynamic>? permissions;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phoneNo,
    this.role,
    this.profilePicture,
    this.departments,
    this.documents,
    this.permissions,
    this.cart = const [],
    this.wishlist = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phoneNo: json['phoneNo'],
      role: json['role'],
      profilePicture: json['profilePicture'],
      departments: List<String>.from(json['departments'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      cart:
          (json['cart'] as List?)?.map((e) => CartModel.fromJson(e)).toList() ??
          [],
      wishlist:
          (json['wishlist'] as List?)
              ?.map((e) => ProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phoneNo': phoneNo,
    'role': role,
    'profilePicture': profilePicture,
    'departments': departments,
    'documents': documents,
    'permissions': permissions,
    'cart': cart.map((c) => c.toJson()).toList(),
    'wishlist': wishlist.map((w) => w.toJson()).toList(),
  };
}
