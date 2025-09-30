import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- Color Palette based on your theme preferences ---
// Using a private class to hold the color values for this example.
class _AppColors {
  // Backgrounds
  static const Color cardBackground = Colors.transparent; // zinc-900
  static const Color imageContainerBackground = Colors.white; // zinc-800

  // Accent & Status
  static const Color accent = Color(0xff4f46e5); // indigo

  // Text
  static const Color primaryText = Color(0xfff4f4f5); // zinc-100/white
  static const Color secondaryText = Colors.black; // zinc-400
  static const Color placeholderText = Color(0xff71717a); // zinc-500
}


class CategoryTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? icon;
  final VoidCallback onTap;
  final bool isSelected;
  final double? borderRadius;

  const CategoryTile({
    super.key,
    required this.title,
    this.imageUrl,
    required this.onTap,
    this.isSelected = false,
    this.borderRadius = 12.0, // Increased for a more modern look
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Category: $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius!),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
            decoration: BoxDecoration(
              color: _AppColors.cardBackground,
              borderRadius: BorderRadius.circular(borderRadius!),
              border: isSelected
                  ? Border.all(color: _AppColors.accent, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // This container holds the image and gives it the rounded background
                Expanded(
                  child: _buildImageSection(),
                ),
                const SizedBox(height: 8),
                _buildTitleSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the container that holds the image/icon, styled like the reference image.
  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: _AppColors.imageContainerBackground,
          borderRadius: BorderRadius.circular(16.0), // Fully rounded corners
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImageWidget(),
      ),
    );
  }

  /// Determines whether to show an SVG icon, a network image, or a fallback.
  Widget _buildImageWidget() {
    // Priority for local SVG string icon
    if (icon != null && icon!.isNotEmpty) {
      final modifiedIcon = icon!.replaceAll('stroke-width="3"', 'stroke-width="1.5"');
      return Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: SvgPicture.string(
            modifiedIcon,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => _buildLoadingWidget(),
          ),
        ),
      );
    }

    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _buildFallbackWidget();
    }

    // Network SVG
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildLoadingWidget(),
      );
    }

    // Network Image (PNG, JPG, etc.)
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
      cacheHeight: 200,
      cacheWidth: 200,
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_AppColors.accent),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Center(
      child: Icon(
        Icons.category_outlined,
        color: _AppColors.placeholderText,
        size: 36,
        semanticLabel: 'Default category icon',
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: _AppColors.secondaryText,
        fontWeight: FontWeight.w500, // Adjusted for better readability
        fontSize: 12,
        height: 1.3,
      ),
      semanticsLabel: title,
    );
  }
}