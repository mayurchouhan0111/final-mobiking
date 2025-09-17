import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  void _log(String message) {
    print('[ConnectivityService] $message');
  }

  // FIXED: Returns Stream<List<ConnectivityResult>>
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  // FIXED: Returns Future<List<ConnectivityResult>>
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _log('Current connectivity status: $result');
      return result;
    } catch (e) {
      _log('Exception in checkConnectivity: $e');
      return [ConnectivityResult.none];
    }
  }

  // FIXED: Uses List<ConnectivityResult>
  Future<bool> isConnected() async {
    try {
      final results = await checkConnectivity();
      final connected = !results.contains(ConnectivityResult.none);
      _log('Device connected: $connected');
      return connected;
    } catch (e) {
      _log('Exception in isConnected: $e');
      return false;
    }
  }

  // FIXED: Accepts List<ConnectivityResult> with proper type annotation
  String getConnectivityTypes(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return 'No Connection';
    }

    List<String> types = [];
    for (var result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          types.add('WiFi');
          break;
        case ConnectivityResult.mobile:
          types.add('Mobile Data');
          break;
        case ConnectivityResult.ethernet:
          types.add('Ethernet');
          break;
        case ConnectivityResult.bluetooth:
          types.add('Bluetooth');
          break;
        case ConnectivityResult.vpn:
          types.add('VPN');
          break;
        case ConnectivityResult.other:
          types.add('Other');
          break;
        case ConnectivityResult.none:
          break;
      }
    }
    return types.isNotEmpty ? types.join(', ') : 'Unknown';
  }
}
