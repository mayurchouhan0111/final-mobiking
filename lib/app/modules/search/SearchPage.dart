import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
import 'dart:async';

import '../../controllers/SearchPageController.dart';
import '../../controllers/product_controller.dart';
import '../../services/product_service.dart';
import '../../themes/app_theme.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late final SearchPageController searchController;
  late final TextEditingController textController;
  late final FocusNode focusNode;
  late final ScrollController scrollController;
  late final AnimationController fadeController;
  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeControllers() {
    searchController = Get.put(SearchPageController());
    textController = TextEditingController();
    focusNode = FocusNode();
    scrollController = ScrollController();
  }

  void _initializeAnimations() {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));
    fadeController.forward();
  }

  Timer? _debounce;

  void _setupListeners() {
    textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        searchController.onSearchChanged(textController.text);
      });
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        searchController.loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    fadeController.dispose();
    Get.delete<SearchPageController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: fadeAnimation,
        child: Column(
          children: [
            _SearchHeader(
              textController: textController,
              focusNode: focusNode,
              searchController: searchController,
            ),
            Expanded(
              child: _SearchBody(
                scrollController: scrollController,
                searchController: searchController,
                textController: textController,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        if (cartController.totalCartItemsCount == 0) {
          return const SizedBox.shrink();
        }

        final List<String> imageUrls = cartController.cartItems.take(3).map((
          item,
        ) {
          final product = item['productId'];
          String? imageUrl;

          if (product is Map) {
            final imagesData = product['images'];
            if (imagesData is List && imagesData.isNotEmpty) {
              final firstImage = imagesData[0];
              if (firstImage is String) {
                imageUrl = firstImage;
              } else if (firstImage is Map) {
                imageUrl = firstImage['url'] as String?;
              }
            } else if (imagesData is String) {
              imageUrl = imagesData;
            }
          }
          return imageUrl ??
              'https://placehold.co/50x50/cccccc/ffffff?text=No+Img';
        }).toList();

        return FloatingCartButton(
          onTap: () {
            Get.to(
              () => CheckoutScreen(),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          },
          itemCount: cartController.totalCartItemsCount,
          productImageUrls: imageUrls,
        );
      }),
    );
  }
}

// ✅ Separated header widget for better performance
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.textController,
    required this.focusNode,
    required this.searchController,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final SearchPageController searchController;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: statusBarHeight + 80,
      width: double.infinity,
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(height: statusBarHeight),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SearchField(
                    textController: textController,
                    focusNode: focusNode,
                    searchController: searchController,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Optimized search field widget
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.textController,
    required this.focusNode,
    required this.searchController,
    required this.textTheme,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final SearchPageController searchController;
  final TextTheme textTheme;

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    textController.clear();
  }

  void _handleSubmit(String query) {
    searchController.addRecentSearch(query);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: focusNode.hasFocus
                ? AppColors.primaryPurple.withOpacity(0.9)
                : AppColors.lightPurple.withOpacity(0.2),
            width: focusNode.hasFocus ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: textController,
          focusNode: focusNode,
          onSubmitted: _handleSubmit,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primaryPurple,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
          decoration: InputDecoration(
            hintText: 'Search for products...',
            hintStyle: textTheme.bodySmall?.copyWith(
              color: AppColors.textLight.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            prefixIcon: AnimatedBuilder(
              animation: focusNode,
              builder: (context, _) => Icon(
                Icons.search_rounded,
                color: focusNode.hasFocus
                    ? AppColors.primaryPurple
                    : AppColors.textLight,
                size: 20,
              ),
            ),
            suffixIcon: Obx(
              () => searchController.showClearButton.value
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                      onPressed: _handleClear,
                    )
                  : const SizedBox.shrink(),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ✅ Main search body widget
class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.scrollController,
    required this.searchController,
    required this.textController,
  });

  final ScrollController scrollController;
  final SearchPageController searchController;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        _RecentSearches(
          searchController: searchController,
          textController: textController,
        ),
        _SearchResultsHeader(searchController: searchController),
        _SearchResults(
          searchController: searchController,
          textController: textController,
        ),
        _LoadMoreButton(searchController: searchController),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ✅ Recent searches widget
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searchController,
    required this.textController,
  });

  final SearchPageController searchController;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Obx(() {
        if (searchController.recentSearches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: searchController.clearRecentSearches,
                    child: Text(
                      'Clear All',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: searchController.recentSearches
                    .map(
                      (search) => _RecentSearchChip(
                        search: search,
                        textTheme: textTheme,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          textController.text = search;
                        },
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          searchController.removeRecentSearch(search);
                          if (textController.text == search) {
                            textController.clear();
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ✅ Individual recent search chip
class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({
    required this.search,
    required this.textTheme,
    required this.onTap,
    required this.onRemove,
  });

  final String search;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neutralBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightPurple.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  search,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Search results header
class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({required this.searchController});

  final SearchPageController searchController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'Search Results',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              if (searchController.displayedProducts.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${searchController.displayedProducts.length}'
                    '${searchController.hasMoreProducts.value ? '+' : ''}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

// ✅ Skeleton loading widget for product cards
class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
          // Content skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Shimmer wrapper for skeleton loading
class _ShimmerLoadingGrid extends StatelessWidget {
  const _ShimmerLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              period: const Duration(milliseconds: 1000),
              child: const _SkeletonProductCard(),
            );
          },
          childCount: 12, // Show 12 skeleton cards
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
          childAspectRatio: 0.50,
        ),
      ),
    );
  }
}

// ✅ Search results content with skeleton loading
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.searchController,
    required this.textController,
  });

  final SearchPageController searchController;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    final productController = searchController.productController;

    return Obx(() {
      // Validation message
      if (searchController.validationMessage.isNotEmpty) {
        return _MessageState(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.primaryPurple,
          title: searchController.validationMessage.value,
        );
      }

      // ✅ Loading state with skeleton
      if (productController.isLoading.value &&
          searchController.displayedProducts.isEmpty) {
        return const _ShimmerLoadingGrid();
      }

      // No results
      if (searchController.displayedProducts.isEmpty &&
          textController.text.isNotEmpty &&
          !productController.isLoading.value) {
        return _MessageState(
          icon: Icons.search_off_rounded,
          iconColor: AppColors.textLight,
          title: 'No results found',
          subtitle:
              'We couldn\'t find any products matching "${textController.text}"',
        );
      }

      // Empty state
      if (searchController.displayedProducts.isEmpty &&
          textController.text.isEmpty) {
        return _MessageState(
          icon: Icons.search_rounded,
          iconColor: AppColors.textLight,
          title: 'Start typing to search for products',
        );
      }

      // Results grid
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = searchController.displayedProducts[index];
            return RepaintBoundary(
              child: AllProductGridCard(
                key: ValueKey('search-${product.id}-$index'),
                product: product,
                heroTag: 'search-product-image-${product.id}-$index',
              ),
            );
          }, childCount: searchController.displayedProducts.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
            childAspectRatio: 0.50,
          ),
        ),
      );
    });
  }
}

// ✅ Load more button
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.searchController});

  final SearchPageController searchController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Obx(() {
        if (!searchController.hasMoreProducts.value ||
            searchController.displayedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: searchController.isLoadingMore.value
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading more...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      searchController.loadMoreProducts();
                    },
                    icon: Icon(Icons.expand_more, color: AppColors.white),
                    label: Text(
                      'Load More',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// ✅ Reusable message state widget
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
