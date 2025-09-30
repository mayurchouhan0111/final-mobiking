import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/services/login_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/controllers/wishlist_controller.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import 'package:mobiking/app/services/user_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await GetStorage.init();
      // Initialize dependencies
      final dioInstance = dio.Dio();
      final getStorageBox = GetStorage();
      Get.put(UserService(dioInstance));
      Get.put(LoginService(dioInstance, getStorageBox, Get.find<UserService>()));
      Get.put(ConnectivityController());
      Get.put(CartController());
      Get.put(WishlistController());

      // Initialize GetX
      Get.put(LoginController());
      final loginController = Get.find<LoginController>();
      await loginController.manualRefreshToken();
      return Future.value(true);
    } catch (e) {
      print('Background task failed: $e');
      return Future.value(false);
    }
  });
}
