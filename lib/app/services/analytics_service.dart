import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Log user login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Log add to cart
  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String itemCategory,
    required int quantity,
    required double price,
  }) async {
    await _analytics.logAddToCart(
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
          quantity: quantity,
          price: price,
        ),
      ],
    );
  }

  // Log purchase
  Future<void> logPurchase({
    required double amount,
    required String transactionId,
    required List<AnalyticsEventItem> items,
  }) async {
    await _analytics.logPurchase(
      value: amount,
      currency: 'INR',
      transactionId: transactionId,
      items: items,
    );
  }

  // Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
