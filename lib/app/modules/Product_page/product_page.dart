// lib/screens/product_page.dart

import 'dart:math';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/modules/home/widgets/AllProductGridCard.dart';
import 'package:mobiking/app/modules/home/widgets/ProductCard.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../../data/product_model.dart';
import '../home/widgets/app_star_rating.dart';
import 'widgets/product_image_banner.dart';
// REMOVED: import 'widgets/product_title_price.dart';
import 'widgets/featured_product_banner.dart';
import 'widgets/collapsible_section.dart';
import 'widgets/animated_cart_button.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';

class ProductPage extends StatefulWidget {
  final ProductModel product;
  final String heroTag;

  const ProductPage({
    super.key,
    required this.product,
    required this.heroTag,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with SingleTickerProviderStateMixin {
  int selectedVariantIndex = 0;
  final TextEditingController _pincodeController = TextEditingController();
  final RxBool _isCheckingDelivery = false.obs;
  final RxString _deliveryStatusMessage = ''.obs;
  final RxBool _isDeliverable = false.obs;
  final CartController cartController = Get.find();
  final ProductController productController = Get.find();
  final WishlistController wishlistController = Get.find();
  final RxInt _currentVariantStock = 0.obs;
  final RxString _currentSelectedVariantName = ''.obs;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  final RxBool _productDetailsVisible = false.obs;
  static const double _horizontalPagePadding = 16.0;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      int firstAvailableIndex = -1;
      for (int i = 0; i < widget.product.variants.length; i++) {
        final variantKey = widget.product.variants.keys.elementAt(i);
        if ((widget.product.variants[variantKey] ?? 0) > 0) {
          firstAvailableIndex = i;
          break;
        }
      }
      if (firstAvailableIndex != -1) {
        selectedVariantIndex = firstAvailableIndex;
        _currentSelectedVariantName.value = widget.product.variants.keys.elementAt(selectedVariantIndex);
      } else {
        selectedVariantIndex = 0;
        _currentSelectedVariantName.value = widget.product.variants.keys.elementAt(selectedVariantIndex);
      }
    } else {
      _currentSelectedVariantName.value = 'Default Variant';
    }

    _pincodeController.addListener(_resetDeliveryStatus);
    _syncVariantData();

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimationController.forward();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _animationCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_resetDeliveryStatus);
    _pincodeController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _resetDeliveryStatus() {
    if (_deliveryStatusMessage.isNotEmpty) {
      _deliveryStatusMessage.value = '';
      _isDeliverable.value = false;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_slideAnimationController.status != AnimationStatus.forward) {
        _slideAnimationController.forward();
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (_slideAnimationController.status != AnimationStatus.reverse) {
        _slideAnimationController.reverse();
      }
    }
  }

  void onVariantSelected(String selectedVariantName) {
    final variantStockValue = widget.product.variants[selectedVariantName] ?? 0;
    final isVariantOutOfStock = variantStockValue <= 0;

    if (!isVariantOutOfStock) {
      setState(() {
        selectedVariantIndex = widget.product.variants.keys.toList().indexOf(selectedVariantName);
        _currentSelectedVariantName.value = selectedVariantName;
        _syncVariantData();
      });
    } else {
      Get.snackbar(
        'Out of Stock',
        'This variant is currently out of stock.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.info_outline, color: Colors.white),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _syncVariantData() {
    if (widget.product.variants.isNotEmpty &&
        selectedVariantIndex >= 0 &&
        selectedVariantIndex < widget.product.variants.length) {
      final variantKey = widget.product.variants.keys.elementAt(selectedVariantIndex);
      final variantStockValue = widget.product.variants[variantKey] ?? 0;
      debugPrint('ProductPage: _syncVariantData - Variant: $variantKey, Stock: $variantStockValue');
      _currentVariantStock.value = variantStockValue;
    } else {
      debugPrint('ProductPage: _syncVariantData - Using totalStock: ${widget.product.totalStock}');
      _currentVariantStock.value = widget.product.totalStock;
    }
  }

  Future<void> _incrementQuantity() async {
    final String productId = widget.product.id.toString();
    final String variantName = _currentSelectedVariantName.value;
    final quantityInCart = cartController.getVariantQuantity(
      productId: productId,
      variantName: variantName,
    );
    if (cartController.isLoading.value || _currentVariantStock.value <= 0 ||
        _currentVariantStock.value <= quantityInCart) {
      return;
    }

    cartController.isLoading.value = true;
    try {
      await cartController.addToCart(productId: productId, variantName: variantName);
    } finally {
      cartController.isLoading.value = false;
    }
  }

  Future<void> _decrementQuantity() async {
    final String productId = widget.product.id.toString();
    final String variantName = _currentSelectedVariantName.value;
    final quantityInCart = cartController.getVariantQuantity(
      productId: productId,
      variantName: variantName,
    );
    if (quantityInCart <= 0 || cartController.isLoading.value) return;
    cartController.isLoading.value = true;
    try {
      await cartController.removeFromCart(productId: productId, variantName: variantName);
    } finally {
      cartController.isLoading.value = false;
    }
  }

  // FIXED HTML conversion method
  String _convertHtmlToPlainText(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      String text = document.body?.text ?? '';

      // Clean up extra whitespace
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      return text;
    } catch (e) {
      // Fallback: strip HTML tags manually
      return htmlString
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'&quot;'), '"')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }

  // COMPLETELY REWRITTEN HTML sanitization method
  String _sanitizeHtml(String htmlString) {
    if (htmlString.isEmpty) return htmlString;

    // Debug print to see what we're working with
    print("Original HTML (first 200 chars): ${htmlString.substring(0, min(200, htmlString.length))}...");

    // Remove any script tags for security
    htmlString = htmlString.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');

    // Remove any style tags that might contain problematic CSS
    htmlString = htmlString.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');

    // Fix common HTML entities
    htmlString = htmlString.replaceAll(RegExp(r'&nbsp;'), ' ');
    htmlString = htmlString.replaceAll(RegExp(r'&amp;'), '&');
    htmlString = htmlString.replaceAll(RegExp(r'&lt;'), '<');
    htmlString = htmlString.replaceAll(RegExp(r'&gt;'), '>');
    htmlString = htmlString.replaceAll(RegExp(r'&quot;'), '"');
    htmlString = htmlString.replaceAll(RegExp(r'&#39;'), "'");

    // Remove ALL inline styles to prevent CSS variable issues
    htmlString = htmlString.replaceAll(RegExp(r'style="[^"]*"'), '');

    // Remove class attributes that might reference unavailable CSS
    htmlString = htmlString.replaceAll(RegExp(r'class="[^"]*"'), '');

    // Clean up any remaining CSS variables or complex selectors
    htmlString = htmlString.replaceAll(RegExp(r'var\([^)]*\)'), '');

    // Remove any remaining problematic attributes
    htmlString = htmlString.replaceAll(RegExp(r'(data-[^=]*="[^"]*")'), '');
    htmlString = htmlString.replaceAll(RegExp(r'(id="[^"]*")'), '');

    // Remove empty paragraphs and divs
    htmlString = htmlString.replaceAll(RegExp(r'<p[^>]*>\s*</p>'), '');
    htmlString = htmlString.replaceAll(RegExp(r'<div[^>]*>\s*</div>'), '');

    // Clean up multiple consecutive whitespaces and line breaks
    htmlString = htmlString.replaceAll(RegExp(r'\s+'), ' ').trim();

    print("Sanitized HTML (first 200 chars): ${htmlString.substring(0, min(200, htmlString.length))}...");

    return htmlString;
  }

  // COMPLETELY REWRITTEN Enhanced Product Description Widget
  Widget _buildEnhancedProductDescription(
      String htmlDescription,
      TextTheme textTheme,
      bool isExpanded, // pass this state from parent
      ) {
    if (htmlDescription.isEmpty) return const SizedBox.shrink();

    String sanitizedHtml = _sanitizeHtml(htmlDescription);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isExpanded
                ? _buildDescriptionContent(sanitizedHtml, textTheme)
                : const SizedBox.shrink(), // nothing shown when closing
          ),
        ],
      ),
    );
  }

  // NEW method to handle description content with fallback
  Widget _buildDescriptionContent(String htmlDescription, TextTheme textTheme) {
    try {
      // First try: Use Html widget with comprehensive styling
      return Html(
        data: htmlDescription,
        style: {
          // Base body styling
          "body": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.6),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontFamily: 'Roboto',
          ),

          // Paragraph styling
          "p": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.5),
            margin: Margins.only(bottom: 12.0),
            padding: HtmlPaddings.zero,
          ),

          // Div styling
          "div": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.5),
            margin: Margins.only(bottom: 8.0),
          ),

          // Heading styles
          "h1": Style(
            fontSize: FontSize(22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 16.0),
          ),
          "h2": Style(
            fontSize: FontSize(20.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 14.0),
          ),
          "h3": Style(
            fontSize: FontSize(18.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 12.0),
          ),

          // List styling
          "ul": Style(
            margin: Margins.only(bottom: 16.0, left: 16.0),
            padding: HtmlPaddings.zero,
          ),
          "ol": Style(
            margin: Margins.only(bottom: 16.0, left: 16.0),
            padding: HtmlPaddings.zero,
          ),
          "li": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.6),
            margin: Margins.only(bottom: 8.0),
            display: Display.listItem,
          ),

          // Span styling
          "span": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
          ),

          // Text formatting
          "strong": Style(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          "b": Style(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          "em": Style(
            fontStyle: FontStyle.italic,
          ),
          "i": Style(
            fontStyle: FontStyle.italic,
          ),

          // Break tag
          "br": Style(
            fontSize: FontSize(8.0),
          ),

          // Override any problematic styles
          "*": Style(
            backgroundColor: Colors.transparent,
          ),
        },

        // Remove problematic extensions
        extensions: const [],

        // Handle link taps
        onLinkTap: (url, attributes, element) {
          print("Link tapped: $url");
        },

        shrinkWrap: true,
      );
    } catch (e) {
      print("HTML rendering failed: $e");

      // Fallback: Use plain text with proper formatting
      return Text(
        _convertHtmlToPlainText(htmlDescription),
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textMedium,
          height: 1.6,
          fontSize: 14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double sellingPrice;
    String discountBadgeText = '';
    final double? originalPrice = product.regularPrice?.toDouble();

    if (product.sellingPrice.isNotEmpty) {
      sellingPrice = product.sellingPrice.map((e) => e.price.toDouble()).reduce(min);
      final maxPrice = product.sellingPrice.map((e) => e.price.toDouble()).reduce(max);
      final actualPrice = originalPrice ?? maxPrice;
      if (actualPrice > sellingPrice) {
        double discount = ((actualPrice - sellingPrice) / actualPrice) * 100;
        discountBadgeText = '${discount.round()}% OFF';
      }
    } else {
      sellingPrice = 0.0;
    }

    final variantNames = product.variants.keys.toList();
    final inStockVariantNames = variantNames.where((name) {
      final variantStockValue = product.variants[name] ?? 0;
      return variantStockValue > 0;
    }).toList();

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _animationCompleted = false;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Banner
                    Obx(() {
                      final isFavorite = wishlistController.wishlist.any((p) => p.id == product.id);
                      return ProductImageBanner(
                        productRating: product.averageRating,
                        reviewCount: product.reviewCount,
                        productId: product.id.toString(),
                        imageUrls: product.images,
                        badgeText: null,
                        isFavorite: isFavorite,
                        onBack: () => Get.back(),
                        onFavorite: () {
                          if (isFavorite) {
                            wishlistController.removeFromWishlist(product.id);
                          } else {
                            wishlistController.addToWishlist(product.id.toString());
                          }
                        },
                        heroTag: widget.heroTag,
                      );
                    }),

                    // MODIFIED: Product Title & Price Card with Toggle Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.neutralBackground,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12), // Adjusted padding
                        child: AnimatedOpacity(
                          opacity: _animationCompleted ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NEW: Replaced ProductTitleAndPrice with enhanced widget
                              ProductDetailsCard(
                                title: product.fullName,
                                originalPrice: originalPrice ?? sellingPrice,
                                discountedPrice: sellingPrice,
                              ),
                              const SizedBox(height: 12), // Adjusted spacing
                              SizedBox(
                                width: double.maxFinite,
                                height: 36,
                                child: Obx(() => ElevatedButton.icon(
                                  onPressed: () {
                                    _productDetailsVisible.value = !_productDetailsVisible.value;
                                    debugPrint('View product details tapped! Visible: ${_productDetailsVisible.value}');
                                  },
                                  icon: Icon(
                                    _productDetailsVisible.value
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _productDetailsVisible.value
                                        ? 'Hide product details'
                                        : 'View product details',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success.withOpacity(0.1),
                                    foregroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                    () => AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // FIXED ENHANCED PRODUCT DESCRIPTION
                                      _buildEnhancedProductDescription(product.description, textTheme, _productDetailsVisible.value),

                                      // Keep existing description points section
                                      if (product.descriptionPoints.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Product Features',
                                                style: textTheme.titleMedium?.copyWith(
                                                  color: AppColors.textDark,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.shade100,
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: product.descriptionPoints.asMap().entries.map((entry) {
                                                    int index = entry.key;
                                                    String point = entry.value;

                                                    return Container(
                                                      margin: EdgeInsets.only(bottom: index == product.descriptionPoints.length - 1 ? 0 : 12),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            margin: const EdgeInsets.only(top: 6, right: 12),
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                              color: AppColors.success,
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              _convertHtmlToPlainText(point),
                                                              style: textTheme.bodyMedium?.copyWith(
                                                                color: AppColors.textMedium,
                                                                height: 1.4,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Key information section
                                      if (product.keyInformation.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Highlights',
                                                style: textTheme.titleMedium?.copyWith(
                                                  color: AppColors.textDark,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.shade100,
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  children: product.keyInformation.map((info) {
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          SizedBox(
                                                            width: 110,
                                                            child: Text(
                                                              info.title,
                                                              style: textTheme.bodyMedium?.copyWith(
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              _convertHtmlToPlainText(info.content),
                                                              style: textTheme.bodyMedium?.copyWith(
                                                                color: Colors.grey.shade700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  crossFadeState: _productDetailsVisible.value
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                  alignment: Alignment.topLeft,
                                ),
                              ),
                            ],
                          ),),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Variant selection section
                    if (inStockVariantNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                        child: CollapsibleSection(
                          title: 'Select Variant',
                          initiallyExpanded: true,
                          content: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: List.generate(inStockVariantNames.length, (index) {
                              final variantName = inStockVariantNames[index];
                              final isSelected = _currentSelectedVariantName.value == variantName;

                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(variantName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    onVariantSelected(variantName);
                                  }
                                },
                                selectedColor: AppColors.success.withOpacity(0.1),
                                backgroundColor: Colors.white,
                                labelStyle: textTheme.labelMedium?.copyWith(
                                  color: isSelected ? AppColors.success : AppColors.textDark.withOpacity(0.8),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.success : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Related products section
                    Obx(() {
                      if (productController.allProducts.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final List<String> groupIds = widget.product.groupIds;
                      final List<ProductModel> relatedProducts = productController.getProductsInSameGroup(
                        widget.product.id,
                        groupIds,
                      );

                      if (relatedProducts.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                            child: Text(
                              'You might also like',
                              style: textTheme.headlineSmall?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedProducts.length,
                              itemBuilder: (context, index) {
                                final relatedProduct = relatedProducts[index];
                                final String productHeroTag = 'product_image_related_${relatedProduct.id}_$index';
                                return Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: AllProductGridCard(
                                    product: relatedProduct,
                                    heroTag: productHeroTag,
                                    onTap: (tappedProduct) {
                                      _navigateToRelatedProduct(tappedProduct, productHeroTag);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            _buildBottomCartBar(context)
          ],
        ),
        floatingActionButton: Obx(() {
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
            margin: const EdgeInsets.only(bottom: 70),
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
      ),);
  }

  // Navigation helper methods
  void _navigateToRelatedProduct(ProductModel product, String heroTag) {
    try {
      HapticFeedback.lightImpact();
      debugPrint('🚀 Navigating to related product: ${product.name} with heroTag: $heroTag');
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.to(
            () => ProductPage(
          product: product,
          heroTag: heroTag,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        preventDuplicates: false,
        popGesture: true,
      )?.then((_) {
        debugPrint('✅ Successfully navigated back from ${product.name}');
      }).catchError((error) {
        debugPrint('❌ Navigation error: $error');
      });
    } catch (e) {
      debugPrint('❌ Exception during navigation: $e');
      _fallbackNavigation(product);
    }
  }

  void _fallbackNavigation(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(
          product: product,
          heroTag: 'fallback_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: _horizontalPagePadding),
      decoration: BoxDecoration(
        color: AppColors.neutralBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGreyBackground,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend_outlined,
              size: 40,
              color: AppColors.textLight.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No recommendations available',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for suggestions',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textLight.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCartBar(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final product = widget.product;
    final double displayPrice = product.sellingPrice.length > 1
        ? product.sellingPrice.last.price.toDouble()
        : product.sellingPrice.isNotEmpty
        ? product.sellingPrice.first.price.toDouble()
        : 0.0;

    return Obx(() {
      final quantityInCartForSelectedVariant = cartController.getVariantQuantity(
        productId: product.id.toString(),
        variantName: _currentSelectedVariantName.value,
      );
      final bool isBusy = cartController.isLoading.value;
      final bool isOutOfStock = _currentVariantStock.value <= 0;
      final bool isInCart = quantityInCartForSelectedVariant > 0;
      final bool canIncrement =
          quantityInCartForSelectedVariant < _currentVariantStock.value && !isBusy;
      final bool canDecrement = quantityInCartForSelectedVariant > 0 && !isBusy;

      return SafeArea(
        bottom: true,
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                    ),
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              AnimatedCartButton(
                isInCart: isInCart,
                isBusy: isBusy,
                isOutOfStock: isOutOfStock,
                quantityInCart: quantityInCartForSelectedVariant,
                onAdd: _incrementQuantity,
                onIncrement: _incrementQuantity,
                onDecrement: _decrementQuantity,
                canIncrement: canIncrement,
                canDecrement: canDecrement,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// NEW: Enhanced widget for product title, price, and features
class ProductDetailsCard extends StatelessWidget {
  final String title;
  final double originalPrice;
  final double discountedPrice;

  const ProductDetailsCard({
    super.key,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasDiscount = originalPrice > discountedPrice;
    final int discountPercentage = hasDiscount
        ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Title
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Selling Price
            Text(
              '₹${discountedPrice.toStringAsFixed(0)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),

            // ✅ MRP with strikethrough
            if (hasDiscount) ...[
              Text(
                'MRP ',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                '₹${originalPrice.toStringAsFixed(0)}',
                style: textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textMedium,
                ),
              ),
            ],
            const SizedBox(width: 8),

            // ✅ Discount badge
            if (hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discountPercentage.round()}% OFF', // rounded value
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        )
,
        const SizedBox(height: 16),

        // Feature Boxes Row
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FeatureInfoBox(
              icon: Icons.delivery_dining_outlined,
              label: 'COD Available',
            ),
            SizedBox(width: 8),
            _FeatureInfoBox(
              icon: Icons.swap_horiz_rounded,
              label: 'Easy Replacement',
            ),
            SizedBox(width: 8),
            _FeatureInfoBox(
              icon: Icons.verified_outlined,
              label: 'Quality Assured',
            ),
            SizedBox(width: 8),
            _FeatureInfoBox(
              icon: Icons.headset_mic_outlined,
              label: 'Customer Support',
            ),
          ],
        )
      ],
    );
  }
}

// NEW: Helper widget for a single feature box
class _FeatureInfoBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureInfoBox({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade200, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}