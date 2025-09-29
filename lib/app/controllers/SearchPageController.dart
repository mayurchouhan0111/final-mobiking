import 'dart:async';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mobiking/app/controllers/product_controller.dart';

class SearchPageController extends GetxController {
  static const int productsPerPage = 20;
  static const Duration debounceDuration = Duration(milliseconds: 300);

  final ProductController productController = Get.find<ProductController>();

  // Reactive state variables
  final RxList<String> recentSearches = <String>[].obs;
  final RxList<dynamic> displayedProducts = <dynamic>[].obs;
  final RxBool showClearButton = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreProducts = true.obs;
  final RxString validationMessage = ''.obs;

  // Internal state
  int _currentPage = 0;
  String _lastSearchQuery = '';
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  void onSearchChanged(String query) {
    final trimmedQuery = query.trim();
    showClearButton.value = trimmedQuery.isNotEmpty;

    // Prevent unnecessary processing
    if (_isSearching || trimmedQuery == _lastSearchQuery) return;

    _debounceTimer?.cancel();

    if (trimmedQuery.isEmpty) {
      _resetSearch();
      return;
    }

    if (trimmedQuery.length < 2) {
      displayedProducts.clear();
      validationMessage.value = 'Please enter at least 2 characters to search.';
      return;
    }

    validationMessage.value = '';

    _debounceTimer = Timer(debounceDuration, () {
      if (!_isSearching) {
        _performSearch(trimmedQuery);
      }
    });
  }

  void _resetSearch() {
    displayedProducts.clear();
    _currentPage = 0;
    hasMoreProducts.value = true;
    validationMessage.value = 'Start typing to search for products.';
    _lastSearchQuery = '';
  }

  Future<void> _performSearch(String query) async {
    if (_isSearching) return;

    _isSearching = true;
    _lastSearchQuery = query;
    _currentPage = 0;
    hasMoreProducts.value = true;

    try {
      await productController.searchProducts(query);
      _updateDisplayedProducts(reset: true);
    } finally {
      _isSearching = false;
    }
  }

  void _updateDisplayedProducts({bool reset = false}) {
    final allResults = productController.searchResults;
    final startIndex = _currentPage * productsPerPage;
    final endIndex = (startIndex + productsPerPage).clamp(0, allResults.length);

    if (reset) {
      displayedProducts.clear();
    }

    if (startIndex < allResults.length) {
      displayedProducts.addAll(allResults.getRange(startIndex, endIndex));
      hasMoreProducts.value = endIndex < allResults.length;
    } else {
      hasMoreProducts.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMoreProducts.value || _isSearching) return;

    isLoadingMore.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _currentPage++;
      _updateDisplayedProducts();
    } finally {
      isLoadingMore.value = false;
    }
  }

  void addRecentSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty && cleanQuery.length >= 2) {
      recentSearches.remove(cleanQuery);
      recentSearches.insert(0, cleanQuery);
      if (recentSearches.length > 5) recentSearches.removeLast();
    }
  }

  void clearRecentSearches() {
    recentSearches.clear();
  }

  void removeRecentSearch(String search) {
    recentSearches.remove(search);
  }
}