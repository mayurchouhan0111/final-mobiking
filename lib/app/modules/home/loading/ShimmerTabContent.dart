import 'package:flutter/material.dart';
import 'package:mobiking/app/modules/home/loading/ShimmerBanner.dart';
import 'package:mobiking/app/modules/home/loading/ShimmerGroupSection.dart';
import 'package:mobiking/app/modules/home/loading/ShimmerProductGrid.dart';

class ShimmerTabContent extends StatelessWidget {
  const ShimmerTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          ShimmerBanner(width: double.infinity, height: 160, borderRadius: 12),
          SizedBox(height: 8),
          ShimmerGroupSection(),
          ShimmerProductGrid(),
        ],
      ),
    );
  }
}
