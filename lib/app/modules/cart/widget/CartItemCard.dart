import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Import your AppTheme
import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart'; // Assuming CartItemCard also uses ProductModel
import 'package:collection/collection.dart'; // For firstWhereOrNull if product.variants is used

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> cartItem;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CartItemCard({
    Key? key,
    required this.cartItem,
    this.onIncrement,
    this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CartController cartController = Get.find<CartController>();

    final productData = cartItem['productId'];
    if (productData is! Map<String, dynamic>) {
      return const SizedBox.shrink(); // Don't render if product data is invalid
    }
    final ProductModel product = ProductModel.fromJson(productData);
    final int quantity = cartItem['quantity'] as int? ?? 1;
    final String variantName = cartItem['variantName'] as String? ?? 'Default';

    final String itemKey = '${product.id}_$variantName';

    double displayPrice = 0.0;
    double? originalPrice = product.regularPrice?.toDouble();
    int? variantStock;

    // ✅ CHANGED: Using .last to get the most recent price instead of the first one.
    if (product.sellingPrice.isNotEmpty &&
        product.sellingPrice.last.price != null) {
      displayPrice = product.sellingPrice.last.price!.toDouble();
    }

    variantStock = product.variants[variantName];

    if (variantStock == null) {
      variantStock = product.totalStock;
    }

    String imageUrl = 'https://via.placeholder.com/100';
    if (product.images.isNotEmpty) {
      imageUrl = product.images[0];
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBackground, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.neutralBackground,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textLight,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.fullName ?? 'Unnamed Product',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variantName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${displayPrice.toStringAsFixed(0)}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (originalPrice != null &&
                                originalPrice > displayPrice)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '₹${originalPrice.toStringAsFixed(0)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (quantity > 1)
                          Text(
                            'Total: ₹${(displayPrice * quantity).toStringAsFixed(0)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Obx(() {
                  final bool isThisItemLoading =
                      cartController.processingProductId.value == itemKey;

                  final bool isDecrementDisabled = isThisItemLoading;
                  final bool isIncrementDisabled =
                      isThisItemLoading ||
                      (variantStock != null && quantity >= variantStock);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityButton(
                          context: context,
                          icon: Icons.remove,
                          onTap: isDecrementDisabled ? null : onDecrement,
                          isDisabled: isDecrementDisabled,
                          isLoading: false,
                        ),
                        const SizedBox(width: 8),
                        isThisItemLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                '$quantity',
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                        const SizedBox(width: 8),
                        _buildQuantityButton(
                          context: context,
                          icon: Icons.add,
                          onTap: isIncrementDisabled ? null : onIncrement,
                          isDisabled: isIncrementDisabled,
                          isLoading: false,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
    required bool isDisabled,
    required bool isLoading,
  }) {
    final Color buttonColor = AppColors.success;
    final Color iconColor = AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? buttonColor.withOpacity(0.5) : buttonColor,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: isDisabled ? iconColor.withOpacity(0.5) : iconColor,
              ),
      ),
    );
  }
}

class CartItem {
  final ProductModel product;
  final int quantity;
  final String variantName;

  CartItem({
    required this.product,
    required this.quantity,
    required this.variantName,
  });
}
