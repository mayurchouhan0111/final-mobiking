import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../data/product_model.dart';
import '../Product_page/product_page.dart';
import 'package:mobiking/app/modules/Product_page/widgets/app_star_rating.dart';

class SearchProductCard extends StatelessWidget {
  final ProductModel product;
  final String heroTag;

  const SearchProductCard({
    Key? key,
    required this.product,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Random rating generation
    final double randomRating = 4.7 + (Random().nextDouble() * 0.3);
    final int randomRatingCount = Random().nextInt(200) + 20;

    final String productName = product.name ?? 'Unnamed Product';

    // Safe price handling
    final String priceText =
        (product.sellingPrice.isNotEmpty &&
            product.sellingPrice[0].price != null)
        ? '₹${product.sellingPrice[0].price!.toStringAsFixed(0)}'
        : 'N/A';

    return InkWell(
      onTap: () {
        Get.to(
          () => ProductPage(
            product: product,
            heroTag: 'search-product-image-${product.id}',
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      (product.images != null &&
                          product.images!.isNotEmpty &&
                          product.images!.first != null)
                      ? Image.network(
                          product.images!.first!,
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined, size: 32),
                        )
                      : const Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            /// Product Name
            Text(
              productName,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            /// Rating
            AppStarRating(
              rating: double.parse(randomRating.toStringAsFixed(1)),
              ratingCount: randomRatingCount,
              starSize: 14,
            ),

            const SizedBox(height: 6),

            /// Price
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                priceText,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
