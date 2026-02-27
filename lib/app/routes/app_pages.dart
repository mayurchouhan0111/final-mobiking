import 'package:get/get.dart';
import 'package:mobiking/app/modules/address/AddressPage.dart';
import 'package:mobiking/app/modules/checkout/CheckoutScreen.dart';
import 'package:mobiking/app/modules/home/home_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../bindings/user_binding.dart';

import 'package:get/get.dart';

import '../bindings/address_binding.dart';
import '../bindings/cart_binding.dart';
import '../bindings/category_binding.dart';
import '../bindings/group_binding.dart';
import '../bindings/order_binding.dart';
import '../bindings/product_binding.dart';
import '../bindings/stock_binding.dart';
import '../bindings/sub_category_binding.dart';
import '../bindings/user_binding.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: '/profile',
      page: () => ProfileScreen(),
      binding: UserBinding(),
    ),
    GetPage(
      name: '/address',
      page: () => AddressPage(),
      binding: AddressBinding(),
    ),
    GetPage(
      name: '/cart',
      page: () => CheckoutScreen(),
      binding: CartBinding(),
    ),
    GetPage(
      name: '/category',
      page: () => CheckoutScreen(),
      binding: CategoryBinding(),
    ),
    GetPage(name: '/group', page: () => HomeScreen(), binding: GroupBinding()),
    /* GetPage(
      name: '/order',
      page: () => CheckoutScreen(),
      binding: OrderBinding(),
    ),*/
    GetPage(name: '/stock', page: () => HomeScreen(), binding: StockBinding()),
    GetPage(
      name: '/sub-category',
      page: () => HomeScreen(),
      binding: SubCategoryBinding(),
    ),
  ];
}
