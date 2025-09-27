import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/search/SearchPage.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../controllers/tab_controller_getx.dart';
import '../controllers/Home_controller.dart';
import 'CategoryTab.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class _SearchTabSliverAppBarState extends State<SearchTabSliverAppBar>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // 🚀 Prevent unnecessary rebuilds

  // 🚀 OPTIMIZATION: Reduced hint texts for better performance
  static const List<String> _hintTexts = [
    'Search products...',
    'Find electronics...',
    'Discover deals...',
  ];

  static const Duration _hintDuration = Duration(seconds: 4);

  late final RxInt _currentHintIndex;
  Timer? _hintTextTimer;

  // 🚀 OPTIMIZATION: Late final controllers to prevent repeated lookups
  late final TabControllerGetX _tabController;
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers once
    _tabController = Get.find<TabControllerGetX>();
    _homeController = Get.find<HomeController>();

    _currentHintIndex = 0.obs;
    _startHintAnimation();
  }

  void _startHintAnimation() {
    _hintTextTimer = Timer.periodic(_hintDuration, (timer) {
      if (mounted) {
        // 🚀 Use SchedulerBinding for smoother animations
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _currentHintIndex.value = (_currentHintIndex.value + 1) % _hintTexts.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return SliverPersistentHeader(
      pinned: true,
      delegate: _UltraOptimizedDelegate(
        hintTexts: _hintTexts,
        currentHintIndex: _currentHintIndex,
        tabController: _tabController,
        homeController: _homeController,
        onSearchTap: _handleSearchTap,
      ),
    );
  }

  void _handleSearchTap() {
    HapticFeedback.lightImpact(); // Better UX
    Get.to(() => const SearchPage(), transition: Transition.fadeIn);
  }
}

// 🚀 ULTRA-OPTIMIZED DELEGATE: Maximum performance
class _UltraOptimizedDelegate extends SliverPersistentHeaderDelegate {
  final List<String> hintTexts;
  final RxInt currentHintIndex;
  final TabControllerGetX tabController;
  final HomeController homeController;
  final VoidCallback onSearchTap;

  // 🚀 OPTIMIZATION: Aggressive caching with size limits
  static final Map<String, String> _imageCache = <String, String>{};
  static final Map<String, BoxDecoration> _decorationCache = <String, BoxDecoration>{};
  static const int _maxCacheSize = 15; // Prevent memory bloat

  // 🚀 OPTIMIZATION: Pre-computed constants
  static const double _maxExtent = 230;
  static const double _minExtent = 180;
  static const double _extentRange = _maxExtent - _minExtent;

  const _UltraOptimizedDelegate({
    required this.hintTexts,
    required this.currentHintIndex,
    required this.tabController,
    required this.homeController,
    required this.onSearchTap,
  });

  @override
  double get maxExtent => _maxExtent;
  @override
  double get minExtent => _minExtent;

  // 🚀 OPTIMIZATION: Lightning-fast image processing
  String? _getOptimizedBackgroundImage() {
    final selectedIndex = tabController.selectedIndex.value;
    final homeData = homeController.homeData;

    if (homeData == null || selectedIndex >= homeData.categories.length) {
      return null;
    }

    final upperBanner = homeData.categories[selectedIndex].upperBanner;
    if (upperBanner == null || upperBanner.isEmpty) return null;

    // Use cached result
    if (_imageCache.containsKey(upperBanner)) {
      return _imageCache[upperBanner];
    }

    // Process image URL - Convert GIF to WebP for better performance
    String processedUrl = upperBanner;
    if (upperBanner.toLowerCase().contains('.gif')) {
      processedUrl = upperBanner.replaceAll('.gif', '.webp') + '?q=60&w=800&h=400';
    }

    // Cache with size limit
    if (_imageCache.length < _maxCacheSize) {
      _imageCache[upperBanner] = processedUrl;
    }

    return processedUrl;
  }

  // 🚀 OPTIMIZATION: Cached decoration creation
  BoxDecoration _getBoxDecoration(String? imageUrl, bool isCollapsed) {
    final cacheKey = '${imageUrl ?? 'null'}_$isCollapsed';

    return _decorationCache.putIfAbsent(cacheKey, () {
      if (imageUrl == null) {
        return BoxDecoration(color: isCollapsed ? Colors.black45 : null);
      }

      return BoxDecoration(
        color: isCollapsed ? Colors.black45 : null,
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            imageUrl,
            maxWidth: 800,
            maxHeight: 400,
            cacheKey: imageUrl,
          ),
          fit: BoxFit.cover,
          colorFilter: isCollapsed
              ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
              : null,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 🚀 Pre-compute all values at once
    final progress = (shrinkOffset / _extentRange).clamp(0.0, 1.0);
    final isCollapsed = progress > 0.5;
    final titleOpacity = (1.0 - progress).clamp(0.0, 1.0);
    final titleHeight = titleOpacity * 50;

    // Get optimized background
    final backgroundImage = _getOptimizedBackgroundImage();
    final decoration = _getBoxDecoration(backgroundImage, isCollapsed);

    return Container(
      padding: const EdgeInsets.only(top: 4),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🚀 Minimize layout calculations
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 Conditional title - only render when visible
          if (titleHeight > 5)
            SizedBox(
              height: titleHeight,
              child: SafeArea(
                child: Opacity(
                  opacity: titleOpacity,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Mobiking Wholesale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 🚀 Optimized search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _SearchBar(
              onTap: onSearchTap,
              isCollapsed: isCollapsed,
              hintTexts: hintTexts,
              currentHintIndex: currentHintIndex,
            ),
          ),

          // 🚀 Category tabs
           CustomTabBarSection(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    // 🚀 More specific rebuild conditions
    if (identical(this, oldDelegate)) return false;
    if (oldDelegate is! _UltraOptimizedDelegate) return true;

    return oldDelegate.currentHintIndex.value != currentHintIndex.value ||
        oldDelegate.tabController.selectedIndex.value != tabController.selectedIndex.value;
  }

  // 🚀 Disable unnecessary configurations
  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration => null;
  @override
  OverScrollHeaderStretchConfiguration? get stretchConfiguration => null;
  @override
  PersistentHeaderShowOnScreenConfiguration? get showOnScreenConfiguration => null;
}

// 🚀 OPTIMIZATION: Separate SearchBar widget
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCollapsed;
  final List<String> hintTexts;
  final RxInt currentHintIndex;

  const _SearchBar({
    required this.onTap,
    required this.isCollapsed,
    required this.hintTexts,
    required this.currentHintIndex,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // Direct color for performance
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isCollapsed ? Colors.black : AppColors.textMedium,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HintText(
                hintTexts: hintTexts,
                currentHintIndex: currentHintIndex,
                isCollapsed: isCollapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 OPTIMIZATION: Dedicated HintText widget
class _HintText extends StatelessWidget {
  final List<String> hintTexts;
  final RxInt currentHintIndex;
  final bool isCollapsed;

  const _HintText({
    required this.hintTexts,
    required this.currentHintIndex,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle;

    return Obx(() => AnimatedSwitcher(
      duration: const Duration(milliseconds: 150), // Faster animation
      child: Text(
        hintTexts[currentHintIndex.value],
        key: ValueKey(currentHintIndex.value),
        style: hintStyle?.copyWith(
          overflow: TextOverflow.ellipsis,
          color: isCollapsed ? Colors.black87 : hintStyle?.color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ));
  }
}
