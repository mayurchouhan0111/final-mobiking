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

  // Delete account related observables
  RxBool isDeletingAccount = false.obs;

  // Timer for OTP resend countdown
  Timer? _otpResendTimer;
  RxInt otpTimeRemaining = 0.obs; // Countdown in seconds
  static const int _otpResendCooldown = 60; // 60 seconds cooldown

  Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  final CartController _cartController = Get.find<CartController>();
  final WishlistController _wishlistController = Get.find<WishlistController>();

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserFromStorage();
    checkLoginStatus();

    ever(_connectivityController.isConnected, (bool isConnected) {
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
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

      if (response.statusCode == 200) {
        // Safely cast response.data to a Map
        final Map<String, dynamic>? responseData = response.data is Map
            ? response.data as Map<String, dynamic>
            : null;

        if (responseData != null && responseData['success'] == true) {
          currentOtpPhoneNumber.value = phoneNumber; // Store phone number for resend
          print('LoginController: OTP sent successfully');
          _startOtpResendTimer(); // Start the countdown timer
          return true;
        } else {
          // Handle cases where responseData is null or 'success' is false
          throw Exception(responseData?['message'] ?? 'Failed to send OTP');
        }
      } else {
        // Handle non-200 status codes
        final Map<String, dynamic>? errorData = response.data is Map
            ? response.data as Map<String, dynamic>
            : null;
        throw Exception(errorData?['message'] ?? 'Failed to send OTP with status ${response.statusCode}');
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
        final Map<String, dynamic>? cart = user?['cart'];
        String? cartId = cart?['_id'];

        // Store user data
        await box.write('user', user);
        await box.write('cartId', cartId);

        print('LoginController: User object before setting currentUser: $user');
        print('LoginController: User _id before setting currentUser: ${user?['_id']}');
        currentUser.value = user;

        // Clear OTP related data
        _clearOtpData();

        print('LoginController: OTP verified and user logged in successfully');
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

  // DELETE ACCOUNT METHOD - NEW ADDITION
  // DELETE ACCOUNT METHOD - UPDATED VERSION
  Future<bool> deleteAccount({String? confirmationText}) async {
    if (isDeletingAccount.value) return false;

    isDeletingAccount.value = true;
    try {
      print('LoginController: Attempting to delete user account...');

      // Check if user is logged in
      if (currentUser.value == null || box.read('accessToken') == null) {
        Get.snackbar(
          'Error',
          'Please log in to delete your account',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // If confirmation is required, validate it here in the controller
      if (confirmationText != null) {
        if (confirmationText.toUpperCase() != 'DELETE') {
          Get.snackbar(
            'Error',
            'Please type "DELETE" to confirm account deletion',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
        print('LoginController: Confirmation validated. User typed: $confirmationText');
      }

      // Call the delete user API from LoginService (only the basic deleteUser method)
      await loginService.deleteUser();

      // Clear all data after successful deletion
      await _clearAllUserData();

      // Show success message
      Get.snackbar(
        'Success',
        'Account deleted successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('LoginController: Account deleted successfully');

      // Navigate to login screen and clear all navigation stack
      Get.offAll(() => PhoneAuthScreen());

      return true;
    } catch (e) {
      print('LoginController: Error deleting account: $e');

      // Handle different types of errors based on LoginService exceptions
      String errorMessage = 'Failed to delete account';

      if (e.toString().contains('Access token not found')) {
        errorMessage = 'Please log in again to delete your account';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection';
      } else if (e.toString().contains('Access denied')) {
        errorMessage = 'Access denied. Please log in again';
      } else if (e.toString().contains('User account not found')) {
        errorMessage = 'Account not found. It may have been already deleted';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = 'Cannot delete account. Please contact support';
      } else if (e.toString().contains('Server error')) {
        errorMessage = 'Server error occurred. Please try again later';
      } else {
        // Clean up the error message by removing the exception prefix
        errorMessage = e.toString()
            .replaceAll('LoginServiceException: ', '')
            .replaceAll('[Status 401] ', '')
            .replaceAll('[Status 403] ', '')
            .replaceAll('[Status 404] ', '')
            .replaceAll('[Status 500] ', '');
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } finally {
      isDeletingAccount.value = false;
    }
  }

// SIMPLIFIED: Method to check if user can delete account (local validation only)
  bool canDeleteAccount() {
    // Simple local validation - just check if user is logged in and has valid tokens
    final hasUser = currentUser.value != null;
    final hasAccessToken = box.read('accessToken') != null;
    final hasRefreshToken = box.read('refreshToken') != null;

    print('LoginController: canDeleteAccount - User: $hasUser, AccessToken: $hasAccessToken, RefreshToken: $hasRefreshToken');

    return hasUser && hasAccessToken && hasRefreshToken;
  }

// OPTIONAL: Method to validate account deletion eligibility with additional checks
  Future<bool> validateAccountDeletion() async {
    try {
      // Basic validation first
      if (!canDeleteAccount()) {
        return false;
      }

      // Check if tokens are not expired
      if (loginService.isTokenExpired()) {
        print('LoginController: Token expired, user needs to re-login for account deletion');
        return false;
      }

      // Optional: Check service health before allowing deletion
      final isHealthy = await loginService.checkServiceHealth();
      if (!isHealthy) {
        print('LoginController: Service is not healthy, account deletion not available');
        return false;
      }

      return true;
    } catch (e) {
      print('LoginController: Error validating account deletion: $e');
      return false;
    }
  }

  // Clear all user data from storage and controllers
  Future<void> _clearAllUserData() async {
    try {
      print('LoginController: Clearing all user data...');

      // Cancel timers
      _otpResendTimer?.cancel();

      // Clear OTP data
      _clearOtpData();

      // Clear all stored data
      loginService.clearAllTokenData();
      box.remove('userPreferences');
      box.remove('favorites');
      box.remove('settings');
      box.remove('last_login_phone');

      // Reset controller state
      currentUser.value = null;
      phoneController.clear();

      // Clear cart and wishlist data
      _cartController.clearCartData();

      print('LoginController: All user data cleared successfully');
    } catch (e) {
      print('LoginController: Error clearing user data: $e');
    }
  }

  Future<void> _handleConnectionRestored() async {
    print('LoginController: Internet connection restored. Attempting to refresh user data/session...');
    if (currentUser.value != null && box.read('accessToken') != null) {
      try {
        await manualRefreshToken();
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

  void checkLoginStatus() {
    if (loginService.hasValidTokens()) {
      _loadCurrentUserFromStorage();
      loginService.startTokenRefreshTimer();
    }
  }

  Future<void> _refreshToken({int retryCount = 0}) async {
    print('LoginController: _refreshToken() called at ${DateTime.now()}');
    final refreshToken = loginService.getCurrentRefreshToken();
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
        final updatedUser = responseData['user'];
        final updatedCart = responseData['cart'];
        final updatedWishlist = responseData['wishlist'];

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
      } else {
        print('LoginController: Token refresh failed. Response: ${response.data}');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      }
    } catch (e) {
      print('LoginController: Token refresh error: $e');

      if (e is dio.DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          print('LoginController: Refresh token expired or invalid. Logging out...');
          _clearLoginData();
          Get.offAll(() => PhoneAuthScreen());
        } else if (retryCount < 3) {
          final delay = Duration(seconds: 5 * (retryCount + 1));
          print('LoginController: Network error during refresh. Retrying in ${delay.inSeconds} seconds...');
          Timer(delay, () => _refreshToken(retryCount: retryCount + 1));
        } else {
          print('LoginController: Max retry attempts reached. Logging out...');
          _clearLoginData();
          Get.offAll(() => PhoneAuthScreen());
        }
      } else {
        print('LoginController: An unexpected error occurred during refresh. Logging out...');
        _clearLoginData();
        Get.offAll(() => PhoneAuthScreen());
      }
    }
  }

  void _clearLoginData() {
    _otpResendTimer?.cancel();
    _clearOtpData();
    loginService.clearAllTokenData();
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

    if (phone.length != 10 || !RegExp(r'^[0-9]+').hasMatch(phone)) {
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
        // Handle logout error
      }
    } catch (e) {
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
    return loginService.getTokenStatus();
  }
}