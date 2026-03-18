import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/search/SearchPage.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../controllers/tab_controller_getx.dart';
import 'package:mobiking/app/controllers/home_controller.dart';
import 'CategoryTab.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';

class SearchTabSliverAppBar extends StatefulWidget {
  final TextEditingController? searchController;
  final void Function(String)? onSearchChanged;

  const SearchTabSliverAppBar({
    Key? key,
    this.searchController,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  _SearchTabSliverAppBarState createState() => _SearchTabSliverAppBarState();
}

class _SearchTabSliverAppBarState extends State<SearchTabSliverAppBar> {
  final List<String> _hintTexts = [
    'Search "Wireless Power Bank"',
    'Search "Calling Smartwatch"',
    'Search "Portable Speaker"',
    'Search "Wireless Gamepad"',
    'Search "Earbuds Neckband"',
    'Search "Charging Adapter"',
    'Search "Wireless Keyboard"',
    'Search "Wired Earphones"',
    'Search "Gaming Mouse"',
    'Search "Car Charger"',
    'Search "Mobile Stand"',
    'Search "Type-C Charging Cable"',
  ];

  late final RxInt _currentHintIndex;
  Timer? _hintTextTimer;

  final TabControllerGetX tabController = Get.put(TabControllerGetX());
  final SubCategoryController subCategoryController = Get.put(
    SubCategoryController(),
  );
  final HomeController homeController = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    _currentHintIndex = 0.obs;
    _startHintTextAnimation();
  }

  void _startHintTextAnimation() {
    _hintTextTimer?.cancel();
    _hintTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentHintIndex.value =
          (_currentHintIndex.value + 1) % _hintTexts.length;
    });
  }

  @override
  void dispose() {
    _hintTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickySearchAndTabBarDelegate(
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        hintTexts: _hintTexts,
        currentHintIndex: _currentHintIndex,
        tabController: tabController,
        subCategoryController: subCategoryController,
        homeController: homeController,
        safeAreaTop: topPadding,
        scaleFactor: (MediaQuery.of(context).size.width / 375.0).clamp(0.8, 1.25),
      ),
    );
  }
}

class _StickySearchAndTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController? searchController;
  final void Function(String)? onSearchChanged;
  final List<String> hintTexts;
  final RxInt currentHintIndex;
  final TabControllerGetX tabController;
  final SubCategoryController subCategoryController;
  final HomeController homeController;
  final double safeAreaTop;
  final double scaleFactor;
  _StickySearchAndTabBarDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.hintTexts,
    required this.currentHintIndex,
    required this.tabController,
    required this.subCategoryController,
    required this.homeController,
    required this.safeAreaTop,
    required this.scaleFactor,
  });

  @override
  double get maxExtent => 206 + safeAreaTop + (25 * (scaleFactor - 1.0)); // Accounts for dynamic status bar and resizing fonts/icons

  @override
  double get minExtent => 156 + safeAreaTop + (25 * (scaleFactor - 1.0)); // Accounts for dynamic status bar and resizing fonts/icons

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Calculate animation progress (0.0 to 1.0)
    final double animationProgress = (shrinkOffset / (maxExtent - minExtent))
        .clamp(0.0, 1.0);
    final bool isCollapsed = animationProgress > 0.5;
    final TextStyle? appThemeHintStyle = Theme.of(
      context,
    ).inputDecorationTheme.hintStyle;

    return Obx(() {
      String? backgroundImage;
      final int selectedTabIndex = tabController.selectedIndex.value;
      final categories = homeController.categories;

      if (categories.length > selectedTabIndex &&
          categories[selectedTabIndex].upperBanner != null &&
          categories[selectedTabIndex].upperBanner!.isNotEmpty) {
        backgroundImage = getResizedImageUrl(
          categories[selectedTabIndex].upperBanner!,
          600,
        );
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppColors.neutralBackground,
          image: backgroundImage != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(backgroundImage),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Collapsible Title Section ---
            SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: (1.0 - animationProgress) * 50, // Shrinks from 50 to 0
                child: Opacity(
                  opacity: 1.0 - animationProgress, // Fades out as it shrinks
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Mobiking Wholesale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Search Bar (Always Visible) ---
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Get.to(() => const SearchPage()),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: isCollapsed ? Colors.black : AppColors.textMedium,
                      ),
                      SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(animation);
                          return ClipRect(
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          hintTexts[currentHintIndex.value],
                          key: ValueKey<int>(currentHintIndex.value),
                          style: appThemeHintStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            // --- Category Tab Section (Always Visible) ---
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CustomTabBarSection(),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
