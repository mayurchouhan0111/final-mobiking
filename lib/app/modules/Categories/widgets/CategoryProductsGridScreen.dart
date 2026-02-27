import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/data/sub_category_model.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';

import '../../../data/product_model.dart';
import '../../../services/category_service.dart';
import '../../../themes/app_theme.dart';


class CategoryProductsGridScreen extends StatefulWidget {
  final String categoryName;
  final List<SubCategory> subCategories;
  final int initialSubCategoryIndex;

  const CategoryProductsGridScreen({
    Key? key,
    required this.categoryName,
    required this.subCategories,
    this.initialSubCategoryIndex = 0,
  }) : super(key: key);

  @override
  State<CategoryProductsGridScreen> createState() => _CategoryProductsGridScreenState();
}

class _CategoryProductsGridScreenState extends State<CategoryProductsGridScreen> {
  late RxInt selectedSubCategoryIndex;
  late RxList<ProductModel> displayedProducts;
  final CategoryService _categoryService = CategoryService();
  final RxBool _isLoadingProducts = false.obs;

  @override
  void initState() {
    super.initState();
    selectedSubCategoryIndex = widget.initialSubCategoryIndex.obs;
    displayedProducts = <ProductModel>[].obs;
    if (widget.subCategories.isNotEmpty) {
      _fetchProductsForSubCategory(widget.initialSubCategoryIndex);
    }
  }

  Future<void> _fetchProductsForSubCategory(int index) async {
    try {
      _isLoadingProducts.value = true;
      final products = await _categoryService.getProductsBySubCategorySlug(widget.subCategories[index].slug);
      
      // Sort: In stock (totalStock > 0) first, then out of stock
      products.sort((a, b) {
        if (a.totalStock > 0 && b.totalStock <= 0) return -1;
        if (a.totalStock <= 0 && b.totalStock > 0) return 1;
        return 0;
      });

      displayedProducts.value = products;
    } catch (e) {
      print(e);
      // Handle error, maybe show a snackbar
    } finally {
      _isLoadingProducts.value = false;
    }
  }

  void _onSubCategorySelected(int index) {
    selectedSubCategoryIndex.value = index;
    _fetchProductsForSubCategory(index);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Row(
        children: [
          // Left Side - Subcategories List
          Container(
            width: 80, // Narrowed to 80
            decoration: BoxDecoration(
              color: AppColors.neutralBackground,
              border: Border(
                right: BorderSide(
                  color: AppColors.lightGreyBackground,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // Subcategories List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0), // Removed horizontal padding here
                    itemCount: widget.subCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = widget.subCategories[index];

                      return Obx(() => _buildSubCategoryItem(
                        subCategory: subCategory,
                        index: index,
                        isSelected: selectedSubCategoryIndex.value == index,
                        onTap: () => _onSubCategorySelected(index),
                        textTheme: textTheme,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side - Products Grid
          Expanded(
            child: Container(
              color: AppColors.neutralBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products Header
                  Obx(() {
                    final selectedSubCategory = selectedSubCategoryIndex.value < widget.subCategories.length
                        ? widget.subCategories[selectedSubCategoryIndex.value]
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBackground,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.lightGreyBackground,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedSubCategory?.name ?? 'Products',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Obx(() => Text(
                              '${displayedProducts.length}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Products Grid
                  Expanded(
                    child: Obx(() {
                      if (_isLoadingProducts.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (displayedProducts.isEmpty) {
                        return _buildEmptyProductsState(textTheme);
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];
                          return AllProductGridCard(
                            product: product,
                            heroTag: 'category-product-${product.id}-$index',
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final cartController = Get.find<CartController>();
        final totalItemsInCart = cartController.totalCartItemsCount;
        if (totalItemsInCart == 0) {
          return const SizedBox.shrink();
        }

        final List<String> imageUrls = cartController.cartItems.take(3).map((item) {
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
          return imageUrl ?? 'https://placehold.co/50x50/cccccc/ffffff?text=No+Img';
        }).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: FloatingCartButton(
            label: "View Cart",
            productImageUrls: imageUrls,
            itemCount: totalItemsInCart,
            onTap: () {
              Get.to(() => CheckoutScreen());
            },
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSubCategoryItem({
    required SubCategory subCategory,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    final productCount = subCategory.products?.length ?? 0;
    final hasImage = (subCategory.photos?.isNotEmpty ?? false);
    final imageUrl = hasImage ? subCategory.photos!.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4), // Reduced vertical margin
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : AppColors.neutralBackground,
        border: isSelected
            ? Border(right: BorderSide(color: AppColors.success, width: 4))
            : null,
        borderRadius: isSelected
            ? BorderRadius.horizontal(right: Radius.circular(8))
            : null,
      ),
      child: Material(
        color: Colors.transparent, // Use transparent so the container's color is visible
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Image
                Container(
                  width: 60, // Slightly larger
                  height: 60, // Slightly larger
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyBackground,
                    borderRadius: BorderRadius.circular(10), // More rounded
                    border: Border.all(
                      color: AppColors.lightGreyBackground,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9), // Slightly smaller than container
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover, // Ensure image covers the area
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_outlined,
                        color: AppColors.textLight,
                        size: 36, // Larger icon
                      ),
                    )
                        : Icon(
                      Icons.category_outlined,
                      color: AppColors.textLight,
                      size: 36, // Larger icon
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Name
                Text(
                  subCategory.name ?? 'Unknown',
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected ? AppColors.success : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11, // Slightly smaller for better fit
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyProductsState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Available',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This category doesn\'t have any products yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}