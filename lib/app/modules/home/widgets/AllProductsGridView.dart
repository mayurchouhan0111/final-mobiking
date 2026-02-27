import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/product_model.dart';
import '../../../themes/app_theme.dart';
import '../../Product_page/product_page.dart';
import 'AllProductGridCard.dart';

class AllProductsGridView extends StatefulWidget {
  final List<ProductModel> products;
  final double horizontalPadding;
  final String title;
  final bool showTitle;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreProducts;

  const AllProductsGridView({
    super.key,
    required this.products,
    this.horizontalPadding = 0.0,
    this.title = "All Products",
    this.showTitle = true,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreProducts = true,
  });

  @override
  State<AllProductsGridView> createState() => _AllProductsGridViewState();
}

class _AllProductsGridViewState extends State<AllProductsGridView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoadingTriggered = false;
  ScrollController? _parentController;

  // 🚀 OPTIMIZATION: Cached filtered products
  List<ProductModel>? _cachedFilteredProducts;
  int? _lastProductHashCode;
  Timer? _scrollDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachToParentScroll();
    });
  }

  void _attachToParentScroll() {
    _parentController = PrimaryScrollController.of(context);
    if (_parentController != null) {
      _parentController!.addListener(_debouncedScrollListener);
    }
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _parentController?.removeListener(_debouncedScrollListener);
    super.dispose();
  }

  void _debouncedScrollListener() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        _onParentScroll();
      }
    });
  }

  void _onParentScroll() {
    if (_parentController == null || !_parentController!.hasClients) return;

    final maxScroll = _parentController!.position.maxScrollExtent;
    final currentScroll = _parentController!.position.pixels;

    if (currentScroll < maxScroll * 0.7) {
      _isLoadingTriggered = false;
    }

    if (currentScroll >= maxScroll * 0.85 && !_isLoadingTriggered) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (_isLoadingTriggered ||
        widget.isLoadingMore ||
        !widget.hasMoreProducts ||
        widget.onLoadMore == null)
      return;

    _isLoadingTriggered = true;

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onLoadMore!();
      }
    });
  }

  List<ProductModel> _getProductsToShow() {
    if (widget.products.isEmpty) return [];

    final currentHash = Object.hashAll(widget.products.map((p) => p.id));

    if (_cachedFilteredProducts != null &&
        _lastProductHashCode == currentHash) {
      return _cachedFilteredProducts!;
    }

    // Create a copy and sort by stock status
    final sortedProducts = List<ProductModel>.from(widget.products);

    sortedProducts.sort((a, b) {
      bool aInStock = a.totalStock > 0 || a.variants.values.any((v) => v > 0);
      bool bInStock = b.totalStock > 0 || b.variants.values.any((v) => v > 0);

      if (aInStock && !bInStock) return -1;
      if (!aInStock && bInStock) return 1;
      return 0;
    });

    _cachedFilteredProducts = sortedProducts;
    _lastProductHashCode = currentHash;

    return sortedProducts;
  }

  bool _isProductOutOfStock(ProductModel product) {
    return product.totalStock <= 0 &&
        !product.variants.values.any((v) => v > 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final textTheme = Theme.of(context).textTheme;
    final productsToShow = _getProductsToShow();

    if (widget.products.isEmpty && !widget.isLoadingMore) {
      return _buildEmptyState(context);
    }

    if (widget.products.isEmpty && widget.isLoadingMore) {
      return _buildLoadingState();
    }

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitle)
            RepaintBoundary(
              child: _buildTitleSection(textTheme, productsToShow.length),
            ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: _buildProductGrid(productsToShow, textTheme),
          ),

          if (widget.isLoadingMore) _buildLoadingIndicator(),

          if (!widget.hasMoreProducts && productsToShow.isNotEmpty)
            _buildEndMessage(textTheme),
        ],
      ),
    );
  }

  Widget _buildTitleSection(TextTheme textTheme, int productCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
      child: Row(
        children: [
          Text(
            widget.title,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$productCount',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products, TextTheme textTheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2.0),
      itemCount: products.length + (widget.isLoadingMore ? 3 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
        childAspectRatio: 0.56,
      ),
      cacheExtent: 1200,
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return RepaintBoundary(child: _buildShimmerCard());
        }

        final product = products[index];
        final isOutOfStock = _isProductOutOfStock(product);
        final heroTag = 'product_${product.id}_$index';

        return RepaintBoundary(
          child: GestureDetector(
            onTap: () => Get.to(
              () => ProductPage(product: product, heroTag: heroTag),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
            ),
            child: _buildProductCard(product, isOutOfStock, heroTag, textTheme),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    ProductModel product,
    bool isOutOfStock,
    String heroTag,
    TextTheme textTheme,
  ) {
    return Stack(
      children: [
        AllProductGridCard(product: product, heroTag: heroTag),

        if (isOutOfStock)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.primaryPurple,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEndMessage(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryPurple,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'You have seen all products!',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading products...',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: AppColors.textLight.withOpacity(0.3),
                  size: 24,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.textLight.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Products Found',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new products!',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
