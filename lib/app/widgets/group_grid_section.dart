import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/group_model.dart';
import '../data/product_model.dart';
import '../modules/Product_page/product_page.dart';
import '../modules/home/widgets/GroupProductsScreen.dart';
import 'package:mobiking/app/widgets/group_categories_section.dart';
import '../modules/home/widgets/AllProductGridCard.dart';

class GroupWithProductsSection extends StatefulWidget {
  final List<GroupModel> groups;

  const GroupWithProductsSection({super.key, required this.groups});

  @override
  State<GroupWithProductsSection> createState() =>
      _GroupWithProductsSectionState();
}

class _GroupWithProductsSectionState extends State<GroupWithProductsSection>
    with AutomaticKeepAliveClientMixin {
  final SubCategoryController subCategoryController =
      Get.find<SubCategoryController>();

  @override
  bool get wantKeepAlive => true; // 🚀 Keep widget alive to prevent rebuilds

  static const double horizontalContentPadding = 16.0;
  static const double gridCardHeight = 240.0;

  // 🚀 Cache for expensive computations
  final Map<String, List<ProductModel>> _inStockProductsCache = {};
  final Map<String, Color?> _backgroundColorCache = {};

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final TextTheme textTheme = Theme.of(context).textTheme;

    if (widget.groups.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      // 🚀 Isolate repaints
      child: ListView.builder(
        itemCount: widget.groups.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // 🚀 Performance optimizations
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        cacheExtent: 1000,
        itemBuilder: (context, index) {
          final group = widget.groups[index];

          if (group.products.isEmpty) return const SizedBox.shrink();

          // 🚀 Use cached in-stock products
          final inStockProducts = _getInStockProducts(group);
          if (inStockProducts.isEmpty) return const SizedBox.shrink();

          // 🚀 Use cached background color
          final sectionBackgroundColor = _getBackgroundColor(group);

          return RepaintBoundary(
            // 🚀 Isolate each group item
            key: ValueKey('group_$index'), // 🚀 Stable key for performance
            child: Container(
              color: sectionBackgroundColor,
              padding: EdgeInsets.symmetric(
                vertical: sectionBackgroundColor != null ? 6.0 : 0.0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalContentPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 🚀 Minimize layout
                  children: [
                    const SizedBox(height: 10),

                    // 🚀 Banner with RepaintBoundary
                    if (group.isBannerVisible &&
                        group.banner != null &&
                        group.banner!.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          if (group.isBannerLinkActive &&
                              group.bannerLink != null &&
                              group.bannerLink!.isNotEmpty) {
                            String urlString = group.bannerLink!;
                            if (!urlString.startsWith('http://') &&
                                !urlString.startsWith('https://')) {
                              urlString = 'https://' + urlString;
                            }
                            final Uri url = Uri.parse(urlString);
                            if (!await launchUrl(url)) {
                              throw Exception('Could not launch $url');
                            }
                          }
                        },
                        child: RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              color: AppColors.neutralBackground,
                              child: CachedNetworkImage(
                                imageUrl: group.banner!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accentNeon,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppColors.textLight,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (group.isBannerVisible &&
                        group.banner != null &&
                        group.banner!.isNotEmpty)
                      const SizedBox(height: 10),

                    if (group.parentCategories.isNotEmpty)
                      const SizedBox(height: 12),

                    if (group.parentCategories.isNotEmpty)
                      GroupCategoriesSection(
                        categories: group.parentCategories,
                        subCategoryController: subCategoryController,
                      ),

                    const SizedBox(height: 12),

                    // 🚀 Title with RepaintBoundary
                    RepaintBoundary(
                      child: Text(
                        group.name,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 12),
                    // 🚀 Grid with RepaintBoundary and optimizations
                    RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final productsToShow = inStockProducts
                              .take(6)
                              .toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 0,
                                  mainAxisSpacing: 0,
                                  childAspectRatio: 0.5,
                                ),
                            itemCount: productsToShow.length,
                            // 🚀 Performance settings
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            itemBuilder: (context, prodIndex) {
                              final product = productsToShow[prodIndex];
                              final String productHeroTag =
                                  'product_image_group_section_${group.id}_${product.id}_$prodIndex';

                              return AllProductGridCard(
                                product: product,
                                heroTag: productHeroTag,
                                onTap: (tappedProduct) {
                                  Get.to(
                                    () => ProductPage(
                                      product: tappedProduct,
                                      heroTag: productHeroTag,
                                    ),
                                    transition: Transition.fadeIn,
                                    duration: const Duration(milliseconds: 300),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 4),
                    // 🚀 Button with RepaintBoundary
                    RepaintBoundary(
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Get.to(() => GroupProductsScreen(group: group));
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: AppColors.success,
                                width: 1,
                              ),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See all products',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🚀 Optimized in-stock product filtering with caching
  List<ProductModel> _getInStockProducts(GroupModel group) {
    final cacheKey = '${group.id}_${group.products.length}';

    if (_inStockProductsCache.containsKey(cacheKey)) {
      return _inStockProductsCache[cacheKey]!;
    }

    final inStockProducts = <ProductModel>[];

    // 🚀 Early exit optimization
    for (final product in group.products) {
      bool hasStock = false;
      for (final variant in product.variants.entries) {
        if (variant.value > 0) {
          hasStock = true;
          break; // Exit variant loop early
        }
      }
      if (hasStock) {
        inStockProducts.add(product);
      }
    }

    _inStockProductsCache[cacheKey] = inStockProducts;
    return inStockProducts;
  }

  // 🚀 Optimized background color processing with caching
  Color? _getBackgroundColor(GroupModel group) {
    if (!group.isBackgroundColorVisible || group.backgroundColor == null) {
      return null;
    }

    final colorKey = group.backgroundColor!;
    if (_backgroundColorCache.containsKey(colorKey)) {
      return _backgroundColorCache[colorKey];
    }

    Color? sectionBackgroundColor;
    final tempBgColorString = group.backgroundColor!.trim();

    if (tempBgColorString.isNotEmpty &&
        tempBgColorString.toLowerCase() != "#ffffff") {
      try {
        final hex = tempBgColorString.replaceAll("#", "");
        if (hex.length == 6) {
          sectionBackgroundColor = Color(int.parse("FF$hex", radix: 16));
        }
      } catch (e) {
        sectionBackgroundColor = null;
      }
    }

    _backgroundColorCache[colorKey] = sectionBackgroundColor;
    return sectionBackgroundColor;
  }

  @override
  void dispose() {
    // 🚀 Clear caches on dispose
    _inStockProductsCache.clear();
    _backgroundColorCache.clear();
    super.dispose();
  }
}
