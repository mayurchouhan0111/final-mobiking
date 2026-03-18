import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/product_controller.dart';

import 'package:mobiking/app/controllers/home_controller.dart';
import '../controllers/sub_category_controller.dart';
import '../controllers/tab_controller_getx.dart';
import '../data/Home_model.dart';
import '../modules/home/widgets/_buildSectionView.dart';
import 'package:shimmer/shimmer.dart';
import '../themes/app_theme.dart';
import '../modules/home/loading/ShimmerBanner.dart';
import '../modules/home/loading/ShimmerGroupSection.dart';
import '../modules/home/loading/ShimmerProductGrid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';

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

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateIndicatorPosition(),
    );
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
      final RenderBox? tabRenderBox =
          _tabKeys[selectedIndex].currentContext?.findRenderObject()
              as RenderBox?;
      final RenderBox? stackRenderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;

      if (tabRenderBox != null && stackRenderBox != null) {
        final double tabGlobalX = tabRenderBox.localToGlobal(Offset.zero).dx;
        final double stackGlobalX = stackRenderBox
            .localToGlobal(Offset.zero)
            .dx;

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
      final RenderBox? tabRenderBox =
          _tabKeys[selectedIndex].currentContext?.findRenderObject()
              as RenderBox?;
      final RenderBox? scrollViewRenderBox =
          _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? stackRenderBox =
          _containerKey.currentContext?.findRenderObject()
              as RenderBox?; // _containerKey is on the Container that wraps the Stack

      if (tabRenderBox != null &&
          scrollViewRenderBox != null &&
          stackRenderBox != null) {
        // Removed debugPrint for performance
        // Calculate indicator position relative to the Stack
        final double tabGlobalX = tabRenderBox.localToGlobal(Offset.zero).dx;
        final double stackGlobalX = stackRenderBox
            .localToGlobal(Offset.zero)
            .dx;

        if (mounted) {
          setState(() {
            _indicatorWidth = tabRenderBox.size.width;
            _indicatorPosition =
                tabGlobalX - stackGlobalX; // Position relative to the Stack
          });
        }

        // Calculate target scroll offset for the SingleChildScrollView
        final double tabLocalXInScrollView = tabRenderBox
            .localToGlobal(Offset.zero, ancestor: scrollViewRenderBox)
            .dx;
        final double tabCenterInScrollView =
            tabLocalXInScrollView + (tabRenderBox.size.width / 2);
        final double screenCenter = MediaQuery.of(context).size.width / 2;
        final double targetScrollOffset = tabCenterInScrollView - screenCenter;

        final double maxScrollExtent =
            _tabScrollController.position.maxScrollExtent;
        final double minScrollExtent =
            _tabScrollController.position.minScrollExtent;

        final double clampedScrollOffset = targetScrollOffset.clamp(
          minScrollExtent,
          maxScrollExtent,
        );

        if (_tabScrollController.hasClients) {
          _tabScrollController.animateTo(
            clampedScrollOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // Removed debugPrint
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
    required double iconSize,
    required double fontSize,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: iconSize,
              width: iconSize,
              child: Builder(
                builder: (context) {
                  try {
                    final decodedSvg = htmlUnescape(icon);
                    return SvgPicture.string(
                      decodedSvg,
                      color: iconAndTextColor,
                    );
                  } catch (e) {
                    return Icon(
                      Icons.broken_image,
                      size: 20,
                      color: iconAndTextColor,
                    );
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
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: iconAndTextColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.25);
    final double dynamicIconSize = 22.0 * scaleFactor;
    final double dynamicFontSize = 11.0 * scaleFactor;

    return Obx(() {
      final List<CategoryModel> categories = homeController.categories;

      if (homeController.isLoading && categories.isEmpty) {
        return SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // Ensure _tabKeys has the correct length
      if (_tabKeys.length != categories.length) {
        _tabKeys = List.generate(categories.length, (index) => GlobalKey());
        // Recalculate position after keys are updated
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateIndicatorPosition(),
        );
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
                  final isSelected =
                      tabControllerGetX.selectedIndex.value == index;
                  final theme = category.theme ?? 'dark';
                  final Color tabColor = theme == 'light'
                      ? Colors.white
                      : Colors.black;

                  return _buildTabItem(
                    key: _tabKeys[index],
                    icon: category.icon ?? '',
                    label: category.name,
                    isSelected: isSelected,
                    onTap: () => tabControllerGetX.updateIndex(index),
                    iconAndTextColor: tabColor,
                    textTheme: textTheme,
                    iconSize: dynamicIconSize,
                    fontSize: dynamicFontSize,
                  );
                }),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _indicatorPosition,
              bottom: -6, // Shifted downwards from 0 to -6 to prevent bumping into text
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

// CustomTabBarViewSection was removed because it was replaced by a high-performance TabBarView in NestedScrollView inside home_screen.dart
