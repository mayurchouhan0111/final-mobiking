import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../themes/app_theme.dart';

class QuantityAndCartRow extends StatelessWidget {
  const QuantityAndCartRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {},
                iconSize: 20,
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '1',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {},
                iconSize: 20,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            final cartController = Get.find<CartController>();
            final box = GetStorage();
            final userData = box.read('userData') ?? {};
            final cartId = userData['cartId'] ?? '';

            cartController.addToCart(
              productId: '683e8aa4352ed33496cc8193',
              variantName: 'Raging Black',
            );
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.success,
          ),
          child: const Text(
            'Add to Cart',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
