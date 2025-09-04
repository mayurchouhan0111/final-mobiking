import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Ensure this path is correct for AppColors

// Assuming ProductModel is defined like this:
// class ProductModel {
//   final String id;
//   final String name;
//   final List<String> images;
//   final List<SellingPriceModel> sellingPrice; // Assuming this contains 'price'
//   // ... other fields
// }
//
// class SellingPriceModel {
//   final double? price;
//   // ... other fields
// }
import '../../../data/product_model.dart';

class SuggestedProductCard extends StatelessWidget {
  final ProductModel product;

  const SuggestedProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    // AppColors is custom, using it where appropriate
    // final ColorScheme colorScheme = theme.colorScheme; // Not used much directly here for custom colors

    final String imageUrl = product.images.isNotEmpty
        ? product.images[0]
        : 'https://via.placeholder.com/120x90';

    // Safely get price, handling potential empty list or null values
    final String displayPrice = (product.sellingPrice != null &&
        product.sellingPrice.isNotEmpty &&
        product.sellingPrice[0].price != null)
        ? "₹${product.sellingPrice[0].price!.toStringAsFixed(2)}" // Format to 2 decimal places
        : "₹0.00"; // Default value

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1), // ADDED BORDER, REMOVED SHADOW
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  displayPrice,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
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