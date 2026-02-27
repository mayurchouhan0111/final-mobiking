import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome and DeviceOrientation
import 'package:mobiking/app/controllers/user_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add Hive import

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import 'package:mobiking/app/services/firebase_messaging_service.dart'; // Your FCM Service
import 'package:mobiking/app/services/analytics_service.dart';

// Hive adapters imports - Add these imports for your models
import 'package:mobiking/app/data/sub_category_model.dart';

import 'package:mobiking/app/data/product_model.dart';

import 'package:mobiking/app/data/category_model.dart';

import 'package:mobiking/app/modules/splash_screen.dart';

// Correct import paths for new screens/controllers/services
// Ensure these paths are correct in your project structure
import 'package:mobiking/app/controllers/BottomNavController.dart';
import 'package:mobiking/app/controllers/address_controller.dart';
import 'package:mobiking/app/controllers/cart_controller.dart';
import 'package:mobiking/app/controllers/category_controller.dart';
import 'package:mobiking/app/controllers/order_controller.dart';
import 'package:mobiking/app/controllers/query_getx_controller.dart';
import 'package:mobiking/app/controllers/sub_category_controller.dart';
import 'package:mobiking/app/controllers/wishlist_controller.dart';
import 'package:mobiking/app/controllers/login_controller.dart';
import 'package:mobiking/app/services/AddressService.dart';
import 'package:mobiking/app/services/login_service.dart';
import 'package:mobiking/app/services/user_service.dart';
import 'package:mobiking/app/services/order_service.dart';
import 'package:mobiking/app/services/query_service.dart';
import 'package:mobiking/app/controllers/home_controller.dart';
import 'package:mobiking/app/controllers/system_ui_controller.dart';
import 'package:mobiking/app/controllers/tab_controller_getx.dart';
import 'package:mobiking/app/modules/login/login_screen.dart'; // Assuming PhoneAuthScreen is here
import 'package:mobiking/app/services/Sound_Service.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:mobiking/app/services/connectivity_service.dart';
import 'package:mobiking/app/controllers/connectivity_controller.dart';
import 'package:mobiking/app/modules/no_network/no_network_screen.dart';

// ✅ ADD COUPON IMPORTS
import 'app/controllers/coupon_controller.dart';
import 'app/services/category_service.dart';
import 'app/services/coupon_service.dart';

import 'app/controllers/fcm_controller.dart';
import 'app/data/ParentCategory.dart';
import 'app/data/key_information.dart';
import 'app/data/selling_price.dart';
import 'package:mobiking/app/modules/bottombar/Bottom_bar.dart';
import 'firebase_options.dart';

// FCM Background Message Handler - MUST be a top-level function
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

// This handles messages when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessagehandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("🔥 BACKGROUND MESSAGE RECEIVED! ID: ${message.messageId}");

  final String title =
      message.notification?.title ?? message.data['title'] ?? "MobiKing";
  final String body =
      message.notification?.body ??
      message.data['body'] ??
      "New deals available!";
  final String? imageUrl =
      message.notification?.android?.imageUrl ??
      message.data['image'] ??
      message.data['imageUrl'] ??
      message.data['bigPicture'];

  // Manual local notification to force the image/logo
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize for background isolate
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  await localNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  String? bigFilePath;
  String? circularPath;

  if (imageUrl != null) {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      bigFilePath = '${directory.path}/bg_notification_img';
      circularPath = '${directory.path}/bg_circular_notification_icon.png';

      final http.Response response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // 1. Save Big Picture
      await File(bigFilePath).writeAsBytes(bytes);

      // 2. Generate Circular Icon
      final originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        final size =
            originalImage.width < originalImage.height
                ? originalImage.width
                : originalImage.height;
        final squaredImage = img.copyCrop(
          originalImage,
          x: (originalImage.width - size) ~/ 2,
          y: (originalImage.height - size) ~/ 2,
          width: size,
          height: size,
        );
        final circularImage =
            img.Image(width: size, height: size, numChannels: 4);
        final center = size / 2.0;
        final radius = size / 2.0;
        for (int y = 0; y < size; y++) {
          for (int x = 0; x < size; x++) {
            final distance =
                ((x - center) * (x - center) + (y - center) * (y - center));
            if (distance <= radius * radius) {
              final pixel = squaredImage.getPixel(x, y);
              circularImage.setPixel(x, y, pixel);
            } else {
              circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
            }
          }
        }
        await File(circularPath).writeAsBytes(img.encodePng(circularImage));
      } else {
        circularPath = null;
      }
    } catch (e) {
      print("🔥 BACKGROUND IMAGE ERROR: $e");
    }
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'mobiking_high_importance_channel',
    'MobiKing Notifications',
    channelDescription: 'Shop updates and deals',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: bigFilePath != null
        ? BigPictureStyleInformation(FilePathAndroidBitmap(bigFilePath))
        : null,
    largeIcon: circularPath != null
        ? FilePathAndroidBitmap(circularPath)
        : const DrawableResourceAndroidBitmap('ic_notification'),
    tag: 'mobiking_notify',
  );

  await localNotifications.show(
    0,
    title,
    body,
    NotificationDetails(android: androidDetails),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========== ANDROID 15 EDGE-TO-EDGE COMPATIBILITY ==========
  // Step 1: Enable Edge-to-Edge Display
  // This makes the system bars transparent, allowing the app to draw behind them.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.dark, // For dark icons on a light background
      systemNavigationBarIconBrightness:
          Brightness.dark, // For dark icons on a light background
    ),
  );

  // Step 2: Ensure the UI mode is set to edge-to-edge
  // This is the modern way to handle system UI visibility.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // =========================================================

  // Set preferred orientations to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // --- Initialize Storage Systems ---
  await GetStorage.init(); // Initialize GetStorage for local storage

  // Initialize Hive for complex data caching
  await _initializeHive();

  // --- Firebase Initialization ---
  // This must happen before you use any Firebase services like FCM.
  // If you generated firebase_options.dart using FlutterFire CLI,
  // uncomment the options line below and ensure you import 'firebase_options.dart'.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Core Services and Dependencies ---
  final dioInstance = dio.Dio(); // Single Dio instance
  final getStorageBox = GetStorage(); // Single GetStorage instance

  // Put your FirebaseMessagingService into GetX dependency injection
  // Initialize it immediately as it sets up listeners for FCM messages.
  Get.put(FirebaseMessagingService());

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessagehandler);

  // ✅ SERVICES: Put services into GetX dependency injection (ORDER MATTERS)
  Get.put(UserService(dioInstance)); // Put UserService first
  Get.put(LoginService(dioInstance, getStorageBox, Get.find<UserService>()));
  // await Get.find<LoginService>().refreshTokenOnAppStart(); // Removed as refresh token logic is no longer used
  Get.put(OrderService());
  Get.put(AddressService(dioInstance, getStorageBox));
  Get.put(ConnectivityService());
  Get.put(SoundService());
  Get.put(QueryService());
  Get.put(AnalyticsService());

  // ✅ ADD COUPON SERVICE: Initialize CouponService with Dio and GetStorage
  Get.put(CouponService(dioInstance, getStorageBox));

  // ✅ CONTROLLERS: Put controllers into GetX dependency injection (ORDER MATTERS)
  Get.put(CategoryController());
  Get.put(ConnectivityController());
  Get.put(FcmController());
  Get.put(AddressController());
  Get.put(UserController());
  Get.put(ProductController());
  Get.put(CartController());
  Get.put(HomeController());

  // ✅ ADD COUPON CONTROLLER: Initialize CouponController (depends on CouponService)
  Get.put(CouponController());

  Get.put(SubCategoryController());
  Get.put(WishlistController());
  Get.put(LoginController());
  Get.put(TabControllerGetX());
  Get.put(SystemUIController());
  Get.put(QueryGetXController());

  // OrderController (depends on OrderService, CartController, AddressController)
  Get.put(OrderController());
  Get.put(BottomNavController());

  runApp(const MyApp());
}

/// Initialize Hive and register all model adapters
Future<void> _initializeHive() async {
  try {
    // Initialize Hive
    await Hive.initFlutter();

    print('[Hive] Initializing Hive...');

    // Register all adapters with their unique typeIds
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubCategoryAdapter()); // typeId: 0
      print('[Hive] Registered SubCategoryAdapter');
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ParentCategoryAdapter()); // typeId: 1
      print('[Hive] Registered ParentCategoryAdapter');
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProductModelAdapter()); // typeId: 2
      print('[Hive] Registered ProductModelAdapter');
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(KeyInformationAdapter()); // typeId: 3
      print('[Hive] Registered KeyInformationAdapter');
    }

    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SellingPriceAdapter()); // typeId: 4
      print('[Hive] Registered SellingPriceAdapter');
    }

    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CategoryModelAdapter()); // typeId: 5
      print('[Hive] Registered CategoryModelAdapter');
    }

    print('[Hive] All adapters registered successfully');

    // Pre-open frequently used boxes for better performance (optional)
    await _preOpenBoxes();
  } catch (e) {
    print('[Hive] Error initializing Hive: $e');
    // You might want to handle this error appropriately
    // For now, we'll continue without Hive functionality
  }
}

/// Pre-open frequently used Hive boxes for better performance
Future<void> _preOpenBoxes() async {
  try {
    // Open metadata box for cache timestamps
    await Hive.openBox<String>('metadata');
    print('[Hive] Opened metadata box');

    // You can pre-open other boxes here if needed
    await Hive.openBox<SubCategory>('subcategories');
    print('[Hive] Opened subcategories box');
    await Hive.openBox<CategoryModel>('categories');
    print('[Hive] Opened categories box');
    await Hive.openBox<Map>('category_details');
    print('[Hive] Opened category_details box');
  } catch (e) {
    print('[Hive] Error pre-opening boxes: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the ConnectivityController instance
    final ConnectivityController connectivityController =
        Get.find<ConnectivityController>();
    final LoginController loginController = Get.find<LoginController>();

    // Define your desired global padding/margin
    const EdgeInsets globalPadding = EdgeInsets.symmetric(
      vertical: 0,
    ); // Changed to 0 as padding usually applies inside the widget structure, not to GetMaterialApp content directly. Adjust if needed.

    return GetMaterialApp(
      title: 'Mobiking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      // IMPORTANT: Wrap your home screen's Scaffold with a SafeArea widget
      // to avoid UI overlapping with system bars (status bar, navigation bar).
      // Example:
      // home: Scaffold(
      //   body: SafeArea(
      //     child: SplashScreen(),
      //   ),
      // ),
      // Since SplashScreen is your home, you should modify the SplashScreen file.
      home: SplashScreen(),

      // If you decide to use GetX routing (recommended), remove 'home:' and use 'initialRoute' and 'getPages'.
      // For example:
      // initialRoute: AppRoutes.LOGIN, // Assuming you have an AppRoutes class
      // getPages: AppPages.routes, // Assuming you have an AppPages class
    );
  }
}
