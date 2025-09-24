import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/controllers/product_controller.dart';

import '../data/product_model.dart';
import '../services/cart_service.dart';
import 'connectivity_controller.dart';

class CartController extends GetxController {
  RxMap<String, dynamic> cartData = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var processingProductId = ''.obs;
  final box = GetStorage();

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  final ProductController _productController = Get.find<ProductController>();

  RxMap<String, int> productVariantQuantities = <String, int>{}.obs;

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
    });
  }

  void _updateProductVariantQuantities() {
    print('🛒 CartController: Recalculating product variant quantities...');
    final Map<String, int> newQuantities = {};
    for (var item in cartItems) {
      final itemProductId = item['productId']?['_id'];
      final itemVariantName = item['variantName'];
      final int quantity = item['quantity'] as int? ?? 0;

      if (itemProductId != null && itemVariantName != null) {
        final key = '${itemProductId}_$itemVariantName';
        newQuantities[key] = quantity;
      }
    }
    productVariantQuantities.value = newQuantities;
    print('🛒 CartController: Finished recalculating product variant quantities. Total unique variants: ${productVariantQuantities.length}');
  }

  Future<void> fetchAndLoadCartData() async {
    print('🛒 CartController: Attempting to fetch and load cart data...');
    isLoading.value = true;

    try {
      final String? userId = box.read('user')?['_id'];
      if (userId == null) {
        print('🛒 CartController: User ID not found, cannot fetch cart from backend. Loading from local storage fallback.');
        await _loadCartDataFromLocalStorage();
        return;
      }

      final apiResponse = await CartService().fetchCart(cartId: cartData.value['_id']);
      print('🛒 CartController: Fetched cart from backend: $apiResponse');

      if (apiResponse != null && apiResponse['success'] == true && apiResponse['data']?['cart'] is Map) {
        final Map<String, dynamic> fetchedCart = Map<String, dynamic>.from(apiResponse['data']['cart']);
        cartData.value = fetchedCart;
        var userInStorage = box.read('user') as Map<String, dynamic>?;
        if (userInStorage != null) {
          userInStorage['cart'] = fetchedCart;
          await box.write('user', userInStorage);
        }
        print('🛒 CartController: Cart data updated from backend: ${cartData.value}');
      } else {
        print('🛒 CartController: Backend cart fetch failed or returned invalid data. Loading from local storage fallback.');
        await _loadCartDataFromLocalStorage();
      }
    } catch (e) {
      print('🛒 CartController: Error fetching cart from backend: $e. Loading from local storage fallback.');
      await _loadCartDataFromLocalStorage();
    } finally {
      isLoading.value = false;
      print('🛒 CartController: Current totalCartItemsCount after _fetchAndLoadCartData: ${totalCartItemsCount}');
    }
  }

  Future<void> _loadCartDataFromLocalStorage() async {
    print('🛒 CartController: Loading cart data from local storage (fallback)...');
    try {
      final Map<String, dynamic>? user = box.read('user');

      if (user != null && user.containsKey('cart') && user['cart'] is Map) {
        cartData.value = Map<String, dynamic>.from(user['cart']);
        print('🛒 CartController: Cart data loaded from local storage: ${cartData.value}');
      } else {
        await _resetLocalCartData();
        print('🛒 CartController: No valid cart data found in stored user object locally, initializing to empty structure.');
      }
    } catch (e) {
      print('🛒 CartController: Error loading cart data from local storage: $e');
      await _resetLocalCartData();
    }
  }

  Future<void> _handleConnectionRestored() async {
    print('🛒 CartController: Internet connection restored. Re-fetching cart data...');
    await fetchAndLoadCartData();
  }

  List<Map<String, dynamic>> get cartItems {
    try {
      if (cartData.containsKey('items') && cartData['items'] is List) {
        final List<Map<String, dynamic>> validItems = [];
        for (var item in (cartData['items'] as List)) {
          if (item is Map && item.containsKey('productId') && item['productId'] is Map<String, dynamic>) {
            validItems.add(Map<String, dynamic>.from(item));
          } else {
            debugPrint('🛒 CartController: Malformed cart item found: $item'); // ADDED DEBUG PRINT
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
      final itemProductId = item['productId']?['_id'];
      if (itemProductId == productId) {
        final itemVariantName = item['variantName'] as String? ?? 'Default';
        final int quantity = item['quantity'] as int? ?? 0;
        if (quantity > 0) {
          productVariantsInCart[itemVariantName] = quantity;
        }
      }
    }
    print('🛒 CartController: Variants in cart for product $productId: $productVariantsInCart');
    return productVariantsInCart;
  }

  int getVariantQuantity({required String productId, required String variantName}) {
    final key = '${productId}_$variantName';
    final quantity = productVariantQuantities[key] ?? 0;
    return quantity;
  }

  int getTotalQuantityForProduct({required String productId}) {
    int totalQuantity = 0;
    for (var item in cartItems) {
      final itemProductId = item['productId']?['_id'];
      if (itemProductId == productId) {
        totalQuantity += item['quantity'] as int? ?? 0;
      }
    }
    print('🛒 CartController: Calculated total quantity for product $productId -> $totalQuantity');
    return totalQuantity;
  }

  int get totalCartItemsCount {
    int totalCount = 0;
    for (var item in cartItems) {
      totalCount += item['quantity'] as int? ?? 0;
    }
    print('🛒 CartController: Calculating totalCartItemsCount: $totalCount');
    return totalCount;
  }

  double calculateDeliveryCharge() {
    double maxDeliveryCharge = 0.0;
    for (var item in cartItems) {
      final productData = item['productId'];
      if (productData is Map<String, dynamic>) {
        final product = ProductModel.fromJson(productData);
        final itemDeliveryCharge = product.category?.deliveryCharge ?? 0.0;
        if (itemDeliveryCharge > maxDeliveryCharge) {
          maxDeliveryCharge = itemDeliveryCharge;
        }
      }
    }
    return maxDeliveryCharge;
  }

  // ✅ FIXED: Rewrote totalCartValue to ensure consistency with CheckoutScreen.
  // It now recalculates the price from the full product data every time,
  // preventing stale price issues.
  double get totalCartValue {
    double total = 0.0;
    for (var item in cartItems) {
      final productData = item['productId'];
      final quantity = (item['quantity'] as int?) ?? 1;
      final itemVariantName = item['variantName'] as String? ?? 'Default'; // Get variant name from cart item

      if (productData is Map<String, dynamic>) {
        final product = ProductModel.fromJson(productData);

        // Find the selling price for the specific variant
        final sellingPriceForVariant = product.sellingPrice.firstWhereOrNull(
          (sp) => sp.variantName == itemVariantName,
        );

        if (sellingPriceForVariant != null && sellingPriceForVariant.price != null) {
          final itemPrice = sellingPriceForVariant.price!.toDouble();
          total += itemPrice * quantity;
        } else {
          // Fallback if variant price not found, use first selling price if available
          if (product.sellingPrice.isNotEmpty && product.sellingPrice[0].price != null) {
            final itemPrice = product.sellingPrice[0].price!.toDouble();
            total += itemPrice * quantity;
          }
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
    final cartId = box.read('cartId');
    if (cartId == null) {
      _showSnackbar('Not Logged In', 'Please log in to add items to your cart.', Colors.orange, Icons.login);
      return false;
    }
    print('🛒 CartController: Adding to cart: productId=$productId, variantName=$variantName, cartId=$cartId');

    processingProductId.value = '${productId}_$variantName';
    try {
      final response = await CartService().addToCart(
        productId: productId,
        cartId: cartId,
        variantName: variantName,
      );

      if (response['success'] == true) {
        await _updateStorageAndCartData(response);
        
        return true;
      } else {
        final errorMessage = response['message'] ?? 'Failed to add product to cart.';

        return false;
      }
    } catch (e) {
      String errorMessage = 'An unexpected error occurred.';
      if (e is dio.DioException) {
        errorMessage = e.response?.data?['message'] ?? e.message ?? errorMessage;
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
    print('🛒 CartController: Removing from cart: productId=$productId, variantName=$variantName, cartId=$cartId');

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

  Future<void> _updateStorageAndCartData(Map<String, dynamic> apiResponse) async {
    print('🛒 CartController: Starting _updateStorageAndCartData...');
    print('🛒 CartController: Full API Response for cart update: $apiResponse');

    final updatedUser = apiResponse['data']?['user'];
    print('🛒 CartController: Extracted updatedUser from response: $updatedUser');

    if (updatedUser != null && updatedUser is Map) {
      await box.write('user', updatedUser);
      print('🛒 CartController: Stored updated user object directly to "user" key in GetStorage.');

      final updatedCart = updatedUser['cart'];
      if (updatedCart != null && updatedCart is Map) {
        cartData.value = Map<String, dynamic>.from(updatedCart);
        print('🛒 CartController: Updated cartData.value observable with latest cart: ${cartData.value}');
      } else {
        await _resetLocalCartData();
        print('🛒 CartController: Warning: Updated user object from API did not contain a valid "cart". Local cartData reset.');
      }
    } else {
      await _resetLocalCartData();
      print('🛒 CartController: Warning: No updated user data (apiResponse["data"]["user"]) in cart response. Local cartData reset.');
    }
  }

  Future<void> _resetLocalCartData() async {
    cartData.value = {
      'items': [],
      'totalCartValue': 0.0,
    };
    final user = box.read('user');
    if (user != null) {
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
        print('🛒 CartController: Failed to clear cart on the backend: ${response['message']}');
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
      snackPosition: SnackPosition.BOTTOM,
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