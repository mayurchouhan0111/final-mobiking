import 'package:get/get.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import '../data/Home_model.dart';
import '../data/group_model.dart';
import '../services/home_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage
import 'package:flutter/widgets.dart'; // For precacheImage
import 'package:cached_network_image/cached_network_image.dart'; // For CachedNetworkImageProvider

class HomeController extends GetxController {
  final GetStorage _box = GetStorage(); // GetStorage instance
  late final HomeService _service = HomeService(_box); // Pass GetStorage to HomeService
  final ConnectivityController _connectivityController = Get.find();

  /// Only expose loading state when needed for UI
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  /// Expose final home data
  final Rxn<HomeLayoutModel> _homeData = Rxn<HomeLayoutModel>();
  HomeLayoutModel? get homeData => _homeData.value;

  /// Store groups per category only once (non-reactive)
  final Map<String, List<GroupModel>> _categoryGroups = {};
  Map<String, List<GroupModel>> get categoryGroups => _categoryGroups;

  /// ✅ Add loading state tracking for individual category groups
  final RxMap<String, bool> _isLoadingGroups = <String, bool>{}.obs;
  Map<String, bool> get isLoadingGroups => _isLoadingGroups;

  /// ✅ Add error state tracking for category groups
  final RxMap<String, String?> _groupErrors = <String, String?>{}.obs;
  Map<String, String?> get groupErrors => _groupErrors;

  /// ✅ Add method to check if any groups are currently loading
  bool get isAnyGroupLoading => _isLoadingGroups.values.any((loading) => loading == true);

  @override
  void onInit() {
    super.onInit();
    fetchHomeLayout();

    // Only refetch on reconnection
    ever<bool>(_connectivityController.isConnected, (isConnected) {
      if (isConnected) _handleConnectionRestored();
    });
  }

  Future<void> _handleConnectionRestored() async {
    print('[HomeController] ✅ Internet reconnected. Re-fetching home layout...');
    await fetchHomeLayout();

    // ✅ Also refresh any previously loaded groups
    final loadedCategories = _categoryGroups.keys.toList();
    for (String categoryId in loadedCategories) {
      await fetchGroupsByCategory(categoryId, forceRefresh: true);
    }
  }

  Future<void> fetchHomeLayout() async {
    try {
      _isLoading.value = true;
      final result = await _service.getHomeLayout();
      if (result != null) {
        final productController = Get.find<ProductController>();
        for (var group in result.groups) {
          for (var product in group.products) {
            if (!productController.allProducts.any((p) => p.id == product.id)) {
              productController.allProducts.add(product);
            }
          }
        }
      }
      print("📥 Home layout fetched: $result");
      _homeData.value = result;

      // Pre-load banner images for all categories
      if (result != null) {
        for (var category in result.categories) {
          if (category.upperBanner != null && category.upperBanner!.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(category.upperBanner!), Get.context!); // Pre-cache upper banner
          }
          if (category.lowerBanner != null && category.lowerBanner!.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(category.lowerBanner!), Get.context!); // Pre-cache lower banner
          }
        }
        print("🖼️ All banner images pre-cached.");
      }
    } catch (e) {
      print("❌ Error fetching home layout: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  /// ✅ Enhanced fetchGroupsByCategory with proper loading states
  Future<void> fetchGroupsByCategory(String categoryId, {bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (_categoryGroups.containsKey(categoryId) && !forceRefresh) {
      print("📦 Groups already loaded for category: $categoryId");
      return;
    }

    // Skip if already loading
    if (_isLoadingGroups[categoryId] == true) {
      print("⏳ Groups already being fetched for category: $categoryId");
      return;
    }

    try {
      print("🚀 Starting to fetch groups for category: $categoryId");

      // ✅ Set loading state
      _isLoadingGroups[categoryId] = true;
      _groupErrors[categoryId] = null; // Clear previous errors

      final groups = await _service.getGroupsByCategory(categoryId);

      final productController = Get.find<ProductController>();
      for (var group in groups) {
        for (var product in group.products) {
          if (!productController.allProducts.any((p) => p.id == product.id)) {
            productController.allProducts.add(product);
          }
        }
      }

      // ✅ Store the fetched groups
      _categoryGroups[categoryId] = groups;
      print("✅ Groups fetched for category $categoryId: ${groups.length}");

    } catch (e) {
      print("❌ Error fetching groups for category $categoryId: $e");

      // ✅ Store error state
      _groupErrors[categoryId] = e.toString();

      // ✅ Set empty list on error to prevent infinite loading
      _categoryGroups[categoryId] = [];

    } finally {
      // ✅ Always clear loading state
      _isLoadingGroups[categoryId] = false;
    }
  }

  /// ✅ Add method to check if a specific category is loading
  bool isCategoryLoading(String categoryId) {
    return _isLoadingGroups[categoryId] == true;
  }

  /// ✅ Add method to check if a specific category has an error
  String? getCategoryError(String categoryId) {
    return _groupErrors[categoryId];
  }

  /// ✅ Add method to retry loading groups for a category
  Future<void> retryGroupsForCategory(String categoryId) async {
    _groupErrors[categoryId] = null;
    _categoryGroups.remove(categoryId); // Remove cached data
    await fetchGroupsByCategory(categoryId, forceRefresh: true);
  }

  /// ✅ Add method to clear all group data (useful for refresh)
  void clearAllGroups() {
    _categoryGroups.clear();
    _isLoadingGroups.clear();
    _groupErrors.clear();
  }

  /// ✅ Add method to refresh all data
  Future<void> refreshAllData() async {
    clearAllGroups();
    await fetchHomeLayout();
  }
}
