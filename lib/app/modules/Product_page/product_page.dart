// lib/screens/product_page.dart

import 'dart:math';

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
import 'widgets/product_title_price.dart';
import 'widgets/featured_product_banner.dart';
import 'widgets/collapsible_section.dart';
import 'widgets/animated_cart_button.dart';
import 'package:mobiking/app/modules/home/widgets/FloatingCartButton.dart';
import 'package:mobiking/app/modules/cart/cart_bottom_dialoge.dart';

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

  // DECODE HTML ENTITIES
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  // PARSE MARKDOWN IMAGES
  List<String> _extractMarkdownImages(String content) {
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = imageRegex.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  // PARSE MARKDOWN TABLE
  Map<String, dynamic>? _parseMarkdownTable(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Find table lines (contain |)
    final tableLines = lines.where((line) => line.contains('|')).toList();
    if (tableLines.length < 2) return null;

    // Parse headers
    final headerLine = tableLines.first.trim();
    final headers = headerLine.split('|')
        .map((h) => h.trim())
        .where((h) => h.isNotEmpty)
        .toList();

    if (headers.isEmpty) return null;

    // Skip separator line and parse data rows
    final dataRows = <List<String>>[];
    for (int i = 2; i < tableLines.length; i++) {
      final row = tableLines[i].trim();
      final cells = row.split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      if (cells.isNotEmpty) {
        dataRows.add(cells);
      }
    }

    return {
      'headers': headers,
      'rows': dataRows,
    };
  }

  // ENHANCED CONTENT PARSER FOR BOTH HTML AND MARKDOWN
  Widget _buildHtmlDescription(String content, BuildContext context) {
    if (content.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          'No detailed description is available for this product.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseContentToWidgets(content, context),
      ),
    );
  }

  // PARSE BOTH HTML AND MARKDOWN CONTENT
  List<Widget> _parseContentToWidgets(String content, BuildContext context) {
    List<Widget> widgets = [];

    try {
      final decodedContent = _decodeHtmlEntities(content);

      // Check if it's HTML or Markdown
      if (decodedContent.contains('<') && decodedContent.contains('>')) {
        // Parse as HTML
        widgets.addAll(_parseHtmlContent(decodedContent, context));
      } else {
        // Parse as Markdown/Plain text
        widgets.addAll(_parseMarkdownContent(decodedContent, context));
      }

      // If no widgets were created, show plain text
      if (widgets.isEmpty) {
        widgets.add(Text(
          decodedContent,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error parsing content: $e');
      widgets.add(Text(
        content.replaceAll(RegExp(r'[<>]'), ''),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textMedium,
          height: 1.5,
        ),
      ));
    }

    return widgets;
  }

  // PARSE HTML CONTENT
  List<Widget> _parseHtmlContent(String htmlContent, BuildContext context) {
    List<Widget> widgets = [];

    try {
      final document = html_parser.parse(htmlContent);
      final body = document.body;

      if (body != null) {
        for (var element in body.children) {
          widgets.addAll(_processHtmlElement(element, context));
        }
      }
    } catch (e) {
      debugPrint('Error parsing HTML: $e');
    }

    return widgets;
  }

  // PARSE MARKDOWN CONTENT
  List<Widget> _parseMarkdownContent(String markdownContent, BuildContext context) {
    List<Widget> widgets = [];

    final lines = markdownContent.split('\n');
    String currentContent = '';
    bool inTable = false;
    List<String> tableLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check for markdown images
      if (line.contains('![') && line.contains('](')) {
        // Add any accumulated text first
        if (currentContent.trim().isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              currentContent.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ));
          currentContent = '';
        }

        // Extract and add images
        final images = _extractMarkdownImages(line);
        for (final imageUrl in images) {
          widgets.add(_buildImageWidget(imageUrl, context));
        }
        continue;
      }

      // Check for table start/continuation
      if (line.contains('|')) {
        if (!inTable) {
          // Add any accumulated text first
          if (currentContent.trim().isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                currentContent.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ));
            currentContent = '';
          }
          inTable = true;
        }
        tableLines.add(line);
        continue;
      } else if (inTable) {
        // End of table, process it
        if (tableLines.isNotEmpty) {
          final tableData = _parseMarkdownTable(tableLines.join('\n'));
          if (tableData != null) {
            widgets.add(_buildMarkdownTable(tableData, context));
          }
        }
        tableLines.clear();
        inTable = false;
      }

      // Regular text line
      if (line.isNotEmpty) {
        currentContent += line + '\n';
      } else if (currentContent.trim().isNotEmpty) {
        // Empty line, add accumulated content as paragraph
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            currentContent.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ));
        currentContent = '';
      }
    }

    // Handle remaining table at end
    if (inTable && tableLines.isNotEmpty) {
      final tableData = _parseMarkdownTable(tableLines.join('\n'));
      if (tableData != null) {
        widgets.add(_buildMarkdownTable(tableData, context));
      }
    }

    // Add any remaining content
    if (currentContent.trim().isNotEmpty) {
      widgets.add(Text(
        currentContent.trim(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textMedium,
          height: 1.5,
        ),
      ));
    }

    return widgets;
  }

  // BUILD IMAGE WIDGET
  Widget _buildImageWidget(String imageUrl, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Image failed to load',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // BUILD MARKDOWN TABLE
  Widget _buildMarkdownTable(Map<String, dynamic> tableData, BuildContext context) {
    final List<String> headers = tableData['headers'];
    final List<List<String>> rows = tableData['rows'];

    if (headers.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
          },
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: headers.map((header) =>
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      header,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
              ).toList(),
            ),
            // Data rows
            ...rows.map((row) =>
                TableRow(
                  children: row.map((cell) =>
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Text(
                          cell,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                  ).toList(),
                ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  // PROCESS HTML ELEMENTS (keep existing method)
  List<Widget> _processHtmlElement(dynamic element, BuildContext context) {
    List<Widget> widgets = [];

    if (element.localName == 'h1' || element.localName == 'h2' || element.localName == 'h3') {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          element.text.trim(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ));
    } else if (element.localName == 'p') {
      if (element.text.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            element.text.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ));
      }
    } else if (element.localName == 'ul') {
      for (var li in element.children) {
        if (li.localName == 'li') {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    li.text.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMedium,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ));
        }
      }
    } else if (element.localName == 'img') {
      final String? src = element.attributes['src'];
      if (src != null && src.isNotEmpty) {
        widgets.add(_buildImageWidget(src, context));
      }
    } else if (element.localName == 'table') {
      widgets.add(_buildCustomTable(element, context));
    }

    return widgets;
  }

  // BUILD CUSTOM HTML TABLE (keep existing method)
  Widget _buildCustomTable(dynamic tableElement, BuildContext context) {
    List<TableRow> rows = [];

    try {
      var tableBody = tableElement.querySelector('tbody');
      var tableRows = tableBody?.children ?? tableElement.children.where((e) => e.localName == 'tr').toList();

      for (var row in tableRows) {
        if (row.localName == 'tr') {
          List<Widget> cells = [];
          var cellElements = row.children.where((e) => e.localName == 'td' || e.localName == 'th').toList();

          for (var cell in cellElements) {
            bool isHeader = cell.localName == 'th';
            cells.add(
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHeader ? Colors.grey.shade100 : Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Text(
                  cell.text.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    color: isHeader ? AppColors.textDark : AppColors.textMedium,
                  ),
                ),
              ),
            );
          }

          if (cells.isNotEmpty) {
            rows.add(TableRow(children: cells));
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing table: $e');
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
          },
          children: rows,
        ),
      ),
    );
  }

  String _convertHtmlToPlainText(String htmlText) {
    if (htmlText.isEmpty) return htmlText;
    try {
      final decodedHtml = _decodeHtmlEntities(htmlText);
      final document = html_parser.parse(decodedHtml);
      String plainText = document.body?.text ?? htmlText;
      plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
      return plainText;
    } catch (e) {
      debugPrint('Error parsing HTML: $e');
      return htmlText;
    }
  }

  // Keep all your existing methods for initState, dispose, build, etc. - they remain exactly the same
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
        // Find the index of the selected variant in the original product.variants.keys list
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
      debugPrint('ProductPage: _syncVariantData - Variant: $variantKey, Stock: $variantStockValue'); // ADDED DEBUG PRINT
      _currentVariantStock.value = variantStockValue;
    } else {
      debugPrint('ProductPage: _syncVariantData - Using totalStock: ${widget.product.totalStock}'); // ADDED DEBUG PRINT
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
      // if (_currentVariantStock.value <= 0) {
      //   Get.snackbar(
      //     'Out of Stock',
      //     'The selected variant is currently out of stock.',
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: AppColors.danger.withOpacity(0.8),
      //     colorText: Colors.white,
      //     icon: const Icon(Icons.info_outline, color: Colors.white),
      //     margin: const EdgeInsets.all(10),
      //     borderRadius: 10,
      //     animationDuration: const Duration(milliseconds: 300),
      //     duration: const Duration(seconds: 3),
      //   );
      // } else if (_currentVariantStock.value <= quantityInCart) {
      //   Get.snackbar(
      //     'Limit Reached',
      //     'You have reached the maximum available quantity for this variant.',
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: AppColors.danger.withOpacity(0.8),
      //     colorText: Colors.white,
      //     icon: const Icon(Icons.info_outline, color: Colors.white),
      //     margin: const EdgeInsets.all(10),
      //     borderRadius: 10,
      //     animationDuration: const Duration(milliseconds: 300),
      //     duration: const Duration(seconds: 3),
      //   );
      // }
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double sellingPrice;
    final double? originalPrice = product.regularPrice?.toDouble();

    if (product.sellingPrice.isNotEmpty) {
      sellingPrice = product.sellingPrice.last.price.toDouble();
    } else {
      sellingPrice = 0.0;
    }

    final double discountPercentage = (originalPrice != null && originalPrice > sellingPrice)
        ? ((originalPrice - sellingPrice) / originalPrice * 100)
        : 0;
    final String discountBadgeText =
    discountPercentage > 0 ? '${discountPercentage.toStringAsFixed(0)}% OFF' : '';

    final variantNames = product.variants.keys.toList();
    final inStockVariantNames = variantNames.where((name) {
      final variantStockValue = product.variants[name] ?? 0;
      return variantStockValue > 0;
    }).toList();


    return Scaffold(
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
                      badgeText: discountBadgeText.isNotEmpty ? discountBadgeText : null,
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

                  // Product Title & Price Card with Toggle Button
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductTitleAndPrice(
                            title: product.fullName,
                            originalPrice: originalPrice ?? sellingPrice,
                            discountedPrice: sellingPrice,
                          ),
                          const SizedBox(height: 8),
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
                                  // ENHANCED PRODUCT DESCRIPTION WITH MARKDOWN SUPPORT
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Product Description',
                                          style: textTheme.titleMedium?.copyWith(
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w600
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // USE THE ENHANCED PARSING METHOD
                                        _buildHtmlDescription(product.description, context),
                                      ],
                                    ),
                                  ),

                                  // Keep existing description points and key information sections
                                  if (product.descriptionPoints.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Product Description Points',
                                            style: textTheme.titleMedium?.copyWith(
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: product.descriptionPoints.map((point) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '• ',
                                                        style: textTheme.bodyMedium?.copyWith(
                                                          color: AppColors.textDark,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          _convertHtmlToPlainText(point),
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: AppColors.textMedium,
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
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
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
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                            child: Column(
                                              children: product.keyInformation.map((info) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                      ),
                    ),
                  ),

                  // Keep all your existing sections for variants, related products, etc.
                  // Now, use the filtered list to generate the ChoiceChips
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
                            final isSelected = selectedVariantIndex == index;
                            final variantName = inStockVariantNames[index];

                            return ChoiceChip(
                              // Set showCheckmark to false to remove the check icon
                              showCheckmark: false,
                              label: Text(variantName),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  // Pass the variantName directly
                                  onVariantSelected(variantName);
                                }
                              },
                              selectedColor: AppColors.success.withOpacity(0.1),
                              backgroundColor: Colors.white,
                              labelStyle: textTheme.labelMedium?.copyWith(
                                // Make the text green when selected
                                color: isSelected ? AppColors.success : AppColors.textDark.withOpacity(0.8),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  // Make the border green when selected
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

                    final String? parentCategory = widget.product.categoryId.isNotEmpty
                        ? widget.product.categoryId
                        : null;
                    final List<ProductModel> relatedProducts = productController.getProductsInSameParentCategory(
                      widget.product.id,
                      parentCategory,
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
          margin: const EdgeInsets.only(bottom: 70), // Adjust this value to position the FAB above the bottom bar
          child: FloatingCartButton(
            label: "View Cart",
            productImageUrls: imageUrls,
            itemCount: totalItemsInCart,
            onTap: () {
              Get.to(() => CartScreen());
            },
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Keep all your existing helper methods...
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
        productId: product.id,
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
