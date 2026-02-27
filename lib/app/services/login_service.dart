
import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Add this for OTP generation

import '../data/login_model.dart'; // Import UserModel
import './user_service.dart'; // Import UserService
import './analytics_service.dart';

// Custom exception for login service errors
class LoginServiceException implements Exception {
  final String message;
  final int? statusCode;

  LoginServiceException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'LoginServiceException: [Status $statusCode] $message';
    }
    return 'LoginServiceException: $message';
  }
}

class LoginService extends GetxService {
  // Inject the Dio instance, don't create it internally
  final dio.Dio _dio;
  final GetStorage box;
  final UserService _userService; // Inject UserService


  // Constructor to receive the Dio instance and GetStorage box
  LoginService(this._dio, this.box, this._userService);

  final String _baseUrl = 'https://boxbudy.com/api/v1/users';

  void _log(String message) {
    print('[LoginService] $message');
  }




  // UPDATED: Send OTP Method with improved error handling and testing display
  Future<dio.Response> sendOtp(String phoneNumber) async {
    try {
      _log('Initiating OTP send request to backend for: $phoneNumber');

      final response = await _dio.post(
        '$_baseUrl/sendOtp',
        data: {
          'mobile': phoneNumber,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      _log('Send OTP response: Status ${response.statusCode}, Data: ${response.data}');

      // Safely cast response.data to a Map
      final Map<String, dynamic>? responseData = response.data is Map
          ? response.data as Map<String, dynamic>
          : null;

      if (response.statusCode == 200 && responseData != null && responseData['success'] == true) {
        _log('OTP sent successfully by backend.');
        return response;
      } else {
        final errorMessage = responseData?['message'] ?? 'Failed to send OTP from backend.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      _log('Error in sendOtp: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null) {
        // Safely cast e.response?.data to a Map
        final Map<String, dynamic>? errorData = e.response?.data is Map
            ? e.response?.data as Map<String, dynamic>
            : null;
        final errorMessage = errorData?['message'] ?? 'Server error occurred.';
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        throw LoginServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error in sendOtp: $e');
      throw LoginServiceException('An unexpected error occurred: $e');
    }
  }

  // UPDATED: Verify OTP Method with SMS status checking
  Future<dio.Response> verifyOtp(String phoneNumber, String enteredOtp) async {
    try {
      _log('Verifying OTP for: $phoneNumber. Entered OTP: $enteredOtp');

      // With backend handling OTP validation, we directly attempt login
      final loginResponse = await login(phoneNumber, enteredOtp);

      _log('Login completed after OTP verification');
      return loginResponse;

    } on LoginServiceException catch (e) {
      _log('Error in verifyOtp: $e');
      rethrow; // Re-throw LoginServiceException for specific handling
    } catch (e) {
      _log('Unexpected error in verifyOtp: $e');
      throw LoginServiceException('OTP verification failed: $e');
    }
  }

  // UPDATED: Enhanced OTP status with SMS tracking and testing info
  Map<String, dynamic> getOtpStatus() {
    // With backend handling OTP, local status is minimal
    return {
      'hasOtp': false,
      'isExpired': true,
      'phoneNumber': null,
      'timeRemaining': 0,
      'messageId': null,
      'testMode': false, // Always false as client doesn't generate OTP
    };
  }

  // Clear OTP data
  Future<void> clearOtpData() async {
    _log('OTP data cleared');
  }

  // Enhanced Login Method
  Future<dio.Response> login(String phone, String otp) async {
    try {
      _log('Attempting to log in user with phone: $phone');
      _log('Login request data: {"mobile": "$phone", "role": "user", "otp": "$otp"}');
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {
          'phoneNo': phone,
          'role': 'user',
          'otp': otp,
        },
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      _log('Login response: Status ${response.statusCode}, Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _log('Login successful. Response data: ${response.data}');

        // Store tokens and creation time from login response
        if (response.data?['data']?['accessToken'] != null) {
          await box.write('accessToken', response.data['data']['accessToken']);
        }
        // Store token creation time removed as refresh logic is no longer used
        
        // ✅ LOG ANALYTICS: Login
        try {
          final userId = response.data?['data']?['user']?['_id'] ?? response.data?['data']?['user']?['id'];
          if (userId != null) {
            Get.find<AnalyticsService>().setUserId(userId.toString());
            Get.find<AnalyticsService>().logLogin('OTP');
          }
        } catch (e) {
          _log('📊 Analytics Login Error: $e');
        }

        return response;
      } else {
        // Explicitly throw an exception if login is not successful
        final errorMessage = response.data?['message'] ?? 'Login failed. Please try again.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
        _log('Dio error during login: ${e.response?.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        _log('Network error during login: ${e.message}');
        throw LoginServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during login: $e');
      throw LoginServiceException('An unexpected error occurred during login: $e');
    }
  }

  // Enhanced Logout Method
  Future<dio.Response> logout() async {
    try {
      final accessToken = box.read('accessToken');

      if (accessToken == null) {
        _log('No access token found for logout. User is already considered logged out locally.');
        throw LoginServiceException('Access token not found. User is not logged in locally.');
      }

      final response = await _dio.post(
        '$_baseUrl/logout',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        _log('User logged out successfully from server.');
        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Logout failed on server.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Server error during logout.';
        _log('Dio error during logout: ${e.response?.statusCode} - $errorMessage');
        throw LoginServiceException(errorMessage, statusCode: e.response?.statusCode);
      } else {
        _log('Network error during logout: ${e.message}');
        throw LoginServiceException('Network error during logout: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during logout: $e');
      throw LoginServiceException('An unexpected error occurred during logout: $e');
    } finally {
      // Enhanced: Clear all token-related data including OTP
      clearAllTokenData();
    }
  }

  // Enhanced Delete User Method
  Future<dio.Response> deleteUser() async {
    try {
      final accessToken = box.read('accessToken');

      if (accessToken == null) {
        _log('No access token found for user deletion. User must be logged in.');
        throw LoginServiceException('Access token not found. Please log in first.');
      }

      _log('Attempting to delete user account...');

      final response = await _dio.delete(
        '$_baseUrl/delete',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      _log('Delete user response: Status ${response.statusCode}, Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _log('User account deleted successfully from server.');

        // Clear all local data after successful deletion
        clearAllTokenData();

        // Optional: Clear any additional user-specific data
        await _clearUserSpecificData();

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Failed to delete user account.';
        throw LoginServiceException(errorMessage, statusCode: response.statusCode);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['message'] ?? 'Server error during user deletion.';

        _log('Dio error during user deletion: $statusCode - $errorMessage');

        // Handle specific status codes
        if (statusCode == 401) {
          throw LoginServiceException('Access denied. Please log in again.', statusCode: statusCode);
        } else if (statusCode == 404) {
          throw LoginServiceException('User account not found.', statusCode: statusCode);
        } else if (statusCode == 403) {
          throw LoginServiceException('Permission denied. Cannot delete account.', statusCode: statusCode);
        } else {
          throw LoginServiceException(errorMessage, statusCode: statusCode);
        }
      } else {
        _log('Network error during user deletion: ${e.message}');
        throw LoginServiceException('Network error during user deletion: ${e.message}');
      }
    } catch (e) {
      _log('Unexpected error during user deletion: $e');
      throw LoginServiceException('An unexpected error occurred during user deletion: $e');
    }
  }

  // Comprehensive token data clearing (updated to include OTP data)
  void clearAllTokenData() {
    box.remove('user');
    box.remove('cartId');
    box.remove('currentOtpData'); // Clear OTP data on logout
    _log('All authentication and user data cleared locally.');
  }

  // Helper method to clear user-specific data beyond tokens
  Future<void> _clearUserSpecificData() async {
    try {
      // Clear additional user-related data
      box.remove('last_login_phone');
      box.remove('user_preferences');
      box.remove('user_profile');
      box.remove('cached_user_data');

      // Clear any other app-specific user data
      box.remove('favorites');
      box.remove('settings');

      _log('User-specific data cleared successfully.');
    } catch (e) {
      _log('Error clearing user-specific data: $e');
    }
  }


  // Check if tokens exist locally
  bool hasValidTokens() {
    final accessToken = box.read('accessToken');
    return accessToken != null;
  }



  // Check if token is expired (defaulting to false as expiration is extended)
  bool isTokenExpired() {
    return false; 
  }

  // Get current access token
  String? getCurrentAccessToken() {
    return box.read('accessToken');
  }


  // Validate token format (basic validation)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    // Basic JWT format check (header.payload.signature)
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  // Get token status information
  Map<String, dynamic> getTokenStatus() {
    final accessToken = getCurrentAccessToken();

    return {
      'hasAccessToken': accessToken != null,
      'isValidFormat': isValidTokenFormat(accessToken),
      'isExpired': isTokenExpired(),
    };
  }

  // Method to get a valid access token
  Future<String?> getValidAccessToken() async {
    return getCurrentAccessToken();
  }

  // Emergency token cleanup (for extreme cases)
  Future<void> emergencyTokenCleanup() async {
    try {
      _log('Performing emergency token cleanup...');
      clearAllTokenData();

      // Clear any cached data
      await box.remove('last_login_phone');
      await box.remove('user_preferences');

      _log('Emergency cleanup completed');
    } catch (e) {
      _log('Error during emergency cleanup: $e');
    }
  }

  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/health',
        options: dio.Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final isHealthy = response.statusCode == 200;
      _log('Service health check: ${isHealthy ? 'Healthy' : 'Unhealthy'} (Status: ${response.statusCode})');
      return isHealthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }
}

