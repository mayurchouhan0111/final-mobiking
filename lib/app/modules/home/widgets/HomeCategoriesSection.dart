import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/home_controller.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryProductsGridScreen.dart';
import 'package:mobiking/app/modules/Categories/widgets/CategoryTile.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class HomeCategoriesSection extends StatelessWidget {
  final CategoryController categoryController;
  final SubCategoryController subCategoryController;

  const HomeCategoriesSection({
    super.key,
    required this.categoryController,
    required this.subCategoryController,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final isAnyLoading =
          categoryController.isLoading.value ||
          subCategoryController.isLoading.value;

      if (isAnyLoading && categoryController.categories.isEmpty) {
        return _buildLoadingState(context);
      }

      final allCategories = categoryController.categories;
      final availableSubCategories = subCategoryController.subCategories;

      final bool hasFailedToLoad =
          allCategories.isEmpty &&
          availableSubCategories.isEmpty &&
          !isAnyLoading;

      if (hasFailedToLoad) {
        return const SizedBox.shrink(); // Or a failed state widget
      }

      final availableSubCatIds = availableSubCategories
          .map((e) => e.id)
          .toSet();

      final filteredCategories = allCategories.where((cat) {
        return (cat.subCategoryIds ?? []).any(availableSubCatIds.contains);
      }).toList();

      if (filteredCategories.isEmpty && !isAnyLoading) {
        return const SizedBox.shrink();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredCategories.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          final title = category.name ?? "Unnamed Category";

          final matchingSubs = availableSubCategories
              .where((sub) => (category.subCategoryIds ?? []).contains(sub.id))
              .toList();

          if (matchingSubs.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(
                        () => CategoryProductsGridScreen(
                          categoryName: title,
                          subCategories: matchingSubs,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AppColors.success,
                            width: 1,
                          ),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See More',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Grid of subcategories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchingSubs.length > 6 ? 6 : matchingSubs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85, // Adjusted aspect ratio
                  ),
                  itemBuilder: (context, i) {
                    final sub = matchingSubs[i];
                    final image = (sub.photos?.isNotEmpty ?? false)
                        ? sub.photos!.first
                        : "https://via.placeholder.com/150x150/E0E0E0/A0A0A0?text=No+Image";

                    return CategoryTile(
                      title: sub.name ?? 'Unknown',
                      imageUrl: image,
                      icon: sub.icon, // new
                      onTap: () {
                        Get.to(
                          () => CategoryProductsGridScreen(
                            categoryName: title,
                            subCategories: matchingSubs,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      itemCount: 2, // Show 2 shimmer sections
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer title
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.grey[50]!,
                child: Container(
                  width: 180,
                  height: textTheme.titleLarge?.fontSize ?? 22,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
