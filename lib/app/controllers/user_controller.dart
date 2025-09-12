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

  Future<void> updateUser({String? name, String? email, String? phone}) async {
    final user = _storage.read('user') ?? {};
    if (name != null) {
      user['name'] = name;
      userName.value = name;
    }
    if (email != null) {
      user['email'] = email;
    }
    if (phone != null) {
      user['phoneNo'] = phone;
    }
    await _storage.write('user', user);
  }
}