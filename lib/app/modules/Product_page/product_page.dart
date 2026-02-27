// lib/screens/product_page.dart

import 'dart:math';
import 'dart:convert'; // For base64 decoding
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add to pubspec.yaml for SVG support
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
import 'widgets/featured_product_banner.dart';
import 'widgets/collapsible_section.dart';
import 'widgets/animated_cart_button.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';

class ProductPage extends StatefulWidget {
  final ProductModel product;
  final String heroTag;

  const ProductPage({super.key, required this.product, required this.heroTag});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
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
        _currentSelectedVariantName.value = widget.product.variants.keys
            .elementAt(selectedVariantIndex);
      } else {
        selectedVariantIndex = 0;
        _currentSelectedVariantName.value = widget.product.variants.keys
            .elementAt(selectedVariantIndex);
      }
    } else {
      _currentSelectedVariantName.value = 'Default Variant';
    }

    _pincodeController.addListener(_resetDeliveryStatus);
    _syncVariantData();
    productController.fetchRelatedProducts(widget.product.slug ?? '');

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
        .animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeInOut,
          ),
        );

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
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_slideAnimationController.status != AnimationStatus.forward) {
        _slideAnimationController.forward();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
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
        selectedVariantIndex = widget.product.variants.keys.toList().indexOf(
          selectedVariantName,
        );
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
      final variantKey = widget.product.variants.keys.elementAt(
        selectedVariantIndex,
      );
      final variantStockValue = widget.product.variants[variantKey] ?? 0;
      debugPrint(
        'ProductPage: _syncVariantData - Variant: $variantKey, Stock: $variantStockValue',
      );
      _currentVariantStock.value = variantStockValue;
    } else {
      debugPrint(
        'ProductPage: _syncVariantData - Using totalStock: ${widget.product.totalStock}',
      );
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
    if (cartController.isLoading.value ||
        _currentVariantStock.value <= 0 ||
        _currentVariantStock.value <= quantityInCart) {
      return;
    }

    cartController.isLoading.value = true;
    try {
      await cartController.addToCart(
        productId: productId,
        variantName: variantName,
      );
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
      await cartController.removeFromCart(
        productId: productId,
        variantName: variantName,
      );
    } finally {
      cartController.isLoading.value = false;
    }
  }

  // NEW: Convert Markdown images to HTML
  String _convertMarkdownImagesToHtml(String content) {
    if (content.isEmpty) return content;

    // Convert markdown images ![alt](url) to HTML <img> tags
    String
    converted = content.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\(([^\)]+)\)'), (
      match,
    ) {
      final alt = match.group(1) ?? 'Product Image';
      final url = match.group(2) ?? '';
      return '<p style="text-align:center; margin:16px 0;"><img src="$url" alt="$alt" style="max-width:100%; height:auto; border-radius:12px;" /></p>';
    });

    // Convert markdown bold **text** to HTML
    converted = converted.replaceAllMapped(
      RegExp(r'\*\*([^\*]+)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );

    // Convert markdown italic *text* to HTML (avoid matching **)
    converted = converted.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^\*]+)\*(?!\*)'),
      (match) => '<em>${match.group(1)}</em>',
    );

    // Convert double line breaks to paragraph breaks
    converted = converted.replaceAll(
      RegExp(r'\n\n+'),
      '</p><p style="margin:8px 0;">',
    );

    // Wrap in paragraph tags if not already HTML
    if (!converted.trim().startsWith('<')) {
      converted = '<p style="margin:8px 0;">$converted</p>';
    }

    return converted;
  }

  // HTML sanitization with proper type handling
  String _sanitizeHtml(String htmlString) {
    if (htmlString.isEmpty) return htmlString;

    try {
      final document = html_parser.parse(htmlString);

      document
          .querySelectorAll('script')
          .forEach((element) => element.remove());
      document.querySelectorAll('style').forEach((element) => element.remove());

      document.querySelectorAll('*').forEach((element) {
        element.attributes.removeWhere((key, value) {
          final keyStr = key.toString().toLowerCase();
          return keyStr.startsWith('on') || keyStr.contains('javascript:');
        });
      });

      return document.outerHtml;
    } catch (e) {
      print("HTML sanitization error: $e");

      String sanitized = htmlString
          .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'''on\w+\s*=\s*["'][^"']*["']''', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

      return sanitized;
    }
  }

  Widget _buildEnhancedProductDescription(
    String htmlDescription,
    TextTheme textTheme,
    bool isExpanded,
  ) {
    if (htmlDescription.isEmpty) return const SizedBox.shrink();

    // UPDATED: First convert markdown to HTML, then sanitize
    String processedHtml = _convertMarkdownImagesToHtml(htmlDescription);
    String sanitizedHtml = _sanitizeHtml(processedHtml);

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
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // HTML rendering with comprehensive edge case handling
  Widget _buildDescriptionContent(String htmlDescription, TextTheme textTheme) {
    try {
      return Html(
        data: htmlDescription,

        style: {
          "body": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.6),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontFamily: 'Roboto',
          ),

          "p": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.5),
            margin: Margins.only(bottom: 12.0),
            padding: HtmlPaddings.zero,
          ),

          "div": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.5),
            margin: Margins.only(bottom: 8.0),
          ),

          "h1": Style(
            fontSize: FontSize(22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 16.0, top: 8.0),
          ),
          "h2": Style(
            fontSize: FontSize(20.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 14.0, top: 8.0),
          ),
          "h3": Style(
            fontSize: FontSize(18.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 12.0, top: 6.0),
          ),
          "h4": Style(
            fontSize: FontSize(16.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 10.0, top: 6.0),
          ),
          "h5": Style(
            fontSize: FontSize(14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 8.0, top: 4.0),
          ),
          "h6": Style(
            fontSize: FontSize(12.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            margin: Margins.only(bottom: 8.0, top: 4.0),
          ),

          "ul": Style(
            margin: Margins.only(bottom: 16.0, left: 20.0),
            padding: HtmlPaddings.zero,
          ),
          "ol": Style(
            margin: Margins.only(bottom: 16.0, left: 20.0),
            padding: HtmlPaddings.zero,
          ),
          "li": Style(
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
            lineHeight: LineHeight(1.6),
            margin: Margins.only(bottom: 8.0),
            display: Display.listItem,
          ),

          "table": Style(
            margin: Margins.only(bottom: 16.0, top: 8.0),
            backgroundColor: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
          ),
          "thead": Style(
            backgroundColor: Colors.grey.shade200,
            fontWeight: FontWeight.bold,
          ),
          "tbody": Style(backgroundColor: Colors.white),
          "th": Style(
            padding: HtmlPaddings.all(8.0),
            backgroundColor: Colors.grey.shade200,
            fontWeight: FontWeight.bold,
            border: Border.all(color: Colors.grey.shade300),
            alignment: Alignment.centerLeft,
          ),
          "td": Style(
            padding: HtmlPaddings.all(8.0),
            alignment: Alignment.centerLeft,
            border: Border.all(color: Colors.grey.shade300),
            fontSize: FontSize(14.0),
            color: AppColors.textMedium,
          ),
          "tr": Style(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),

          "span": Style(fontSize: FontSize(14.0), color: AppColors.textMedium),

          "strong": Style(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          "b": Style(fontWeight: FontWeight.bold, color: AppColors.textDark),
          "em": Style(fontStyle: FontStyle.italic),
          "i": Style(fontStyle: FontStyle.italic),
          "u": Style(textDecoration: TextDecoration.underline),
          "s": Style(textDecoration: TextDecoration.lineThrough),
          "strike": Style(textDecoration: TextDecoration.lineThrough),
          "del": Style(
            textDecoration: TextDecoration.lineThrough,
            color: Colors.grey.shade600,
          ),
          "mark": Style(
            backgroundColor: Colors.yellow.shade200,
            color: AppColors.textDark,
          ),

          "code": Style(
            backgroundColor: Colors.grey.shade100,
            color: Colors.red.shade700,
            padding: HtmlPaddings.symmetric(horizontal: 4.0, vertical: 2.0),
            fontFamily: 'monospace',
            fontSize: FontSize(13.0),
          ),
          "pre": Style(
            backgroundColor: Colors.grey.shade100,
            padding: HtmlPaddings.all(12.0),
            margin: Margins.only(bottom: 12.0),
            fontFamily: 'monospace',
            fontSize: FontSize(13.0),
            whiteSpace: WhiteSpace.pre,
          ),

          "blockquote": Style(
            margin: Margins.only(left: 16.0, bottom: 12.0),
            padding: HtmlPaddings.only(left: 12.0),
            border: Border(
              left: BorderSide(color: AppColors.textMedium, width: 3.0),
            ),
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade700,
          ),

          "hr": Style(
            margin: Margins.symmetric(vertical: 16.0),
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
          ),

          "br": Style(fontSize: FontSize(8.0)),

          "img": Style(
            margin: Margins.symmetric(vertical: 12.0),
            width: Width(100, Unit.percent),
            height: Height.auto(),
          ),

          "a": Style(
            color: Colors.blue,
            textDecoration: TextDecoration.underline,
          ),

          "sub": Style(
            fontSize: FontSize(10.0),
            verticalAlign: VerticalAlign.sub,
          ),
          "sup": Style(
            fontSize: FontSize(10.0),
            verticalAlign: VerticalAlign.baseline,
          ),

          "small": Style(fontSize: FontSize(12.0), color: Colors.grey.shade600),

          "center": Style(alignment: Alignment.center),

          "*": Style(backgroundColor: Colors.transparent),
        },

        onLinkTap: (url, attributes, element) {
          if (url != null) {
            print("Link tapped: $url");
          }
        },

        extensions: [
          TagExtension(
            tagsToExtend: {"img"},
            builder: (extensionContext) {
              final attributes = extensionContext.attributes;
              final src = attributes['src'];
              final alt = attributes['alt'] ?? 'Product Image';

              if (src == null || src.isEmpty) {
                print("❌ Image src is null or empty");
                return _buildImageErrorWidget(alt);
              }

              print("✅ Loading image from: $src");

              try {
                final widthStr = attributes['width'];
                final heightStr = attributes['height'];

                final width = widthStr != null
                    ? double.tryParse(
                        widthStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                      )
                    : null;
                final height = heightStr != null
                    ? double.tryParse(
                        heightStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                      )
                    : null;

                // Handle Base64 images
                if (src.startsWith('data:image') && src.contains('base64,')) {
                  try {
                    final parts = src.split('base64,');
                    final base64String = parts.length > 1
                        ? parts[1].trim()
                        : '';

                    if (base64String.isEmpty) {
                      return _buildImageErrorWidget(alt);
                    }

                    final decodedBytes = base64Decode(base64String);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.memory(
                          decodedBytes,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorWidget(alt);
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    print("Base64 decode error: $e");
                    return _buildImageErrorWidget(alt);
                  }
                }

                // Handle Asset images
                if (src.startsWith('asset:') || src.startsWith('assets/')) {
                  final assetPath = src.replaceFirst('asset:', '');
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.asset(
                        assetPath,
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImageErrorWidget(alt);
                        },
                      ),
                    ),
                  );
                }

                // Handle SVG images
                final srcLower = src.toLowerCase();
                if (srcLower.endsWith('.svg')) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: SvgPicture.network(
                        src,
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Container(
                          width: width ?? 100,
                          height: height ?? 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.success,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Handle Network images (default)
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      src,
                      width: width ?? double.infinity,
                      height: height,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: height ?? 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.success,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading image...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("❌ Network image error: $error");
                        return _buildImageErrorWidget(alt);
                      },
                    ),
                  ),
                );
              } catch (e) {
                print("Error rendering image: $e");
                return _buildImageErrorWidget(alt);
              }
            },
          ),

          TagExtension(
            tagsToExtend: {"iframe", "video"},
            builder: (extensionContext) {
              final element = extensionContext.element;
              final src = element?.attributes['src'];

              if (src == null || src.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Video content unavailable',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video content available',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view in browser',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        shrinkWrap: true,
      );
    } catch (e, stackTrace) {
      print("HTML rendering failed: $e");
      print("Stack trace: $stackTrace");

      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Displaying simplified content',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _convertHtmlToPlainText(htmlDescription),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
                height: 1.6,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageErrorWidget(String? altText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade400,
            size: 48.0,
          ),
          if (altText != null && altText.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              altText,
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: 12.0),
            Text(
              'Image unavailable',
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _convertHtmlToPlainText(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      String text = document.body?.text ?? '';

      text = text
          .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();

      return text;
    } catch (e) {
      print("HTML to text conversion error: $e");

      return htmlString
          .replaceAll(RegExp(r'<br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<p[^>]*>'), '\n')
          .replaceAll(RegExp(r'</p>'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'&quot;'), '"')
          .replaceAll(RegExp(r'&#39;'), "'")
          .replaceAll(RegExp(r'&apos;'), "'")
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of your build method stays exactly the same as in the file)
    // Copy the entire build method from your original code
    final product = widget.product;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double sellingPrice;
    final double? originalPrice = product.regularPrice?.toDouble();
    String discountBadgeText = '';

    if (product.sellingPrice.isNotEmpty &&
        product.sellingPrice.last.price != null) {
      sellingPrice = product.sellingPrice.last.price!.toDouble();
    } else {
      sellingPrice = 0.0;
    }

    final bool hasDiscount =
        originalPrice != null &&
        originalPrice > sellingPrice &&
        sellingPrice > 0;
    if (hasDiscount) {
      double discount = ((originalPrice! - sellingPrice) / originalPrice) * 100;
      discountBadgeText = '${discount.round()}% OFF';
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
                    Obx(() {
                      final isFavorite = wishlistController.wishlist.any(
                        (p) => p.id == product.id,
                      );
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
                            wishlistController.addToWishlist(
                              product.id.toString(),
                            );
                          }
                        },
                        heroTag: widget.heroTag,
                      );
                    }),

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
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        child: AnimatedOpacity(
                          opacity: _animationCompleted ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductDetailsCard(
                                title: product.fullName,
                                originalPrice: originalPrice ?? sellingPrice,
                                discountedPrice: sellingPrice,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.maxFinite,
                                height: 36,
                                child: Obx(
                                  () => ElevatedButton.icon(
                                    onPressed: () {
                                      _productDetailsVisible.value =
                                          !_productDetailsVisible.value;
                                      debugPrint(
                                        'View product details tapped! Visible: ${_productDetailsVisible.value}',
                                      );
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success
                                          .withOpacity(0.1),
                                      foregroundColor: AppColors.success,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEnhancedProductDescription(
                                        product.description,
                                        textTheme,
                                        _productDetailsVisible.value,
                                      ),

                                      if (product.descriptionPoints.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Product Features',
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      color: AppColors.textDark,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          Colors.grey.shade100,
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: product.descriptionPoints.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    int index = entry.key;
                                                    String point = entry.value;

                                                    return Container(
                                                      margin: EdgeInsets.only(
                                                        bottom:
                                                            index ==
                                                                product
                                                                        .descriptionPoints
                                                                        .length -
                                                                    1
                                                            ? 0
                                                            : 12,
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            margin:
                                                                const EdgeInsets.only(
                                                                  top: 6,
                                                                  right: 12,
                                                                ),
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .success,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              _convertHtmlToPlainText(
                                                                point,
                                                              ),
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color: AppColors
                                                                        .textMedium,
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

                                      if (product.keyInformation.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Highlights',
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      color: AppColors.textDark,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          Colors.grey.shade100,
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  children: product.keyInformation.map((
                                                    info,
                                                  ) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8.0,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(
                                                            width: 110,
                                                            child: Text(
                                                              info.title,
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              _convertHtmlToPlainText(
                                                                info.content,
                                                              ),
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
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
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (inStockVariantNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _horizontalPagePadding,
                        ),
                        child: CollapsibleSection(
                          title: 'Select Variant',
                          initiallyExpanded: true,
                          content: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: List.generate(
                              inStockVariantNames.length,
                              (index) {
                                final variantName = inStockVariantNames[index];
                                final isSelected =
                                    _currentSelectedVariantName.value ==
                                    variantName;

                                return ChoiceChip(
                                  showCheckmark: false,
                                  label: Text(variantName),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      onVariantSelected(variantName);
                                    }
                                  },
                                  selectedColor: AppColors.success.withOpacity(
                                    0.1,
                                  ),
                                  backgroundColor: Colors.white,
                                  labelStyle: textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? AppColors.success
                                        : AppColors.textDark.withOpacity(0.8),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.success
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Continue with the rest of your build method...
                    // Copy all the remaining code from your original file
                    const SizedBox(height: 24),

                    // Related Products Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _horizontalPagePadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Similar Products',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240, // Adjust this height as needed
                            child: Obx(() {
                              if (productController
                                  .isFetchingRelatedProducts
                                  .value) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (productController.relatedProducts.isEmpty) {
                                return _buildEmptyState(textTheme);
                              }

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    productController.relatedProducts.length,
                                itemBuilder: (context, index) {
                                  final relatedProduct =
                                      productController.relatedProducts[index];
                                  return SizedBox(
                                    width: 120, // Adjust this width as needed
                                    child: AllProductGridCard(
                                      product: relatedProduct,
                                      heroTag:
                                          'related_product_${relatedProduct.id}',
                                      onTap: (product) {
                                        _navigateToRelatedProduct(
                                          product,
                                          'related_product_${product.id}',
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            _buildBottomCartBar(context),
          ],
        ),
        floatingActionButton: Obx(() {
          final totalItemsInCart = cartController.totalCartItemsCount;
          if (totalItemsInCart == 0) {
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
      ),
    );
  }

  // Copy all remaining methods from your original file:
  // - _navigateToRelatedProduct
  // - _fallbackNavigation
  // - _buildEmptyState
  // - _buildBottomCartBar

  void _navigateToRelatedProduct(ProductModel product, String heroTag) {
    try {
      HapticFeedback.lightImpact();
      debugPrint(
        '🚀 Navigating to related product: ${product.name} with heroTag: $heroTag',
      );
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.to(
            () => ProductPage(product: product, heroTag: heroTag),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            preventDuplicates: false,
            popGesture: true,
          )
          ?.then((_) {
            debugPrint('✅ Successfully navigated back from ${product.name}');
          })
          .catchError((error) {
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
          heroTag:
              'fallback_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
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
        border: Border.all(color: AppColors.lightGreyBackground, width: 1),
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
      final quantityInCartForSelectedVariant = cartController
          .getVariantQuantity(
            productId: product.id.toString(),
            variantName: _currentSelectedVariantName.value,
          );
      final bool isBusy = cartController.isLoading.value;
      final bool isOutOfStock = _currentVariantStock.value <= 0;
      final bool isInCart = quantityInCartForSelectedVariant > 0;
      final bool canIncrement =
          quantityInCartForSelectedVariant < _currentVariantStock.value &&
          !isBusy;
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
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
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

// Copy ProductDetailsCard and _FeatureInfoBox classes from your original file
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

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹${discountedPrice.toStringAsFixed(0)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),

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

            if (hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discountPercentage.round()}% OFF',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

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
        ),
      ],
    );
  }
}

class _FeatureInfoBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureInfoBox({required this.icon, required this.label});

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
            Icon(icon, color: Colors.grey.shade700, size: 20),
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
