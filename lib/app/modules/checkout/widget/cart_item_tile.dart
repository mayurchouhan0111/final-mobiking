import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../../controllers/cart_controller.dart';
import '../../../data/product_model.dart';
import 'package:collection/collection.dart';

class CartItemTile extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final String variantName;

  const CartItemTile({
    Key? key,
    required this.product,
    required this.quantity,
    required this.variantName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CartController cartController = Get.find<CartController>();

    double displayPrice = 0.0;
    double? originalPrice = product.regularPrice?.toDouble();
    int? variantStock;

    if (product.sellingPrice.isNotEmpty && product.sellingPrice.last.price != null) {
      displayPrice = product.sellingPrice.last.price!.toDouble();
    }

    variantStock = product.variants[variantName] ?? product.totalStock;

    String imageUrl = 'https://via.placeholder.com/100';
    if (product.images.isNotEmpty) {
      imageUrl = product.images[0];
    }

    final bool hasDiscount = originalPrice != null && originalPrice > displayPrice && displayPrice > 0;
    final double discountPercentage = hasDiscount ? ((originalPrice - displayPrice) / originalPrice) * 100 : 0;

    return Container(
      // Improved padding for better horizontal spacing
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutralBackground, width: 1),
      ),
      child: Row(
        // Align children to the start of the row
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: AppColors.neutralBackground,
                child: Icon(
                  Icons.image_not_supported,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.fullName ?? 'Unnamed Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
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
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                    if (hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textLight,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                if (hasDiscount)
                  const SizedBox(height: 4),
                if (hasDiscount)
                  Text(
                    '${discountPercentage.round()}% OFF',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Added a Spacer to push the quantity control to the right
          const SizedBox(width: 16),

          Obx(
                () {
              final String itemKey = '${product.id}_$variantName';
              final bool isThisItemLoading = cartController.processingProductId.value == itemKey;
              final bool isDecrementDisabled = isThisItemLoading || quantity < 1;
              final bool isIncrementDisabled = isThisItemLoading || (variantStock != null && quantity >= variantStock!);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.remove,
                      onTap: isDecrementDisabled ? null : () {
                        cartController.removeFromCart(
                          productId: product.id!,
                          variantName: variantName,
                        );
                      },
                      isDisabled: isDecrementDisabled,
                      isLoading: false,
                    ),
                    const SizedBox(width: 6),
                    isThisItemLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
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
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildQuantityButton(
                      context: context,
                      icon: Icons.add,
                      onTap: isIncrementDisabled ? null : () {
                        cartController.addToCart(
                          productId: product.id!,
                          variantName: variantName,
                        );
                      },
                      isDisabled: isIncrementDisabled,
                      isLoading: false,
                    ),
                  ],
                ),
              );
            },
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
    final Color buttonColor = isDisabled ? AppColors.success.withOpacity(0.5) : AppColors.success;
    final Color iconColor = isDisabled ? AppColors.textLight.withOpacity(0.7) : AppColors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        )
            : Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
      ),
    );
  }
}