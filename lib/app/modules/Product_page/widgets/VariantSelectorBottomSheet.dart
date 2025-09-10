import 'package:flutter/material.dart';

// --- UPDATED: pro class with totalStock information ---
// You should integrate this 'totalStock' property into your actual ProductModel.
class pro {
  final String name;
  final double price;
  final List<String> variants;
  final int totalStock; // Added total stock for the entire product

  pro({
    required this.name,
    required this.price,
    this.variants = const [],
    this.totalStock = 0, // Default to 0 stock if not provided
  });

  bool get hasVariants => variants.isNotEmpty;
}
// --- END UPDATED pro class ---


class VariantSelectorBottomSheet extends StatelessWidget {
  final pro product;

  const VariantSelectorBottomSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    String? selectedVariant;

    // Determine if the entire product is out of stock
    final bool isProductOutOfStock = product.totalStock == 0;

    return StatefulBuilder(
      builder: (context, setState) {
        // The "Add to Cart" button is only enabled if the product is not out of stock
        // and a variant is selected (if variants exist).
        final bool isAddToCartEnabled = !isProductOutOfStock &&
            (!product.hasVariants || selectedVariant != null);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Select Variant",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              // Display "Out of Stock" message prominently if the product is out of stock
              if (isProductOutOfStock)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "This product is currently out of stock.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                )
              else if (product.hasVariants) // Only show variants if in stock
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: product.variants.map((variant) {
                    final isSelected = variant == selectedVariant;
                    return ChoiceChip(
                      label: Text(
                        variant,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.grey[200],
                      selected: isSelected,
                      onSelected: isProductOutOfStock // Disable selection if overall product is out of stock
                          ? null
                          : (_) {
                        setState(() {
                          selectedVariant = variant;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isSelected ? 6 : 0,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isAddToCartEnabled
                      ? () {
                    Navigator.pop(context); // Close the bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${product.name} ${product.hasVariants ? '($selectedVariant)' : ''} added to cart",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                      : () { // Action when button is disabled (i.e., out of stock or no variant selected)
                    
                    // If not out of stock but no variant selected, user can select one
                    // No need for a snackbar here, the button will simply be disabled until a variant is chosen.
                  },
                  child: Text(
                    isProductOutOfStock ? "Out of Stock" : "Add to Cart",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}