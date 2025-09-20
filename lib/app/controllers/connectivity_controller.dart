import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/services/connectivity_service.dart';

class ConnectivityController extends GetxController {
  // It's good practice to make the service private if only used within this class.
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();

  // These reactive variables will automatically update the UI when their values change.
  final RxBool isConnected = true.obs;
  final RxString connectionType = 'Unknown'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeConnectivity();
  }

  /// Sets up the initial connectivity status and listens for future changes.
  void _initializeConnectivity() {
    // Check the initial connection status when the controller is first created.
    _connectivityService.checkConnectivity().then((result) {
      _updateConnectionStatus(result);
    });

    // Listen to the stream for any subsequent changes in connectivity.
    _connectivityService.connectivityStream.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  /// Updates the reactive variables based on the connectivity result.
  ///
  /// **Correction**: This method now accepts a single `ConnectivityResult`.
  void _updateConnectionStatus(ConnectivityResult result) {
    // The condition is now a simple comparison.
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
      connectionType.value = 'No Connection';
    } else {
      isConnected.value = true;
      // Use the corrected helper method from the service.
      connectionType.value = _connectivityService.getConnectivityStatusString(result);
    }
  }

  /// Manually triggers a check for the current connection status.
  /// Useful for a "Retry" button in the UI.
  Future<void> refreshConnectionStatus() async {
    final result = await _connectivityService.checkConnectivity();
    _updateConnectionStatus(result);
  }

  // --- Helper Getters ---

  /// A convenient getter to check if the connection is WiFi.
  Future<bool> get isWiFiConnected async {
    final result = await _connectivityService.checkConnectivity();
    return result == ConnectivityResult.wifi;
  }

  /// A convenient getter to check if the connection is Mobile Data.
  Future<bool> get isMobileConnected async {
    final result = await _connectivityService.checkConnectivity();
    return result == ConnectivityResult.mobile;
  }
}