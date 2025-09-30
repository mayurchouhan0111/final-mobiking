import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/product_controller.dart';


import '../controllers/home_controller.dart';
import '../controllers/sub_category_controller.dart';
import '../controllers/tab_controller_getx.dart';
import '../data/Home_model.dart';
import '../modules/home/widgets/_buildSectionView.dart';
import '../themes/app_theme.dart';

class CustomTabBarSection extends StatefulWidget {
  CustomTabBarSection({super.key});

  @override
  State<CustomTabBarSection> createState() => _CustomTabBarSectionState();
}

class _CustomTabBarSectionState extends State<CustomTabBarSection> {
  final HomeController homeController = Get.find<HomeController>();
  final TabControllerGetX tabControllerGetX = Get.find<TabControllerGetX>();

  late List<GlobalKey> _tabKeys;
  double _indicatorWidth = 0.0;
  double _indicatorPosition = 0.0;

  late ScrollController _tabScrollController;
  final GlobalKey _scrollViewKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabScrollController = ScrollController();
    _tabKeys = []; // Initialize as empty list
    tabControllerGetX.selectedIndex.listen((_) => _updateIndicatorPosition());

    // Add scroll listener to update indicator position during scroll
    _tabScrollController.addListener(() {
      _updateIndicatorPositionOnly();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicatorPosition());
  }

  @override
  void dispose() {
    _tabScrollController.removeListener(_updateIndicatorPositionOnly);
    _tabScrollController.dispose();
    super.dispose();
  }

  // Method to update indicator position during scroll without animating scroll
  void _updateIndicatorPositionOnly() {
    final selectedIndex = tabControllerGetX.selectedIndex.value;
    if (selectedIndex >= 0 && selectedIndex < _tabKeys.length) {
      final RenderBox? tabRenderBox = _tabKeys[selectedIndex].currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? stackRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;

      if (tabRenderBox != null && stackRenderBox != null) {
        final double tabGlobalX = tabRenderBox.localToGlobal(Offset.zero).dx;
        final double stackGlobalX = stackRenderBox.localToGlobal(Offset.zero).dx;

        if (mounted) {
          setState(() {
            _indicatorWidth = tabRenderBox.size.width;
            _indicatorPosition = tabGlobalX - stackGlobalX;
          });
        }
      }
    }
  }

  void _updateIndicatorPosition() {
    final selectedIndex = tabControllerGetX.selectedIndex.value;
    if (selectedIndex >= 0 && selectedIndex < _tabKeys.length) {
      final RenderBox? tabRenderBox = _tabKeys[selectedIndex].currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? scrollViewRenderBox = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? stackRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?; // _containerKey is on the Container that wraps the Stack

      if (tabRenderBox != null && scrollViewRenderBox != null && stackRenderBox != null) {
        debugPrint('CustomTabBarSection: _updateIndicatorPosition - selectedIndex: $selectedIndex, tabRenderBox: $tabRenderBox, scrollViewRenderBox: $scrollViewRenderBox, stackRenderBox: $stackRenderBox');
        // Calculate indicator position relative to the Stack
        final double tabGlobalX = tabRenderBox.localToGlobal(Offset.zero).dx;
        final double stackGlobalX = stackRenderBox.localToGlobal(Offset.zero).dx;

        if (mounted) {
          setState(() {
            _indicatorWidth = tabRenderBox.size.width;
            _indicatorPosition = tabGlobalX - stackGlobalX; // Position relative to the Stack
          });
        }

        // Calculate target scroll offset for the SingleChildScrollView
        final double tabLocalXInScrollView = tabRenderBox.localToGlobal(Offset.zero, ancestor: scrollViewRenderBox).dx;
        final double tabCenterInScrollView = tabLocalXInScrollView + (tabRenderBox.size.width / 2);
        final double screenCenter = MediaQuery.of(context).size.width / 2;
        final double targetScrollOffset = tabCenterInScrollView - screenCenter;

        final double maxScrollExtent = _tabScrollController.position.maxScrollExtent;
        final double minScrollExtent = _tabScrollController.position.minScrollExtent;

        final double clampedScrollOffset = targetScrollOffset.clamp(minScrollExtent, maxScrollExtent);

        if (_tabScrollController.hasClients) {
          _tabScrollController.animateTo(
            clampedScrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        debugPrint('CustomTabBarSection: _updateIndicatorPosition - RenderBox is null. tabRenderBox: $tabRenderBox, scrollViewRenderBox: $scrollViewRenderBox, stackRenderBox: $stackRenderBox');
      }
    }
  }

  String htmlUnescape(String input) {
    return input
        .replaceAll(r'\u003C', '<')
        .replaceAll(r'\u003E', '>')
        .replaceAll(r'\u0022', '"')
        .replaceAll(r'\u0027', "'")
        .replaceAll(r'\\', '');
  }

  Widget _buildTabItem({
    required Key key,
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color iconAndTextColor,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: Builder(
              builder: (context) {
                try {
                  final decodedSvg = htmlUnescape(icon);
                  return SvgPicture.string(decodedSvg, color: iconAndTextColor);
                } catch (e) {
                  return Icon(Icons.broken_image, size: 20, color: iconAndTextColor);
                }
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: iconAndTextColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final HomeLayoutModel? homeLayout = homeController.homeData;
      final List<CategoryModel> categories = homeLayout?.categories ?? [];

      if (homeController.isLoading || categories.isEmpty) {
        debugPrint('CustomTabBarSection: Loading or categories empty. isLoading: ${homeController.isLoading}, categories.length: ${categories.length}');
        return const SizedBox(
          height: 70,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.white),
          ),
        );
      }
      // Ensure _tabKeys has the correct length
      if (_tabKeys.length != categories.length) {
        _tabKeys = List.generate(categories.length, (index) => GlobalKey());
        // Recalculate position after keys are updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicatorPosition());
      }

      return Container(
        key: _containerKey,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              key: _scrollViewKey,
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  final isSelected = tabControllerGetX.selectedIndex.value == index;
                  final theme = category.theme ?? 'dark';
                  final Color tabColor = theme == 'light' ? Colors.white : Colors.black;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildTabItem(
                      key: _tabKeys[index],
                      icon: category.icon ?? '',
                      label: category.name,
                      isSelected: isSelected,
                      onTap: () => tabControllerGetX.updateIndex(index),
                      iconAndTextColor: tabColor,
                      textTheme: textTheme,
                    ),
                  );
                }),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _indicatorPosition,
              bottom: 0,
              width: _indicatorWidth,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Changed to white
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3), // Changed to white
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class CustomTabBarViewSection extends StatelessWidget {
  final TabControllerGetX controller = Get.find<TabControllerGetX>();
  final HomeController homeController = Get.find<HomeController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>();

  CustomTabBarViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final HomeLayoutModel? homeLayout = homeController.homeData;
      final List<CategoryModel> categories = homeLayout?.categories ?? [];
      final selectedIndex = controller.selectedIndex.value;

      // Initial Loading State
      if (homeController.isLoading || categories.isEmpty) {
        return Container(
          height: 300,
          color: AppColors.neutralBackground,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accentNeon),
          ),
        );
      }

      // IndexedStack for Cached Tab Views
      return IndexedStack(
        index: selectedIndex,
        children: List.generate(categories.length, (index) {
          final category = categories[index];
          final categoryId = category.id;

          // Fetch group data only once
          if (!homeController.categoryGroups.containsKey(categoryId)) {
            homeController.fetchGroupsByCategory(categoryId);
          }

          // ✅ Reset and fetch products when category changes

          final updatedGroups = homeController.categoryGroups[categoryId] ?? [];
          final String bannerImageUrlToUse = category.lowerBanner ?? '';

          return Offstage(
            offstage: selectedIndex != index,
            child: TickerMode(
              enabled: selectedIndex == index,
              child: buildSectionView(
                productController: productController,
                index: index,
                groups: updatedGroups,
                bannerImageUrl: bannerImageUrlToUse,
                categoryGridItems: subCategoryController.subCategories,
                subCategories: subCategoryController.subCategories,
              ),
            ),
          );
        }),
      );
    });
  }
}