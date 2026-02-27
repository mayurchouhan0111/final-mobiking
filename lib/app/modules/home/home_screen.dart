import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import '../../controllers/cart_controller.dart' show CartController;
import '../../controllers/category_controller.dart';
import 'package:mobiking/app/controllers/home_controller.dart';
import '../../controllers/sub_category_controller.dart';
import '../../controllers/tab_controller_getx.dart';
import '../../controllers/product_controller.dart';
import '../../themes/app_theme.dart';
import '../../widgets/CustomBottomBar.dart';
import '../../widgets/CategoryTab.dart';
import '../../widgets/CustomAppBar.dart';
import '../../widgets/SearchTabSliverAppBar.dart' show SearchTabSliverAppBar;

import 'package:mobiking/app/modules/home/widgets/HomeShimmer.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController =
      Get.find<SubCategoryController>();
  final TabControllerGetX tabController = Get.find<TabControllerGetX>();
  final ProductController productController = Get.find<ProductController>();
  final HomeController homeController = Get.find<HomeController>();

  late ScrollController _scrollController;
  final RxBool _showScrollToTopButton = false.obs;

  @override
  void initState() {
    super.initState();
    productController.refreshProducts();
    categoryController.refreshCategories();
    subCategoryController.refreshSubCategories();
    homeController.refreshAllData();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 200 && !_showScrollToTopButton.value) {
      _showScrollToTopButton.value = true;
    } else if (_scrollController.offset < 200 && _showScrollToTopButton.value) {
      _showScrollToTopButton.value = false;
    }

    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.75) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (productController.isFetchingMore.value ||
        !productController.hasMoreProducts.value)
      return;

    print("🚀 Infinite scroll triggered from HomeScreen");
    productController.fetchMoreProducts();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh() async {
    print("🔄 Manual refresh triggered from HomeScreen");
    await Future.wait([
      productController.refreshProducts(),
      categoryController.refreshCategories(),
      subCategoryController.refreshSubCategories(),
      homeController.refreshAllData(),
    ]);
    print("✅ All data refreshed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AppColors.neutralBackground,
      appBar: null,
      body: Stack(
        children: [
          Obx(() {
            if (homeController.isLoading && homeController.homeData == null) {
              return const HomeShimmer();
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primaryPurple,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SearchTabSliverAppBar(
                    onSearchChanged: (value) {
                      print('Search query: $value');
                    },
                  ),
                  SliverToBoxAdapter(child: CustomTabBarViewSection()),
                  Obx(() {
                    if (productController.isFetchingMore.value) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }),
                ],
              ),
            );
          }),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: Obx(
              () => AnimatedOpacity(
                opacity: _showScrollToTopButton.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showScrollToTopButton.value
                    ? FloatingActionButton(
                        mini: true,
                        backgroundColor: AppColors.darkPurple,
                        onPressed: _scrollToTop,
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
