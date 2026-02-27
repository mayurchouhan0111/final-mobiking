import 'package:flutter/material.dart';

class SimilarProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> similarProducts;

  const SimilarProductsList({super.key, required this.similarProducts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: similarProducts.length,
        itemBuilder: (context, index) {
          final product = similarProducts[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(product['image']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${product['price']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
