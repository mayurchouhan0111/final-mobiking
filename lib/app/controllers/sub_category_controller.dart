import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/sub_category_model.dart';
import '../data/product_model.dart';
import '../services/sub_category_service.dart';

class SubCategoryController extends GetxController {
  final SubCategoryService _service = SubCategoryService();

  // Observable variables with proper generic types
  final RxList<SubCategory> subCategories = <SubCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoad = true.obs;

  // Selected subcategory and its products
  final Rx<SubCategory?> selectedSubCategory = Rx<SubCategory?>(null);
  final RxList<ProductModel> productsForSelectedSubCategory = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _service.init(); // Initialize the service's Hive boxes
    loadSubCategories();

    // React to changes in selectedSubCategory to update products
    ever(selectedSubCategory, (_) {
      _updateProductsForSelectedSubCategory();
    });
  }

  /// Load subcategories with Hive caching support
  Future<void> loadSubCategories({bool forceRefresh = false}) async {
    try {
      if (subCategories.isEmpty) {
        isLoading.value = true;
        isInitialLoad.value = true;
      }

      print('[SubCategoryController] Loading subcategories...');
      final data = await _service.fetchSubCategories(forceRefresh: forceRefresh);
      subCategories.assignAll(data);

      print('[SubCategoryController] Loaded ${data.length} subcategories');

      // Auto-select the first subcategory if available
      if (data.isNotEmpty && selectedSubCategory.value == null) {
        selectedSubCategory.value = data.first;
      }

      // Show success message only for forced refresh
      if (forceRefresh && data.isNotEmpty) {

      }

    } catch (e, stackTrace) {
      print('[SubCategoryController] Error loading subcategories: $e');
      print(stackTrace);

      await _service.clearCache(); // Clear cache on error
    } finally {
      isLoading.value = false;
      isInitialLoad.value = false;
    }
  }

  /// Add new subcategory
  Future<void> addSubCategory(SubCategory model) async {
    try {
      isLoading.value = true;
      final newItem = await _service.createSubCategory(model);
      subCategories.add(newItem);

      // Auto-select if it's the first subcategory
      if (selectedSubCategory.value == null) {
        selectedSubCategory.value = newItem;
      }

      print('[SubCategoryController] Subcategory added: ${newItem.name}');

    } catch (e) {
      print('[SubCategoryController] Error adding subcategory: $e');
      // Get.snackbar('Error', 'Failed to add subcategory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a subcategory
  void selectSubCategory(SubCategory? subCategory) {
    selectedSubCategory.value = subCategory;
  }

  /// Update products for selected subcategory
  void _updateProductsForSelectedSubCategory() {
    if (selectedSubCategory.value != null) {
      final List<ProductModel> products = List<ProductModel>.from(selectedSubCategory.value!.products);
      
      // Sort: In stock first, then out of stock
      products.sort((a, b) {
        if (a.totalStock > 0 && b.totalStock <= 0) return -1;
        if (a.totalStock <= 0 && b.totalStock > 0) return 1;
        return 0;
      });

      productsForSelectedSubCategory.assignAll(products);
      print('[SubCategoryController] Updated & Sorted products: ${productsForSelectedSubCategory.length} for ${selectedSubCategory.value!.name}');
    } else {
      productsForSelectedSubCategory.clear();
      print('[SubCategoryController] Cleared products as no subcategory selected');
    }
  }

  /// Force refresh subcategories from API
  Future<void> refreshSubCategories() async {
    await loadSubCategories(forceRefresh: true);
  }

  /// Clear subcategories cache
  Future<void> clearCache() async {
    try {
      await _service.clearCache();

    } catch (e) {
      print('[SubCategoryController] Error clearing cache: $e');
    }
  }

  /// Get cache information - SAFE VERSION
  Map<String, dynamic> getCacheInfo() {
    try {
      final cacheInfo = _service.getCacheInfo();
      return {
        'cachedItemsCount': cacheInfo['cachedItemsCount'] ?? 0,
        'lastFetch': cacheInfo['lastFetch'],
        'isCacheValid': cacheInfo['isCacheValid'] ?? false,
      };
    } catch (e) {
      print('[SubCategoryController] Error getting cache info: $e');
      return {
        'cachedItemsCount': 0,
        'lastFetch': null,
        'isCacheValid': false,
      };
    }
  }

  /// Get subcategories for a specific category
  List<SubCategory> getSubCategoriesForCategory(String categoryId) {
    return subCategories.where((sub) => sub.parentCategory?.id == categoryId).toList();
  }
}