import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'ShimmerProductGrid.dart';

class ShimmerGroupSection extends StatelessWidget {
  const ShimmerGroupSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            height: 20,
            width: 150,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const ShimmerProductGrid(),
        ],
      ),
    );
  }
}
