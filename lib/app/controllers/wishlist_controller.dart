import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/product_model.dart';
import '../services/wishlist_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

class WishlistController extends GetxController {
  final WishlistService _service = WishlistService();

  var wishlist = <ProductModel>[].obs;
  var isLoading = false.obs;

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();

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
    await _fetchWishlistInternal();
  }

  Future<void> _handleConnectionRestored() async {
    print('WishlistController: Internet connection restored. Re-loading wishlist from local storage.');
    loadWishlistFromLocal();
  }

  Future<void> _fetchWishlistInternal() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final fetchedWishlist = await _service.fetchWishlist();
      wishlist.assignAll(fetchedWishlist);
    } catch (e) {
      print('WishlistController: Failed to fetch wishlist: $e');
    } finally {
      isLoading.value = false;
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
    if (isLoading.value) return;
    isLoading.value = true;

    if (isProductInWishlist(productId)) {
      isLoading.value = false;
      return;
    }

    final success = await _service.addToWishlist(productId);
    if (success) {
      wishlist.assignAll(await _service.fetchWishlist());
    } else {
      loadWishlistFromLocal();
    }
    isLoading.value = false;
  }

  Future<void> removeFromWishlist(String productId) async {
    if (isLoading.value) return;
    isLoading.value = true;

    final success = await _service.removeFromWishlist(productId);
    if (success) {
      wishlist.assignAll(await _service.fetchWishlist());
    } else {
      loadWishlistFromLocal();
    }
    isLoading.value = false;
  }

  void updateWishlistFromLogin(List<dynamic> newWishlistData) {
    wishlist.value = newWishlistData
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}