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
import 'package:image/image.dart' as img;

import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'package:mobiking/app/modules/orders/order_screen.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/controllers/login_controller.dart';

class FirebaseMessagingService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        final String? imageUrl = message.notification?.android?.imageUrl ??
            message.data['image'] ??
            message.data['imageUrl'] ??
            message.data['bigPicture'];

        // FIX: Only show the manual in-app overlay when the app is in the foreground.
        // Calling _showLocalNotification here as well guarantees a duplicate.
        _showManualRichNotification(title, body, imageUrl, message.data);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });
    } catch (e) {
      _log('Config Error: $e');
    }
  }

  Future<void> _showLocalNotification(String title, String body, String? imageUrl, Map<String, dynamic> data) async {
    try {
      String? bigPicturePath;
      String? largeIconPath;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        bigPicturePath = await _downloadAndSaveFile(imageUrl, 'notification_img');
        largeIconPath = await _getCircularImage(imageUrl);
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mobiking_high_importance_channel',
        'MobiKing Notifications',
        channelDescription: 'Shop updates and deals',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        styleInformation: bigPicturePath != null ? BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath)) : null,
        largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
        tag: 'mobiking_notify',
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        0,
        title,
        body,
        details,
        payload: imageUrl,
      );
    } catch (e) {
      _log('Local Notification Error: $e');
    }
  }

  Future<String?> _getCircularImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final originalImage = img.decodeImage(response.bodyBytes);
      if (originalImage == null) return null;

      final size = originalImage.width < originalImage.height ? originalImage.width : originalImage.height;
      final squaredImage = img.copyCrop(originalImage, x: (originalImage.width - size) ~/ 2, y: (originalImage.height - size) ~/ 2, width: size, height: size);

      final circularImage = img.Image(width: size, height: size, numChannels: 4);
      final center = size / 2;
      final radius = size / 2;

      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          final distance = ((x - center.toDouble()) * (x - center.toDouble()) +
              (y - center.toDouble()) * (y - center.toDouble()));
          if (distance <= radius * radius) {
            final pixel = squaredImage.getPixel(x, y);
            circularImage.setPixel(x, y, pixel);
          } else {
            circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/circular_notification_icon.png';
      final File file = File(filePath);
      await file.writeAsBytes(img.encodePng(circularImage));
      return filePath;
    } catch (e) {
      _log('Circular Crop Error: $e');
      return null;
    }
  }

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
          title: title,
          body: body,
          imageUrl: imageUrl,
          onTap: () {
            entry.remove();
            _handleNotificationTap(data);
          },
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
    try {
      await _firebaseMessaging.subscribeToTopic('allUsers');
    } catch (e) {}
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

  const _ManualNotificationWidget({
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
    required this.onDismiss
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          onVerticalDragEnd: (_) => onDismiss(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B), // zinc-900 card background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A), width: 1), // zinc-800 border
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16
                              )
                          ),
                          const SizedBox(height: 4),
                          Text(
                              body,
                              style: const TextStyle(
                                  color: Color(0xFFD4D4D8), // zinc-300 secondary text
                                  fontSize: 13
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis
                          ),
                        ],
                      ),
                    ),
                    if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.indigo, width: 2), // Indigo accent
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFF27272A)),
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFA1A1AA), size: 20), // zinc-400
                        onPressed: onDismiss,
                        padding: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints()
                    ),
                  ],
                ),
                if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 140, color: const Color(0xFF27272A)),
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