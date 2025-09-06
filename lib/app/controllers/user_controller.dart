import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserController extends GetxController {
  final _storage = GetStorage();
  RxString userName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserName();
  }

  void loadUserName() {
    final user = _storage.read('user');
    if (user != null && user['name'] != null) {
      userName.value = user['name'];
    }
  }

  void saveUserName(String name) {
    final user = _storage.read('user') ?? {};
    user['name'] = name;
    _storage.write('user', user);
    userName.value = name;
  }
}