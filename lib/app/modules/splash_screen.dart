import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'package:mobiking/app/modules/login/login_screen.dart';

import '../controllers/category_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/sub_category_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // 🚀 Start pre-fetching all critical data in parallel while splash is showing
    final categoryController = Get.find<CategoryController>();
    final productController = Get.find<ProductController>();
    final subCategoryController = Get.find<SubCategoryController>();
    final homeController = Get.find<HomeController>();

    categoryController.fetchCategories();
    productController.loadProductsOnDemand();
    subCategoryController.loadSubCategories();
    homeController.fetchHomeLayout();

    // Increased delay to 2500ms so the logo animation can play fully
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // ✅ APP STORE COMPLIANCE: Always allow users to enter the app to browse.
    // We only require login for account-based features (Adding to Cart, Checkout).
    Get.off(
      () => MainContainerScreen(),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Wrap the body with SafeArea to handle system insets
      body: Center(
        child: Image.asset(
          'assets/animations/splash0001.gif',
          width: MediaQuery.of(context).size.width * 0.6,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
