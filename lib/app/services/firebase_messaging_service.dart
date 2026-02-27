import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'package:mobiking/app/modules/orders/order_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/login_controller.dart';

class FirebaseMessagingService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // NEW: Local Notifications for forcing images
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  void _log(String message) {
    print('[FirebaseMessagingService] $message');
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocalNotifications();
    _configureFirebaseMessaging();
    _log('Service Initialized');
  }

  // --- INITIALIZE LOCAL NOTIFICATIONS ---
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          // Handle tap from payload
        }
      },
    );

    // Create High Importance Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mobiking_high_importance_channel',
      'MobiKing Notifications',
      description: 'This channel is used for important shop updates and deals.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _configureFirebaseMessaging() async {
    try {
      await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _subscribeToAllUsersTopic();
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log('Foreground Message Received');
        
        final String title = message.notification?.title ?? message.data['title'] ?? "MobiKing";
        final String body = message.notification?.body ?? message.data['body'] ?? "New deals!";
        
        // Comprehensive Image Search
        final String? imageUrl = message.notification?.android?.imageUrl ?? 
                                message.data['image'] ?? 
                                message.data['imageUrl'] ??
                                message.data['bigPicture'];

        // Show standard system notification manually to force the image
        _showLocalNotification(title, body, imageUrl, message.data);
        
        // Also show our custom in-app UI if needed
        _showManualRichNotification(title, body, imageUrl, message.data);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });
    } catch (e) {
      _log('Config Error: $e');
    }
  }

  // --- SHOW FORCED IMAGE NOTIFICATION ---
  Future<void> _showLocalNotification(String title, String body, String? imageUrl, Map<String, dynamic> data) async {
    try {
      String? bigPicturePath;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        bigPicturePath = await _downloadAndSaveFile(imageUrl, 'notification_img');
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mobiking_high_importance_channel',
        'MobiKing Notifications',
        channelDescription: 'Shop updates and deals',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPicturePath != null 
            ? BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath))
            : null,
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);
      
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: imageUrl, // Can pass whatever payload needed
      );
    } catch (e) {
      _log('Local Notification Error: $e');
    }
  }

  // Helper to download image for BigPictureStyle
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      _log('Download Error: $e');
      return null;
    }
  }

  void _showManualRichNotification(String title, String body, String? imageUrl, Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.key.currentContext;
      if (context == null) return;
      OverlayState? overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => _ManualNotificationWidget(
          title: title, body: body, imageUrl: imageUrl,
          onTap: () { entry.remove(); _handleNotificationTap(data); },
          onDismiss: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 8), () {
        if (entry.mounted) entry.remove();
      });
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    String? screen = data['screen'];
    if (screen == 'orders') {
      Get.to(() => OrderHistoryScreen(), arguments: {'orderId': data['orderId']});
    } else {
      Get.to(() => MainContainerScreen());
    }
  }

  Future<void> _subscribeToAllUsersTopic() async {
    try { await _firebaseMessaging.subscribeToTopic('allUsers'); } catch (e) {}
  }

  Future<String?> getFCMToken() async => await _firebaseMessaging.getToken();
  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    return (await _firebaseMessaging.getNotificationSettings()).authorizationStatus;
  }
  Future<AuthorizationStatus> requestNotificationPermissions() async {
    return (await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true)).authorizationStatus;
  }
}

class _ManualNotificationWidget extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _ManualNotificationWidget({required this.title, required this.body, this.imageUrl, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 12, right: 12,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          onVerticalDragEnd: (_) => onDismiss(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: onDismiss),
                  ],
                ),
                Text(body, style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 180, color: Colors.white10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}