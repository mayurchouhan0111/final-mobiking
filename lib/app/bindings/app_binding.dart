import 'package:get/get.dart';
import 'package:mobiking/app/controllers/address_controller.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/controllers/coupon_controller.dart';
import 'package:mobiking/app/controllers/fcm_controller.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/controllers/order_controller.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';
import 'package:mobiking/app/controllers/user_controller.dart';
import 'package:mobiking/app/controllers/wishlist_controller.dart';
import 'package:mobiking/app/controllers/BottomNavController.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Using Get.put() for all controllers to ensure they are created
    // and available immediately when the app starts.

    // Foundational Controllers
    Get.put<ConnectivityController>(ConnectivityController());
    Get.put<ProductController>(ProductController());
    Get.put<CartController>(CartController());
    Get.put<WishlistController>(WishlistController());
    Get.put<SystemUIController>(SystemUIController());
    Get.put<LoginController>(LoginController());
    Get.put<UserController>(UserController());
    Get.put<FcmController>(FcmController());
    Get.put<CartController>(CartController());

    // Data Source Controllers
    Get.put<CategoryController>(CategoryController());
    Get.put<SubCategoryController>(SubCategoryController());

    // Dependent Feature Controllers

    Get.put<AddressController>(AddressController());
    Get.put<CouponController>(CouponController());
    Get.put<QueryGetXController>(QueryGetXController());
    Get.put<OrderController>(OrderController());
    Get.put<BottomNavController>(BottomNavController());
  }
}
