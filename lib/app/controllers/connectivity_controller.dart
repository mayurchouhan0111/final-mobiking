import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/services/connectivity_service.dart';

class ConnectivityController extends GetxController {
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  final RxBool isConnected = true.obs;
  final RxString connectionType = 'Unknown'.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    // FIXED: Handles List<ConnectivityResult>
    _connectivityService.checkConnectivity().then((results) {
      _updateConnectionStatus(results);
    });

    // FIXED: Handles List<ConnectivityResult>
    _connectivityService.connectivityStream.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  // FIXED: Accepts List<ConnectivityResult> with proper type annotation
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      isConnected.value = false;
      connectionType.value = 'No Connection';
    } else {
      isConnected.value = true;
      connectionType.value = _connectivityService.getConnectivityTypes(results);
    }
  }

  // FIXED: Handles List<ConnectivityResult>
  Future<void> retryConnection() async {
    final results = await _connectivityService.checkConnectivity();
    _updateConnectionStatus(results);
  }

  // Helper methods
  Future<bool> get isWiFiConnected async {
    final results = await _connectivityService.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<bool> get isMobileConnected async {
    final results = await _connectivityService.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }
}
