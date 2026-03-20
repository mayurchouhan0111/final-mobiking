import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart'; // Your AppColors and AppTheme

import '../../../controllers/cart_controller.dart';
import '../../../controllers/wishlist_controller.dart';
import 'Wish_list_card.dart'; // Ensure this path is correct and it's the updated version
import '../../../data/product_model.dart';
import '../../checkout/CheckoutScreen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/modules/login/login_screen.dart'; // ✅ Added for redirection

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ GUEST CHECK: Explicitly redirect if user is not logged in
    final box = GetStorage();
    if (box.read('cartId') == null && box.read('user') == null) {
      debugPrint('🛡️ WishlistScreen: Guest detected, redirecting to login.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => PhoneAuthScreen());
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = Get.find<WishlistController>();
    final cartController = Get.find<CartController>();
    
    // Ensure data is refreshed on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchWishlistOnScreenLoad();
    });

    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          iconSize: 28,
          tooltip: 'Back',
          visualDensity: VisualDensity.comfortable,
          onPressed: () {
            debugPrint('🔙 Wishlist: Header back button pressed');
            HapticFeedback.mediumImpact();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          'My Wishlist',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isInitialLoading.value && controller.wishlist.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                Text(
                  'Loading your wishlist...',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        if (controller.wishlist.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Wishlist is Empty!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add products you love to keep track of them here.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.wishlist.length,
              itemBuilder: (context, index) {
                final product = controller.wishlist[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WishlistCard(
                    product: product,
                    isProcessing: controller.isProcessingItem.value == product.id || 
                                  cartController.processingProductId.value.startsWith(product.id.toString()),
                    onRemove: () {
                      // Automatic removal as requested
                      controller.removeFromWishlist(product.id);
                    },
                  ),
                );
              },
            ),
            // Show a subtle progress indicator if processing something
            if (controller.isProcessingItem.value.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  color: AppColors.primaryGreen,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                ),
              ),
          ],
        );
      }),
    );
  }
}
