// lib/app/controllers/login_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import '../modules/login/login_screen.dart';
import '../services/login_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';

import 'package:mobiking/app/controllers/wishlist_controller.dart';

import 'package:mobiking/app/data/wishlist_model.dart';

import 'cart_controller.dart';

class LoginController extends GetxController {
  final LoginService loginService = Get.find<LoginService>();
  final TextEditingController phoneController = TextEditingController();
  final box = GetStorage();
  RxBool isLoading = false.obs;

  // OTP related observables
  RxBool isOtpLoading = false.obs;
  RxBool isResendingOtp = false.obs;
  RxString currentOtpPhoneNumber = ''.obs;

  // Timer for OTP resend countdown
  Timer? _otpResendTimer;
  RxInt otpTimeRemaining = 0.obs; // Countdown in seconds
  static const int _otpResendCooldown = 60; // 60 seconds cooldown

  Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  final CartController _cartController = Get.find<CartController>();
  final WishlistController _wishlistController = Get.find<WishlistController>();

  // Timer for automatic token refresh
  Timer? _tokenRefreshTimer;
  static const Duration _refreshInterval = Duration(hours: 20); // Refresh token after 20 hours
  static const Duration _tokenValidityPeriod = Duration(hours: 24); // Token is valid for 24 hours

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserFromStorage();
    checkLoginStatus();
    _startTokenRefreshTimer(); // Start automatic refresh timer

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    _tokenRefreshTimer?.cancel(); // Cancel token refresh timer
    _otpResendTimer?.cancel(); // Cancel OTP resend timer
    super.onClose();
  }

  // Send OTP method
  Future<bool> sendOtp(String phoneNumber) async {
    if (isOtpLoading.value) return false;

    isOtpLoading.value = true;
    try {
      print('LoginController: Sending OTP to $phoneNumber');

      final response = await loginService.sendOtp(phoneNumber);

      if (response.statusCode == 200 && response.data['success'] == true) {
        currentOtpPhoneNumber.value = phoneNumber; // Store phone number for resend
        

        print('LoginController: OTP sent successfully');
        _startOtpResendTimer(); // Start the countdown timer
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('LoginController: Error sending OTP: $e');

      

      return false;
    } finally {
      isOtpLoading.value = false;
    }
  }

  // Verify OTP method
  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    if (isOtpLoading.value) return false;

    if (phoneNumber.isEmpty || otpCode.isEmpty) {
      
      return false;
    }

    isOtpLoading.value = true;
    try {
      print('LoginController: Verifying OTP for $phoneNumber');

      final response = await loginService.verifyOtp(phoneNumber, otpCode);

      if (response.statusCode == 200 && response.data['success'] == true) {
        // OTP verification successful - user is now logged in
        final responseData = response.data['data'];
        final user = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        final Map<String, dynamic>? cart = user?['cart'];
        String? cartId = cart?['_id'];

        // Store tokens and user data
        await box.write('accessToken', accessToken);
        await box.write('refreshToken', refreshToken);
        await box.write('user', user);
        await box.write('cartId', cartId);
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);
        print('LoginController: tokenCreationTime written: ${box.read('tokenCreationTime')}');

        currentUser.value = user;

        // Clear OTP related data
        _clearOtpData();

        // Start automatic token refresh timer
        _startTokenRefreshTimer();

        print('LoginController: OTP verified and user logged in successfully');
        print('Access Token: ${box.read('accessToken')}');
        print('User data: ${box.read('user')}');
        print('Cart ID: ${box.read('cartId')}');

        

        // Navigate to main app
        Get.offAll(() => MainContainerScreen());
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('LoginController: Error verifying OTP: $e');
      
      return false;
    } finally {
      isOtpLoading.value = false;
    }
  }

  // Resend OTP method
  Future<bool> resendOtp() async {
    if (!canResendOtp()) return false;

    isResendingOtp.value = true;
    try {
      print('LoginController: Resending OTP to ${currentOtpPhoneNumber.value}');

      final response = await loginService.sendOtp(currentOtpPhoneNumber.value); // Re-use sendOtp

      if (response.statusCode == 200 && response.data['success'] == true) {
        

        print('LoginController: OTP resent successfully');
        _startOtpResendTimer(); // Restart the countdown timer
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      print('LoginController: Error resending OTP: $e');

      

      return false;
    } finally {
      isResendingOtp.value = false;
    }
  }

  // Method to start the OTP resend timer
  void _startOtpResendTimer() {
    _otpResendTimer?.cancel(); // Cancel any existing timer
    otpTimeRemaining.value = _otpResendCooldown;
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimeRemaining.value > 0) {
        otpTimeRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // Method to format the remaining time for the UI
  String getFormattedTimeRemaining() {
    int seconds = otpTimeRemaining.value;
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  // Clear OTP related data
  void _clearOtpData() {
    currentOtpPhoneNumber.value = '';
    _otpResendTimer?.cancel(); // Stop timer on clear
    otpTimeRemaining.value = 0; // Reset timer value
  }

  // Check if OTP can be resent
  bool canResendOtp() {
    return !isResendingOtp.value && otpTimeRemaining.value == 0;
  }

  Future<void> _handleConnectionRestored() async {
    print('LoginController: Internet connection restored. Attempting to refresh user data/session...');
    if (currentUser.value != null && box.read('accessToken') != null) {
      try {
        await _checkAndRefreshTokenIfNeeded();
        print('LoginController: User session or data re-validated/refreshed successfully.');
      } catch (e) {
        print('LoginController: Failed to refresh user data/session on reconnect: $e');
      }
    }
  }

  void _loadCurrentUserFromStorage() {
    final storedUser = box.read('user');
    if (storedUser != null && storedUser is Map<String, dynamic>) {
      currentUser.value = storedUser;
    } else {
      currentUser.value = null;
    }
  }

  void checkLoginStatus() async {
    final accessToken = box.read('accessToken');
    final refreshToken = box.read('refreshToken');
    final tokenCreationTime = box.read('tokenCreationTime');

    if (accessToken != null && refreshToken != null && tokenCreationTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // ✅ CORRECTED: Cast the value from storage to num and then convert to int.
      final tokenAge = Duration(milliseconds: now - (tokenCreationTime as num).toInt());

      if (tokenAge >= _tokenValidityPeriod) {
        print('LoginController: Token expired (${tokenAge.inHours} hours old). Logging out...');
        _clearLoginData();
      } else if (tokenAge >= _refreshInterval) {
        print('LoginController: Token needs refresh (${tokenAge.inHours} hours old). Refreshing...');
        await _refreshToken();
      } else {
        print('LoginController: Access token is valid (${tokenAge.inHours} hours old).');
      }
    } else {
      print('LoginController: No access token, refresh token, or creation time found.');
    }
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    final tokenCreationTime = box.read('tokenCreationTime');
    final accessToken = box.read('accessToken');
    print('LoginController: _startTokenRefreshTimer called.');
    print('LoginController: tokenCreationTime: $tokenCreationTime');
    print('LoginController: accessToken: $accessToken');

    if (tokenCreationTime == null || accessToken == null) {
      print('LoginController: Token creation time or access token is null. Cannot start refresh timer.');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    // ✅ CORRECTED: Cast the value from storage to num and then convert to int.
    final tokenAge = now - (tokenCreationTime as num).toInt();

    Duration effectiveRefreshInterval = loginService.isTestingTokenRefresh.value
        ? const Duration(minutes: 1) // 1 minute for testing
        : _refreshInterval; // 20 hours for normal operation

    final nextRefreshTimeMs = effectiveRefreshInterval.inMilliseconds - tokenAge;

    if (nextRefreshTimeMs <= 0) {
      _refreshToken();
      return;
    }

    print('LoginController: Next token refresh scheduled in ${(nextRefreshTimeMs / (1000 * 60 * 60)).toStringAsFixed(1)} hours');

    _tokenRefreshTimer = Timer(Duration(milliseconds: nextRefreshTimeMs), () {
      _refreshToken();
    });
  }

  Future<void> _checkAndRefreshTokenIfNeeded() async {
    final tokenCreationTime = box.read('tokenCreationTime');
    if (tokenCreationTime == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // ✅ CORRECTED: Cast the value from storage to num and then convert to int.
    final tokenAge = Duration(milliseconds: now - (tokenCreationTime as num).toInt());

    Duration effectiveRefreshInterval = loginService.isTestingTokenRefresh.value
        ? const Duration(minutes: 1) // 1 minute for testing
        : _refreshInterval; // 20 hours for normal operation

    if (tokenAge >= effectiveRefreshInterval) {
      await _refreshToken();
    }
  }

  Future<void> _refreshToken() async {
    print('LoginController: _refreshToken() called at \${DateTime.now()}'); // Added print statement
    final refreshToken = box.read('refreshToken');
    if (refreshToken == null) {
      print('LoginController: No refresh token available. Logging out...');
      _clearLoginData();
      return;
    }

    try {
      print('LoginController: Refreshing access token...');

      dio.Response response = await loginService.refreshToken(refreshToken);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final newAccessToken = responseData['accessToken'];
        final newRefreshToken = responseData['refreshToken'];
        final updatedUser = responseData['user'];
        final updatedCart = responseData['cart'];
        final updatedWishlist = responseData['wishlist'];

        await box.write('accessToken', newAccessToken);
        await box.write('tokenCreationTime', DateTime.now().millisecondsSinceEpoch);

        if (newRefreshToken != null) {
          await box.write('refreshToken', newRefreshToken);
        }

        if (updatedUser != null) {
          await box.write('user', updatedUser);
          currentUser.value = updatedUser;
        }

        if (updatedCart != null) {
          _cartController.updateCartFromLogin(updatedCart as Map<String, dynamic>);
          await box.write('cartId', updatedCart['_id']);
        }

        if (updatedWishlist != null) {
          _wishlistController.updateWishlistFromLogin(updatedWishlist as List<dynamic>);
        }

        print('LoginController: Token refreshed successfully');
        _startTokenRefreshTimer();

      } else {
        print('LoginController: Token refresh failed. Response: \${response.data}');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      }
    } catch (e) {
      print('LoginController: Token refresh error: \$e');

      if (e is dio.DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        print('LoginController: Refresh token expired or invalid. Logging out...');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      } else {
        print('LoginController: Network error during refresh. Retrying in 5 minutes...');
        Timer(const Duration(minutes: 5), () => _refreshToken());
      }
    }
  }

  void _clearLoginData() {
    _tokenRefreshTimer?.cancel();
    _clearOtpData();
    box.remove('accessToken');
    box.remove('refreshToken');
    box.remove('user');
    box.remove('cartId');
    box.remove('tokenCreationTime');
    currentUser.value = null;
  }

  dynamic getUserData(String key) {
    return currentUser.value?[key];
  }

  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      
      return;
    }

    bool otpSent = await sendOtp(phone);
    if (otpSent) {
      // You would typically navigate to the OTP screen here
      // Get.to(() => OtpVerificationScreen(phoneNumber: phone));
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      dio.Response response = await loginService.logout();

      if (response.statusCode == 200 && response.data['success'] == true) {
        _clearLoginData();
        
        Get.offAll(() => PhoneAuthScreen());
      } else {
        
      }
    } catch (e) {
      // Get.snackbar(
      //   'Error',
      //   'Logout failed: ${e.toString()}',
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
      print('Logout Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> manualRefreshToken() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      await _refreshToken();
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getTokenStatus() {
    final tokenCreationTime = box.read('tokenCreationTime');
    final accessToken = box.read('accessToken');

    if (tokenCreationTime == null || accessToken == null) {
      return {
        'hasToken': false,
        'ageHours': 0.0,
        'needsRefresh': false,
        'isExpired': true,
      };
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    // ✅ CORRECTED: Cast the value from storage to num and then convert to int.
    final tokenAge = Duration(milliseconds: now - (tokenCreationTime as num).toInt());
    final tokenAgeHours = tokenAge.inMilliseconds / (1000 * 60 * 60);

    return {
      'hasToken': true,
      'ageHours': tokenAgeHours,
      'needsRefresh': tokenAge >= _refreshInterval,
      'isExpired': tokenAge >= _tokenValidityPeriod,
    };
  }
}
