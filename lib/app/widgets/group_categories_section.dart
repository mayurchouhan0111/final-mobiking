
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/data/parent_category_model.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsGridScreen.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryTile.dart';

class GroupCategoriesSection extends StatelessWidget {
  final List<ParentCategoryModel> categories;
  final SubCategoryController subCategoryController;

  const GroupCategoriesSection({
    super.key,
    required this.categories,
    required this.subCategoryController,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Adjust the cross axis count as needed
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, i) {
          final category = categories[i];
          return CategoryTile(
            title: category.name,
            imageUrl: category.image,
            onTap: () {
              final matchingSubs = subCategoryController.subCategories
                  .where((sub) => sub.parentCategory?.id == category.id)
                  .toList();
              Get.to(() => CategoryProductsGridScreen(
                    categoryName: category.name,
                    subCategories: matchingSubs,
                  ));
            },
          );
        },
      ),
    );
  }
}
