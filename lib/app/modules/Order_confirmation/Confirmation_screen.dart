// lib/screens/order_confirmation_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:get_storage/get_storage.dart';

// Import your updated theme
import '../../themes/app_theme.dart'; // Contains AppColors & AppTheme

// Assuming these paths are correct
import '../../data/order_model.dart';
import '../bottombar/Bottom_bar.dart';
import '../../services/order_service.dart';
import '../../controllers/cart_controller.dart';


class OrderConfirmationScreen extends StatefulWidget {
  final String? orderId;
  final Map<String, dynamic>? orderData;

  const OrderConfirmationScreen({
    Key? key,
    this.orderId,
    this.orderData,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final OrderService _orderService = Get.find<OrderService>();
  late final CartController _cartController = Get.find<CartController>();

  late AnimationController _lottieController;

  final RxBool _showLottie = true.obs;
  final RxBool _isLottiePlayedOnce = false.obs;

  final Rx<OrderModel?> _confirmedOrder = Rx<OrderModel?>(null);
  final RxBool _isLoadingOrderDetails = true.obs;
  final RxString _errorMessage = ''.obs;

  final GetStorage _box = GetStorage();

  @override
  void initState() {
    super.initState();
    debugPrint('OrderConfirmationScreen initState called');
    _lottieController = AnimationController(vsync: this);
    _fetchOrderDetailsAndAnimate();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _showLottie.close();
    _isLottiePlayedOnce.close();
    _confirmedOrder.close();
    _isLoadingOrderDetails.close();
    _errorMessage.close();
    debugPrint('OrderConfirmationScreen dispose called');
    super.dispose();
  }

  void _navigateToMainScreen() {
    debugPrint('Navigating to main screen and clearing cart');
    _cartController.clearCartData();
    Get.offAll(() => MainContainerScreen());
  }

  String? _getOrderId() {
    debugPrint('=== TRYING TO RETRIEVE ORDER ID ===');

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      debugPrint('✅ Found order ID from widget parameter: ${widget.orderId}');
      return widget.orderId;
    }

    final List<String> possibleKeys = [
      'recent_order_id',
      'last_order_id',
      'latest_order_id',
      'lastOrderId',
    ];

    String? orderId;
    for (String key in possibleKeys) {
      orderId = _box.read(key)?.toString();
      debugPrint('Checking storage key "$key": $orderId');
      if (orderId != null && orderId.isNotEmpty) {
        debugPrint('✅ Found order ID in storage key "$key": $orderId');
        return orderId;
      }
    }

    // Fallback: Check inside stored order data objects
    final orderData = _getOrderData(); // Uses the same logic as before to find any order data map
    if (orderData != null) {
      orderId = orderData['orderId']?.toString() ??
          orderData['_id']?.toString() ??
          orderData['id']?.toString();

      if (orderId != null && orderId.isNotEmpty) {
        debugPrint('✅ Found order ID in stored order data object: $orderId');
        return orderId;
      }
    }

    debugPrint('❌ No order ID found in any source');
    return null;
  }

  // This helper is kept in case the API fails, we can still try to parse local data as a last resort.
  Map<String, dynamic>? _getOrderData() {
    if (widget.orderData != null) return widget.orderData!;

    final List<String> orderDataKeys = [
      'current_order_for_confirmation', 'last_placed_order',
      'order_confirmation_data', 'order_success_data',
    ];

    for (String key in orderDataKeys) {
      final orderData = _box.read(key);
      if (orderData != null && orderData is Map<String, dynamic>) {
        return orderData;
      }
    }
    return null;
  }

  Future<void> _fetchOrderDetailsAndAnimate() async {
    _showLottie.value = true;
    _isLottiePlayedOnce.value = false;
    _isLoadingOrderDetails.value = true;
    _errorMessage.value = '';
    _confirmedOrder.value = null;

    if (_lottieController.duration != null && !_lottieController.isAnimating) {
      _lottieController.forward(from: 0.0);
    }

    final Completer<void> dataFetchCompleter = Completer<void>();

    // ✅ --- MODIFICATION START ---
    // We no longer check for local data first. We go straight to fetching
    // the full order details from the server for consistency.
    _tryFetchWithOrderId(dataFetchCompleter);
    // ✅ --- MODIFICATION END ---

    try {
      await Future.wait([
        dataFetchCompleter.future,
        Future.delayed(const Duration(seconds: 3)), // Ensure animation plays for a minimum time
      ]);
    } finally {
      _isLoadingOrderDetails.value = false;
      if (mounted && _lottieController.isAnimating) {
        _lottieController.forward().then((_) {
          if (mounted) _showLottie.value = false;
        });
      } else {
        _showLottie.value = false;
      }
    }
  }

  void _tryFetchWithOrderId(Completer<void> completer) {
    final String? orderId = _getOrderId();
    debugPrint('[_tryFetchWithOrderId] Retrieved order ID: $orderId');

    if (orderId == null || orderId.isEmpty) {
      _errorMessage.value = 'No recent order ID found. Please check your order history.';
      completer.complete();
      return;
    }

    (() async {
      try {
        debugPrint('[_tryFetchWithOrderId] Fetching order from API with ID: $orderId');
        final fetchedOrder = await _orderService.getOrderDetails(orderId: orderId);
        _confirmedOrder.value = fetchedOrder;
        _errorMessage.value = '';
        debugPrint('[_tryFetchWithOrderId] Successfully fetched complete order from API.');
      } catch (e) {
        debugPrint('[_tryFetchWithOrderId] API fetch failed: $e');

        // Fallback to local data only if API fails
        final fallbackOrderData = _getOrderData();
        if (fallbackOrderData != null) {
          try {
            final OrderModel parsedOrder = OrderModel.fromJson(fallbackOrderData);
            _confirmedOrder.value = parsedOrder;
            _errorMessage.value = 'Could not fetch latest details. Displaying saved info.'; // Inform user
            debugPrint('[_tryFetchWithOrderId] Fallback: Successfully used stored order data.');
          } catch (parseError) {
            _errorMessage.value = 'Unable to load any order details. Please try again.';
            debugPrint('[_tryFetchWithOrderId] Both API and stored data parsing failed: $parseError');
          }
        } else {
          _errorMessage.value = 'Unable to load order details. Please check your connection.';
          debugPrint('[_tryFetchWithOrderId] No fallback data available.');
        }
      } finally {
        completer.complete();
      }
    })();
  }



  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      body: Obx(() {
        if (_showLottie.value || _isLoadingOrderDetails.value) {
          return _buildLottieAnimation(context, textTheme);
        } else if (_errorMessage.isNotEmpty && _confirmedOrder.value == null) {
          return _buildError(context, textTheme);
        } else if (_confirmedOrder.value == null) {
          return _buildNoOrders(context, textTheme);
        } else {
          return _buildOrderDetails(context, textTheme, _confirmedOrder.value!);
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        if (_showLottie.value ||
            _isLoadingOrderDetails.value ||
            _confirmedOrder.value == null ||
            (_errorMessage.isNotEmpty && _confirmedOrder.value == null)) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(25),
            shadowColor: AppColors.primaryPurple.withOpacity(0.4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurple.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _navigateToMainScreen,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                ),
                label: Text(
                  "Continue Shopping",
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  minimumSize: const Size.fromHeight(60),
                  elevation: 0,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLottieAnimation(BuildContext context, TextTheme textTheme) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/order.json',
              controller: _lottieController,
              onLoaded: (composition) {
                if (mounted) {
                  _lottieController.duration = composition.duration;
                  _lottieController.forward(from: 0.0);
                }
              },
              repeat: false,
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Obx(
                  () => Text(
                _isLoadingOrderDetails.value
                    ? 'Fetching your order details...'
                    : 'Confirming your order...',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (_isLoadingOrderDetails.value)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CircularProgressIndicator(color: AppColors.textDark, strokeWidth: 3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, TextTheme textTheme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF0)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, size: 60, color: AppColors.danger),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Oops! Something went wrong',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage.value,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.primaryPurple.withOpacity(0.8)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _lottieController.reset();
                          _fetchOrderDetailsAndAnimate();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'Try Again',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoOrders(BuildContext context, TextTheme textTheme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF0)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_basket_outlined, size: 70, color: AppColors.primaryPurple),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'No Recent Orders',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'It looks like you haven\'t placed any orders yet. Let\'s get you started with some amazing products!',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMedium,
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.primaryPurple.withOpacity(0.8)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToMainScreen,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                        ),
                        label: Text(
                          'Start Shopping',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, TextTheme textTheme, OrderModel order) {
    final orderTime = order.createdAt != null
        ? DateFormat('dd MMM, HH:mm').format(order.createdAt!.toLocal())
        : 'N/A';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF0)],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Premium Success Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.8),
                    const Color(0xFF2E7D4A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      // Success Icon with Animation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 50,
                            color: AppColors.success,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Order Confirmed!",
                        style: textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 36,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          "Order #${order.orderId ?? 'N/A'}",
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Placed at $orderTime",
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Delivery Address Section
                  _buildPremiumSection(
                    context,
                    textTheme,
                    'Delivery Address',
                    Icons.location_on,
                    _buildAddressCard(context, textTheme, order),
                  ),

                  const SizedBox(height: 20),

                  // Shipping Details Section
                  _buildPremiumSection(
                    context,
                    textTheme,
                    'Shipping Details',
                    Icons.local_shipping,
                    _buildShippingDetailsCard(context, textTheme, order),
                  ),

                  const SizedBox(height: 20),

                  // Order Items Section
                  _buildPremiumSection(
                    context,
                    textTheme,
                    'Order Items',
                    Icons.shopping_bag,
                    Column(
                      children: order.items.isNotEmpty
                          ? order.items.map((item) => _buildOrderItemCard(context, textTheme, item)).toList()
                          : [_buildEmptyItemsCard(context, textTheme)],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Summary Section
                  _buildPremiumSection(
                    context,
                    textTheme,
                    'Payment Summary',
                    Icons.receipt_long,
                    _buildOrderSummary(context, textTheme, order),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection(
      BuildContext context,
      TextTheme textTheme,
      String title,
      IconData icon,
      Widget child,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Removed gradient
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 20), // Smaller size, purple color
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, TextTheme textTheme, OrderModel order) {
    final String addressText = (order.address ?? 'Address not available for this order.');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Removed background color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_outline, color: AppColors.primaryPurple, size: 18), // Smaller size
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.name ?? 'N/A',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on, size: 20, color: AppColors.primaryPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        addressText,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Phone
            if (order.phoneNo != null && order.phoneNo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phone, size: 18, color: AppColors.primaryPurple),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    order.phoneNo!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetailsCard(BuildContext context, TextTheme textTheme, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumDetailRow(
              textTheme,
              Icons.local_shipping,
              'Shipping Status',
              order.shippingStatus ?? 'Processing',
              AppColors.primaryPurple,
            ),
            if (order.courierName != null && order.courierName!.isNotEmpty)
              _buildPremiumDetailRow(
                textTheme,
                Icons.business,
                'Courier Partner',
                order.courierName!,
                const Color(0xFF2196F3),
              ),
            if (order.awbCode != null && order.awbCode!.isNotEmpty)
              _buildPremiumDetailRow(
                textTheme,
                Icons.qr_code,
                'Tracking Number',
                order.awbCode!,
                const Color(0xFF4CAF50),
              ),
            if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty)
              _buildPremiumDetailRow(
                textTheme,
                Icons.schedule,
                'Expected Delivery',
                DateFormat('dd MMM yyyy').format(
                  DateTime.tryParse(order.expectedDeliveryDate!) ?? DateTime.now(),
                ),
                const Color(0xFFFF9800),
              ),
            if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
              _buildPremiumDetailRow(
                textTheme,
                Icons.check_circle,
                'Delivered On',
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.tryParse(order.deliveredAt!) ?? DateTime.now(),
                ),
                AppColors.success,
              ),
            _buildPremiumDetailRow(
              textTheme,
              Icons.payment,
              'Payment Method',
              order.method ?? 'N/A',
              const Color(0xFF9C27B0),
            ),
            if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
              _buildPremiumDetailRow(
                textTheme,
                Icons.receipt,
                'Payment ID',
                order.razorpayPaymentId!,
                const Color(0xFF607D8B),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDetailRow(
      TextTheme textTheme,
      IconData icon,
      String label,
      String value,
      Color iconColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent, // Removed background color
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor), // Smaller size, use iconColor
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, TextTheme textTheme, OrderItemModel item) {
    final String imageUrl = item.productDetails?.images?.isNotEmpty == true
        ? item.productDetails!.images!.first
        : 'https://via.placeholder.com/80/E8EAF0/757575?text=No+Image';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textLight,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productDetails?.name ?? item.productDetails?.fullName
                        ?? '',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.variantName.isNotEmpty && item.variantName != 'Default') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.variantName,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Qty: ${item.quantity}",
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1976D2),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(item.price),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Total Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(item.price * item.quantity),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Total',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsCard(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No items listed for this order.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, TextTheme textTheme, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumSummaryRow(textTheme, "Subtotal", order.subtotal ?? 0.0, Icons.shopping_bag),
            if ((order.discount ?? 0.0) > 0)
              _buildPremiumSummaryRow(textTheme, "Discount", -(order.discount ?? 0.0), Icons.local_offer, isDiscount: true),
            _buildPremiumSummaryRow(textTheme, "Delivery Fee", order.deliveryCharge, Icons.local_shipping),
            _buildPremiumSummaryRow(textTheme, "GST", double.tryParse(order.gst ?? '0.0') ?? 0.0, Icons.receipt),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE0E0E0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            _buildPremiumSummaryRow(textTheme, "Grand Total", order.orderAmount, Icons.payments, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSummaryRow(
      TextTheme textTheme,
      String title,
      double value,
      IconData icon, {
        bool isTotal = false,
        bool isDiscount = false,
      }) {
    final formattedValue = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2).format(value);

    Color iconColor = AppColors.textMedium;
    Color bgColor = const Color(0xFFF8F9FA);

    if (isTotal) {
      iconColor = AppColors.primaryPurple;
      bgColor = AppColors.primaryPurple.withOpacity(0.1);
    } else if (isDiscount) {
      iconColor = AppColors.danger;
      bgColor = AppColors.danger.withOpacity(0.1);
    }

    final titleStyle = textTheme.bodyMedium?.copyWith(
      fontSize: isTotal ? 14 : 12,
      fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
      color: isDiscount
          ? AppColors.danger
          : isTotal
          ? AppColors.textDark
          : AppColors.textMedium,
    );

    final valueStyle = textTheme.bodyMedium?.copyWith(
      fontSize: isTotal ? 16 : 13,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isDiscount
          ? AppColors.danger
          : isTotal
          ? AppColors.textDark
          : AppColors.textDark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Removed background color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isTotal ? 16 : 14, color: iconColor), // Smaller size
              ),
              const SizedBox(width: 12),
              Text(title, style: titleStyle),
            ],
          ),
          Text(formattedValue, style: valueStyle),
        ],
      ),
    );
  }
}