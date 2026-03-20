import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:collection/collection.dart'; // ✅ ADDED: Required for firstWhereOrNull
import 'coupon_controller.dart';

import '../data/product_model.dart';
import '../services/cart_service.dart';
import 'connectivity_controller.dart';
import '../services/analytics_service.dart';
import '../modules/login/login_screen.dart'; // ✅ For guest redirection

class CartController extends GetxController {
  RxMap<String, dynamic> cartData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var processingProductId = ''.obs;
  final box = GetStorage();

  final ConnectivityController _connectivityController =
      Get.find<ConnectivityController>();
  final ProductController _productController = Get.find<ProductController>();

  RxMap<String, int> productVariantQuantities = <String, int>{}.obs;

  // ✅ ADDED: userId getter to safely retrieve user ID
  String? get userId {
    try {
      final user = box.read('user');
      if (user != null && user is Map) {
        return user['_id']?.toString() ?? user['id']?.toString();
      }
      return null;
    } catch (e) {
      print('🛒 CartController: Error getting userId: $e');
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAndLoadCartData();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });

    ever(cartData, (_) {
      _updateProductVariantQuantities();

      final currentTotal = totalCartValue;
      final isEmpty = cartItems.isEmpty;

      // ✅ Handle Coupon Logic
      try {
        if (Get.isRegistered<CouponController>()) {
          final couponController = Get.find<CouponController>();

          if (isEmpty) {
            // Cart is empty, reset coupon state completely
            couponController.removeCoupon();
          } else {
            // Update subtotal for recalculation
            couponController.setSubtotal(currentTotal);
          }
        }
      } catch (e) {
        debugPrint('🛒 CartController: Error updating coupon state: $e');
      }
    });
  }

  void _updateProductVariantQuantities() {
    print('🛒 CartController: Recalculating product variant quantities...');
    final Map<String, int> newQuantities = {};
    for (var item in (cartData['items'] as List? ?? [])) {
      if (item is Map) {
        final itemProductId = _extractProductId(item['productId']);
        final itemVariantName = item['variantName'];
        final int quantity = item['quantity'] as int? ?? 0;

        if (itemProductId != null && itemVariantName != null) {
          final key = '${itemProductId}_$itemVariantName';
          newQuantities[key] = quantity;
        }
      }
    }
    productVariantQuantities.value = newQuantities;
    print(
      '🛒 CartController: Finished recalculating product variant quantities. Total unique variants: ${productVariantQuantities.length}',
    );
  }

  // Helper to extract ID from either String or Map
  String? _extractProductId(dynamic productData) {
    if (productData == null) return null;
    if (productData is String) return productData;
    if (productData is Map)
      return productData['_id']?.toString() ?? productData['id']?.toString();
    return null;
  }

  Future<void> fetchAndLoadCartData() async {
    print('🛒 CartController: Attempting to fetch and load cart data...');
    isLoading.value = true;

    try {
      if (userId == null) {
        print(
          '🛒 CartController: User ID not found, cannot fetch cart from backend. Loading from local storage fallback.',
        );
        await _loadCartDataFromLocalStorage();
        return;
      }

      // Updated: fetchCart no longer requires cartId in the URL as it uses the Authorization token
      final apiResponse = await CartService().fetchCart();
      print('🛒 CartController: Fetched cart from backend: $apiResponse');

      if (apiResponse != null &&
          apiResponse['success'] == true &&
          apiResponse['data'] is Map) {
        final Map<String, dynamic> fetchedCart = Map<String, dynamic>.from(
          apiResponse['data'],
        );

        // Ensure we store the latest cart ID for other side effects if needed
        if (fetchedCart.containsKey('_id')) {
          await box.write('cartId', fetchedCart['_id'].toString());
        }

        // ✅ FIXED: Proper type handling for GetStorage
        var userInStorage = box.read('user');
        if (userInStorage != null && userInStorage is Map) {
          final updatedUser = Map<String, dynamic>.from(userInStorage);
          updatedUser['cart'] = fetchedCart;
          await box.write('user', updatedUser);
        }

        cartData.value = fetchedCart;
        print('🛒 CartController: Fresh API data stored and then shown.');
      } else {
        print(
          '🛒 CartController: Backend cart fetch failed or returned invalid data. Loading from local storage fallback.',
        );
        await _loadCartDataFromLocalStorage();
      }
    } catch (e) {
      print(
        '🛒 CartController: Error fetching cart from backend: $e. Loading from local storage fallback.',
      );
      await _loadCartDataFromLocalStorage();
    } finally {
      isLoading.value = false;
      print(
        '🛒 CartController: Current totalCartItemsCount after fetchAndLoadCartData: $totalCartItemsCount',
      );
    }
  }

  Future<void> _loadCartDataFromLocalStorage() async {
    print(
      '🛒 CartController: Loading cart data from local storage (fallback)...',
    );
    try {
      final dynamic userRaw = box.read('user');

      if (userRaw != null && userRaw is Map) {
        final user = Map<String, dynamic>.from(userRaw);

        if (user.containsKey('cart') && user['cart'] is Map) {
          cartData.value = Map<String, dynamic>.from(user['cart']);
          _updateProductVariantQuantities();
          print(
            '🛒 CartController: Cart data loaded from local storage: ${cartData.value}',
          );
        } else {
          await _resetLocalCartData();
          print(
            '🛒 CartController: No valid cart data found in stored user object locally, initializing to empty structure.',
          );
        }
      } else {
        await _resetLocalCartData();
        print(
          '🛒 CartController: No user data in storage, initializing to empty cart.',
        );
      }
    } catch (e) {
      print(
        '🛒 CartController: Error loading cart data from local storage: $e',
      );
      await _resetLocalCartData();
    }
  }

  Future<void> _handleConnectionRestored() async {
    print(
      '🛒 CartController: Internet connection restored. Re-fetching cart data...',
    );
    await fetchAndLoadCartData();
  }

  List<Map<String, dynamic>> get cartItems {
    try {
      if (cartData.containsKey('items') && cartData['items'] is List) {
        final List<Map<String, dynamic>> validItems = [];
        for (var item in (cartData['items'] as List)) {
          if (item is Map && item.containsKey('productId')) {
            validItems.add(Map<String, dynamic>.from(item));
          } else {
            debugPrint('🛒 CartController: Malformed cart item found: $item');
          }
        }
        return validItems;
      }
      return [];
    } catch (e) {
      print('🛒 CartController: Error getting cartItems: $e');
      return [];
    }
  }

  Map<String, int> getCartItemsForProduct({required String productId}) {
    final Map<String, int> productVariantsInCart = {};
    for (var item in cartItems) {
      final itemProductId = _extractProductId(item['productId']);
      if (itemProductId == productId) {
        final itemVariantName = item['variantName'] as String? ?? 'Default';
        final int quantity = item['quantity'] as int? ?? 0;
        if (quantity > 0) {
          productVariantsInCart[itemVariantName] = quantity;
        }
      }
    }
    print(
      '🛒 CartController: Variants in cart for product $productId: $productVariantsInCart',
    );
    return productVariantsInCart;
  }

  int getVariantQuantity({
    required String productId,
    required String variantName,
  }) {
    final key = '${productId}_$variantName';
    final quantity = productVariantQuantities[key] ?? 0;
    return quantity;
  }

  int getTotalQuantityForProduct({required String productId}) {
    int totalQuantity = 0;
    for (var item in cartItems) {
      final itemProductId = _extractProductId(item['productId']);
      if (itemProductId == productId) {
        totalQuantity += item['quantity'] as int? ?? 0;
      }
    }
    print(
      '🛒 CartController: Calculated total quantity for product $productId -> $totalQuantity',
    );
    return totalQuantity;
  }

  int get totalCartItemsCount {
    int totalCount = 0;
    productVariantQuantities.forEach((_, qty) => totalCount += qty);
    return totalCount;
  }

  double calculateDeliveryCharge() {
    double maxDeliveryCharge = 0.0;
    for (var item in cartItems) {
      final productData = item['productId'];
      if (productData is Map<String, dynamic>) {
        try {
          final product = ProductModel.fromJson(productData);
          final itemDeliveryCharge = product.category?.deliveryCharge ?? 0.0;
          if (itemDeliveryCharge > maxDeliveryCharge) {
            maxDeliveryCharge = itemDeliveryCharge;
          }
        } catch (e) {
          print(
            '🛒 CartController: Error parsing product for delivery charge: $e',
          );
        }
      }
    }
    return maxDeliveryCharge;
  }

  // ✅ FIXED: Proper null-safety and type handling
  double get totalCartValue {
    double total = 0.0;
    for (var item in cartItems) {
      final productData = item['productId'];
      final quantity = (item['quantity'] as int?) ?? 1;
      final itemVariantName = item['variantName'] as String? ?? 'Default';

      if (productData is Map<String, dynamic>) {
        try {
          final product = ProductModel.fromJson(productData);

          // ✅ FIXED: Using firstWhereOrNull from collection package
          final sellingPriceForVariant = product.sellingPrice.firstWhereOrNull(
            (sp) => sp.variantName == itemVariantName,
          );

          if (sellingPriceForVariant != null &&
              sellingPriceForVariant.price != null) {
            final itemPrice = sellingPriceForVariant.price!.toDouble();
            total += itemPrice * quantity;
          } else {
            // Fallback if variant price not found
            if (product.sellingPrice.isNotEmpty &&
                product.sellingPrice.last.price != null) {
              final itemPrice = product.sellingPrice.last.price!.toDouble();
              total += itemPrice * quantity;
            }
          }
        } catch (e) {
          print('🛒 CartController: Error calculating price for item: $e');
        }
      }
    }
    return total;
  }

  Future<bool> addToCart({
    required String productId,
    required String variantName,
    ProductModel? product,
  }) async {
    if (product != null) {
      print('🛒 CartController: Product details: ${product.toJson()}');
    }
    final cartId = box.read('cartId');
    if (cartId == null) {
      // ✅ APP STORE COMPLIANCE: Redirect to login for account-based actions
      Get.to(() => PhoneAuthScreen());

      _showSnackbar(
        'Login Required',
        'Please log in to add items to your cart.',
        Colors.orange,
        Icons.login,
      );
      return false;
    }
    print(
      '🛒 CartController: Adding to cart: productId=$productId, variantName=$variantName, cartId=$cartId',
    );

    processingProductId.value = '${productId}_$variantName';
    try {
      final response = await CartService().addToCart(
        productId: productId,
        cartId: cartId,
        variantName: variantName,
      );

      if (response['success'] == true) {
        await _updateStorageAndCartData(response);

        // ✅ LOG ANALYTICS: Add to Cart
        try {
          if (product != null) {
            Get.find<AnalyticsService>().logAddToCart(
              itemId: productId,
              itemName: product.fullName ?? 'Product',
              itemCategory: product.category?.name ?? 'General',
              quantity: 1,
              price: product.sellingPrice.isNotEmpty
                  ? (product.sellingPrice.last.price?.toDouble() ?? 0.0)
                  : 0.0,
            );
          }
        } catch (e) {
          debugPrint('📊 Analytics Error: $e');
        }
        return true;
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to add product to cart.';
        print('🛒 CartController: Add to cart failed: $errorMessage');
        return false;
      }
    } catch (e) {
      String errorMessage = 'An unexpected error occurred.';
      if (e is dio.DioException) {
        errorMessage =
            e.response?.data?['message'] ?? e.message ?? errorMessage;
      } else {
        errorMessage = e.toString();
      }
      print("🛒 CartController: Add to cart error: $errorMessage");
      return false;
    } finally {
      processingProductId.value = '';
    }
  }

  Future<void> removeFromCart({
    required String productId,
    required String variantName,
  }) async {
    final cartId = box.read('cartId');
    if (cartId == null) {
      return;
    }
    print(
      '🛒 CartController: Removing from cart: productId=$productId, variantName=$variantName, cartId=$cartId',
    );

    processingProductId.value = '${productId}_$variantName';
    try {
      final response = await CartService().removeFromCart(
        productId: productId,
        cartId: cartId,
        variantName: variantName,
      );

      if (response['success'] == true) {
        await _updateStorageAndCartData(response);
      }
    } catch (e) {
      print("🛒 CartController: Remove from cart error: $e");
    } finally {
      processingProductId.value = '';
    }
  }

  Future<void> _updateStorageAndCartData(
    Map<String, dynamic> apiResponse,
  ) async {
    print('🛒 CartController: Starting _updateStorageAndCartData...');
    print('🛒 CartController: Full API Response for cart update: $apiResponse');

    final updatedUserRaw = apiResponse['data']?['user'];
    print(
      '🛒 CartController: Extracted updatedUser from response: $updatedUserRaw',
    );

    if (updatedUserRaw != null && updatedUserRaw is Map) {
      final updatedUser = Map<String, dynamic>.from(updatedUserRaw);
      await box.write('user', updatedUser);
      print(
        '🛒 CartController: Stored updated user object directly to "user" key in GetStorage.',
      );

      final updatedCart = updatedUser['cart'];
      if (updatedCart != null && updatedCart is Map) {
        cartData.value = Map<String, dynamic>.from(updatedCart);
        print(
          '🛒 CartController: Updated cartData.value observable with latest cart: ${cartData.value}',
        );
      } else {
        await _resetLocalCartData();
        print(
          '🛒 CartController: Warning: Updated user object from API did not contain a valid "cart". Local cartData reset.',
        );
      }
    } else {
      await _resetLocalCartData();
      print(
        '🛒 CartController: Warning: No updated user data (apiResponse["data"]["user"]) in cart response. Local cartData reset.',
      );
    }
  }

  Future<void> _resetLocalCartData() async {
    cartData.value = {'items': [], 'totalCartValue': 0.0};

    final userRaw = box.read('user');
    if (userRaw != null && userRaw is Map) {
      final user = Map<String, dynamic>.from(userRaw);
      user['cart'] = cartData.value;
      await box.write('user', user);
    }
  }

  Future<void> clearCartData() async {
    print('🛒 CartController: Clearing cart data...');
    final cartId = cartData.value['_id'];
    if (cartId == null) {
      print('🛒 CartController: No cart ID found, just clearing local data.');
      await _resetLocalCartData();
      return;
    }

    try {
      final response = await CartService().clearCart(cartId: cartId);
      if (response['success'] == true) {
        print('🛒 CartController: Cart cleared successfully on the backend.');
      } else {
        print(
          '🛒 CartController: Failed to clear cart on the backend: ${response['message']}',
        );
      }
    } catch (e) {
      print('🛒 CartController: Error clearing cart on the backend: $e');
    } finally {
      await _resetLocalCartData();
      print('🛒 CartController: Local cartData observable cleared.');
    }
  }

  void _showSnackbar(String title, String message, Color color, IconData icon) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.8),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      animationDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 2),
    );
  }

  void updateCartFromLogin(Map<String, dynamic> newCartData) {
    cartData.value = newCartData;
  }
}
