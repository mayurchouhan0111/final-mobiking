import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/product_model.dart';
import '../services/wishlist_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/modules/profile/wishlist/Wish_list_screen.dart';
import 'package:collection/collection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/modules/login/login_screen.dart';

class WishlistController extends GetxController {
  final WishlistService _service = WishlistService();

  var wishlist = <ProductModel>[].obs;
  var isInitialLoading = false.obs;
  var isProcessingItem = ''.obs; // Stores productId being processed

  final ConnectivityController _connectivityController =
      Get.find<ConnectivityController>();

  @override
  void onInit() {
    super.onInit();
    loadWishlistFromLocal();
    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Future<void> fetchWishlistOnScreenLoad() async {
    if (wishlist.isEmpty) {
      isInitialLoading.value = true;
    }
    await _fetchWishlistInternal();
    isInitialLoading.value = false;
  }

  Future<void> _handleConnectionRestored() async {
    print(
      'WishlistController: Internet connection restored. Re-loading wishlist from local storage.',
    );
    loadWishlistFromLocal();
  }

  Future<void> _fetchWishlistInternal() async {
    try {
      final fetchedWishlist = await _service.fetchWishlist();
      wishlist.assignAll(fetchedWishlist);
    } catch (e) {
      print('WishlistController: Failed to fetch wishlist: $e');
    }
  }

  void loadWishlistFromLocal() {
    final box = _service.box;
    final userMap = box.read('user') as Map<String, dynamic>?;

    if (userMap != null) {
      final List<dynamic>? wishlistData = userMap['wishlist'];
      if (wishlistData != null) {
        wishlist.clear();
        wishlist.value = wishlistData
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        print('Wishlist loaded locally with ${wishlist.length} items.');
      } else {
        wishlist.clear();
        print('No "wishlist" field found in user data or it is null locally.');
      }
    } else {
      wishlist.clear();
      print('No user data found locally for wishlist.');
    }
  }

  bool isProductInWishlist(String productId) {
    return wishlist.any((p) => p.id == productId);
  }

  Future<void> addToWishlist(String productId) async {
    final box = GetStorage();
    final cartId = box.read('cartId');
    if (cartId == null) {
      Get.to(() => PhoneAuthScreen());
      Get.snackbar(
        'Login Required',
        'Please log in to add items to your wishlist.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (isProcessingItem.value == productId) return;
    
    isProcessingItem.value = productId;
    try {
      if (isProductInWishlist(productId)) {
        return;
      }

      final success = await _service.addToWishlist(productId);
      if (success) {
        final updatedList = await _service.fetchWishlist();
        wishlist.assignAll(updatedList);
        
        Get.snackbar(
          'Wishlist Updated',
          'Product added to your wishlist',
          mainButton: TextButton(
            onPressed: () {
              if (Get.isSnackbarOpen) Get.back();
              Get.to(() => const WishlistScreen(), transition: Transition.rightToLeftWithFade);
            },
            child: const Text('GOTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          icon: const Icon(Icons.favorite, color: Colors.white),
          backgroundColor: AppColors.primaryGreen,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isProcessingItem.value = '';
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    if (isProcessingItem.value == productId) return;
    
    isProcessingItem.value = productId;
    try {
      // Find name before optimistic removal for nicer snackbar
      final item = wishlist.firstWhereOrNull((p) => p.id == productId);
      final itemName = item?.name ?? 'Product';

      final success = await _service.removeFromWishlist(productId);
      if (success) {
        // Optimistic update
        wishlist.removeWhere((p) => p.id == productId);
        
        // Refresh from backend to stay in sync
        final updatedList = await _service.fetchWishlist();
        wishlist.assignAll(updatedList);
        
        Get.snackbar(
          'Removed',
          '$itemName removed from wishlist',
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          backgroundColor: AppColors.textDark.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      isProcessingItem.value = '';
    }
  }

  void updateWishlistFromLogin(List<dynamic> newWishlistData) {
    wishlist.value = newWishlistData
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
