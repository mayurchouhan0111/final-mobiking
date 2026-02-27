import 'package:flutter/material.dart';

class FeaturedProductBanner extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const FeaturedProductBanner({super.key, required this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
