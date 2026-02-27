import 'package:flutter/material.dart';
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
  }

  Future<void> fetchHomeLayout({bool forceRefresh = false}) async {
    try {
      _isLoading.value = true;
      final result = await _service.getHomeLayout(forceRefresh: forceRefresh);
      if (result != null) {
        _homeData.value = result;

        // Pre-load banner images for all categories
        for (var category in result.categories) {
          if (category.upperBanner != null && category.upperBanner!.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(category.upperBanner!), Get.context!); // Pre-cache upper banner
          }
          if (category.lowerBanner != null && category.lowerBanner!.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(category.lowerBanner!), Get.context!); // Pre-cache lower banner
          }
        }
        print("🖼️ All banner images pre-cached.");

        // Process groups and group them by category
        _categoryGroups.clear();
for (var group in result.groups) {
          for (var categoryId in group.categories) {
            if (_categoryGroups.containsKey(categoryId)) {
              _categoryGroups[categoryId]!.add(group);
            } else {
              _categoryGroups[categoryId] = [group];
            }
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching home layout: $e");
    } finally {
      _isLoading.value = false;
    }
  }


  /// ✅ Add method to clear all group data (useful for refresh)
  void clearAllGroups() {
    _categoryGroups.clear();
  }

  /// ✅ Add method to refresh all data
  Future<void> refreshAllData() async {
    await fetchHomeLayout(forceRefresh: true);
  }
}
