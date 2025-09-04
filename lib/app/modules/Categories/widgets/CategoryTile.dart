import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class CategoryTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? icon;
  final VoidCallback onTap;
  final bool isSelected; // Optional selection state
  final double? borderRadius;

  const CategoryTile({
    super.key,
    required this.title,
    this.imageUrl,
    required this.onTap,
    this.isSelected = false,
    this.borderRadius = 8.0, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Category: $title',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius!),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(borderRadius!),
              // Optional selection border
              border: isSelected
                  ? Border.all(color: AppColors.primaryPurple, width: 2)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildImageSection(),
                ),
                _buildTitleSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: _buildImageWidget(),
    );
  }

  Widget _buildImageWidget() {
    if (icon != null && icon!.isNotEmpty) {
      final modifiedIcon = icon!.replaceAll('stroke-width="3"', 'stroke-width="1"');
      return Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: SvgPicture.string(
            modifiedIcon,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => _buildLoadingWidget(),
          ),
        ),
      );
    }
    // Early return for null/empty URLs
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _buildFallbackWidget();
    }

    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildLoadingWidget(),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      semanticLabel: 'Image for $title category',
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Failed to load image for $title: $error');
        return _buildFallbackWidget();
      },
      // Improved caching
      cacheHeight: 200,
      cacheWidth: 200,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: AppColors.neutralBackground,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryPurple.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      color: AppColors.neutralBackground,
      child: Center(
        child: Icon(
          Icons.category_outlined,
          color: AppColors.textLight.withOpacity(0.6),
          size: 36,
          semanticLabel: 'Default category icon',
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          height: 1.2, // Better line spacing
        ),
        semanticsLabel: title, // Explicit semantic label
      ),
    );
  }
}
