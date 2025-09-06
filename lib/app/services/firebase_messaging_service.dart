import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'package:mobiking/app/modules/orders/order_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/login_controller.dart';

class FirebaseMessagingService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LoginController? _loginController;
  final String _deviceTokenKey = 'fcm_device_token';

  void _log(String message) {
    print('[FirebaseMessagingService] $message');
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<LoginController>()) {
      _loginController = Get.find<LoginController>();
    }

    // Now, we listen for a successful login
    _loginController?.currentUser.listen((user) async {
      if (user != null && user['_id'] != null) {
        _log('User logged in: ${user['name']}. Attempting to update FCM token with userId.');
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _updateTokenWithUserId(token, user['_id']);
        }
      }
    });

    _configureFirebaseMessaging();
    _log('Firebase Messaging service initialized successfully');
  }

  Future<void> _configureFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _log('User granted permission: ${settings.authorizationStatus}');

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _log('Initial FCM Token obtained: Success');
        // Initial save with or without userId
        await _saveTokenToFirestore(token);
      } else {
        _log('Initial FCM Token obtained: Failed');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _log('FCM Token refreshed');
        _saveTokenToFirestore(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log('Received message in foreground');
        if (message.notification != null) {
          _log('Message contained notification: ${message.notification!.title}');
          Get.snackbar(
            message.notification!.title ?? "New Notification",
            message.notification!.body ?? "You have a new message.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.darkPurple,
            colorText: AppColors.white,
            duration: const Duration(seconds: 5),
            onTap: (_) => _handleNotificationTap(message.data),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log('App opened from notification tap');
        _handleNotificationTap(message.data);
      });

      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _log('App opened from initial message');
        _handleNotificationTap(initialMessage.data);
      }
    } catch (e) {
      _log('Error configuring Firebase Messaging: $e');
    }
  }

  // Initial save method, always uses the token as the document ID
  Future<void> _saveTokenToFirestore(String token) async {
    _log('Attempting to save initial token. Document ID: $token');
    try {
      await _firestore.collection('deviceTokens').doc(token).set(
        {
          'token': token,
          'platform': GetPlatform.isAndroid ? 'android' : (GetPlatform.isIOS ? 'ios' : 'web'),
          'createdAt': FieldValue.serverTimestamp(),
          'userId': null, // Explicitly set userId to null initially
        },
        SetOptions(merge: true),
      );
      _log('Initial FCM token stored successfully in Firestore with temp ID: $token');
    } catch (e) {
      _log('Error storing FCM token to Firestore: $e');
    }
  }

  // New method to update the token document with the user's ID
  Future<void> _updateTokenWithUserId(String token, String userId) async {
    _log('Attempting to update token document with user ID: $userId');
    try {
      await _firestore.collection('deviceTokens').doc(token).set(
        {
          'userId': userId,
        },
        SetOptions(merge: true),
      );
      _log('FCM token document updated successfully with user ID: $userId');
    } catch (e) {
      _log('Error updating FCM token document: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    String? screen = data['screen'];
    String? orderId = data['orderId'];
    _log('Handling notification tap for screen: $screen');

    if (screen == 'orders') {
      Get.to(() => OrderHistoryScreen(), arguments: {'orderId': orderId});
    } else if (screen == 'products') {
      Get.to(() => MainContainerScreen());
    } else {
      Get.to(() => MainContainerScreen());
    }
  }

  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      _log('FCM token retrieved: ${token != null ? "Success" : "Failed"}');
      return token;
    } catch (e) {
      _log('Error getting FCM token: $e');
      return null;
    }
  }

  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      _log('Notification permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e) {
      _log('Error getting notification permission status: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  Future<AuthorizationStatus> requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _log('Notification permission requested: ${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e) {
      _log('Error requesting notification permissions: $e');
      return AuthorizationStatus.denied;
    }
  }
}