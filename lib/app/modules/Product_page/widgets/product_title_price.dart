import 'package:flutter/material.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class ProductTitleAndPrice extends StatelessWidget {
  final String title;
  final double originalPrice;
  final double discountedPrice;

  const ProductTitleAndPrice({
    super.key,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'ProductTitleAndPrice: originalPrice: $originalPrice, discountedPrice: $discountedPrice',
    );
    final textTheme = Theme.of(context).textTheme;
    final bool hasDiscount =
        originalPrice > discountedPrice && discountedPrice > 0;
    final double discountPercentage = hasDiscount
        ? ((originalPrice - discountedPrice) / originalPrice) * 100
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏷 Product Title
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // 💰 Prices
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Final Selling Price
            Text(
              '₹${discountedPrice.toStringAsFixed(0)}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),

            // MRP with Strikethrough
            if (hasDiscount) ...[
              Text(
                'MRP ',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${originalPrice.toStringAsFixed(0)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],

            const Spacer(),

            // Discount Badge
            if (hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${discountPercentage.round()}% OFF',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
