import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// A GetX service to monitor network connectivity status.
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  void _log(String message) {
    // A simple logger for debugging.
    print('[ConnectivityService] $message');
  }

  /// Provides a stream that emits the connectivity status whenever it changes.
  ///
  /// **Correction**: The `onConnectivityChanged` stream from the `connectivity_plus`
  /// package emits a single `ConnectivityResult`, not a list.
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Checks the current connectivity status of the device.
  ///
  /// **Correction**: The `checkConnectivity` method returns a `Future` with a
  /// single `ConnectivityResult`.
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _log('Current connectivity status: $result');
      return result;
    } catch (e) {
      _log('Exception in checkConnectivity: $e');
      return ConnectivityResult.none;
    }
  }

  /// Returns `true` if the device has an active network connection (e.g., WiFi, Mobile).
  ///
  /// Returns `false` if the connection is `ConnectivityResult.none` or if an error occurs.
  Future<bool> isConnected() async {
    try {
      final result = await checkConnectivity();
      // **Correction**: The check is now a simple comparison, not a list lookup.
      final connected = result != ConnectivityResult.none;
      _log('Device connected: $connected');
      return connected;
    } catch (e) {
      _log('Exception in isConnected: $e');
      return false;
    }
  }

  /// Converts a [ConnectivityResult] enum into a user-friendly string.
  ///
  /// **Correction**: This utility method now accepts a single `ConnectivityResult`
  /// and uses a more efficient `switch` statement.
  String getConnectivityStatusString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }
}
