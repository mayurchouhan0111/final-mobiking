import 'package:flutter/material.dart';
// Remove GoogleFonts import if not globally applied via AppTheme
// import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/data/product_model.dart'; // Ensure this path is correct
import 'package:mobiking/app/themes/app_theme.dart'; // Import your AppColors

class WishlistCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  final VoidCallback? onTap; // Optional: for making the card itself tappable
  final VoidCallback? onAddToCart; // Added: for Add to Cart functionality

  const WishlistCard({
    super.key,
    required this.product,
    required this.onRemove,
    this.onTap,
    this.onAddToCart, // Initialize the new callback
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Determine the actual price to display.
    final num regularPrice = product.sellingPrice.isNotEmpty
        ? product.sellingPrice.first.price
        : 0.0;
    // Assuming discounted price is at index 1 if available
    final int? discountedPrice = product.sellingPrice.length > 1
        ? product.sellingPrice[1].price
        : null;
    final bool hasDiscount =
        discountedPrice != null && discountedPrice < regularPrice;

    final num displayPrice = hasDiscount ? discountedPrice! : regularPrice;

    // Use a placeholder image if no images are available
    final String imageUrl = product.images.isNotEmpty
        ? product.images[0]
        : "https://via.placeholder.com/100x100/F0F0F0/A0A0A0?text=No+Image";

    return Container(
      // Replacing Card with Container for more precise styling control
      decoration: BoxDecoration(
        color: AppColors.white, // Pure white background for the card
        borderRadius: BorderRadius.circular(
          12,
        ), // Rounded corners for the entire card
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(
              0.04,
            ), // Very subtle, diffused shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ), // Match container's border radius
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ), // Reduced padding for a more compact card
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to the top
            children: [
              // --- Product Image ---
              Container(
                width: 90, // Consistent image size
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // Slightly less rounded than card
                  color: AppColors
                      .neutralBackground, // Light background for image area
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.neutralBackground,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textLight,
                        size: 36,
                      ), // Themed broken image icon
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // --- Product Details: Name, Price, Discount, Actions ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        // Using titleSmall for product name
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        height: 1.3, // Adjust line height for readability
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.baseline, // Align text baselines
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Display the actual selling price (discounted or regular)
                        Text(
                          '₹${displayPrice.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            // Larger and bolder for main price
                            fontWeight: FontWeight.w600,
                            color: AppColors
                                .primaryGreen, // Discounted/Current price in Blinkit green
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Display original price if there's a discount
                        if (hasDiscount)
                          Text(
                            '₹${regularPrice.toStringAsFixed(2)}',
                            style: textTheme.bodyLarge?.copyWith(
                              // bodyLarge for strikethrough price
                              fontWeight: FontWeight.w500,
                              color: AppColors
                                  .textMedium, // Medium grey for strikethrough
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textMedium,
                              decorationThickness: 1.5,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12), // Space before action buttons
                    // --- Actions: Remove and Add to Cart ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remove Button (leading edge)
                        TextButton.icon(
                          onPressed: onRemove,
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textMedium,
                            size: 20,
                          ), // Clear 'X' icon for remove
                          label: Text(
                            'Remove',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor:
                                AppColors.textMedium, // Ripple color
                          ),
                        ),
                        // Add to Cart Button (trailing edge)
                        if (onAddToCart != null)
                          SizedBox(
                            height: 36, // Fixed height for button
                            child: ElevatedButton(
                              onPressed: onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // Slightly rounded corners
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ), // Horizontal padding
                                elevation: 2, // Subtle elevation
                              ),
                              child: Text(
                                'Add', // Simple "Add" text
                                style: textTheme.labelMedium?.copyWith(
                                  // labelLarge for button text
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
