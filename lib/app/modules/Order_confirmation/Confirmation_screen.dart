// lib/screens/order_confirmation_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/AddressModel.dart';
import '../../themes/app_theme.dart';
import '../../data/order_model.dart';
import '../bottombar/Bottom_bar.dart';
import 'package:mobiking/app/controllers/product_controller.dart';
import '../../services/order_service.dart';
import '../../controllers/cart_controller.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String? orderId;
  final Map<String, dynamic>? orderData;
  final AddressModel? address;

  const OrderConfirmationScreen({
    Key? key,
    this.orderId,
    this.orderData,
    this.address,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final OrderService _orderService = Get.find<OrderService>();
  late final CartController _cartController = Get.find<CartController>();
  late AnimationController _lottieController;

  final RxBool _showLottie = true.obs;
  final Rx<OrderModel?> _confirmedOrder = Rx<OrderModel?>(null);
  final RxBool _isLoadingOrderDetails = true.obs;
  final RxString _errorMessage = ''.obs;

  final GetStorage _box = GetStorage();

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // Load fallback data immediately for instant display
    final fallbackData = _getOrderData();
    if (fallbackData != null) {
      try {
        _confirmedOrder.value = OrderModel.fromJson(fallbackData);
        debugPrint('✅ Initialized with fallback order data');
      } catch (e) {
        debugPrint('⚠️ Error parsing fallback order data: $e');
      }
    }

    _fetchOrderDetailsAndAnimate();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _showLottie.close();
    _confirmedOrder.close();
    _isLoadingOrderDetails.close();
    _errorMessage.close();
    super.dispose();
  }

  void _navigateToMainScreen() {
    _cartController.clearCartData();
    Get.find<ProductController>().refreshProducts();
    Get.offAll(() => MainContainerScreen());
  }

  String? _getOrderId() {
    // Try to get from confirmed order if we have it
    if (_confirmedOrder.value != null) {
      return _confirmedOrder.value!.id;
    }

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return widget.orderId;
    }
    final List<String> possibleKeys = [
      'recent_order_id',
      'last_order_id',
      'latest_order_id',
      'lastOrderId',
    ];
    for (String key in possibleKeys) {
      final orderId = _box.read(key)?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        return orderId;
      }
    }
    final orderData = _getOrderData();
    if (orderData != null) {
      final orderId =
          orderData['orderId']?.toString() ??
          orderData['_id']?.toString() ??
          orderData['id']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        return orderId;
      }
    }
    return null;
  }

  Map<String, dynamic>? _getOrderData() {
    if (widget.orderData != null) return widget.orderData!;
    final List<String> orderDataKeys = [
      'current_order_for_confirmation',
      'last_placed_order',
      'order_confirmation_data',
      'order_success_data',
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
    _isLoadingOrderDetails.value = true;
    _errorMessage.value = '';
    // Don't clear _confirmedOrder here to keep fallback data visible if available

    final Completer<void> dataFetchCompleter = Completer<void>();
    _tryFetchWithOrderId(dataFetchCompleter);

    try {
      await Future.wait([
        dataFetchCompleter.future,
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } finally {
      _isLoadingOrderDetails.value = false;
      if (mounted) {
        _showLottie.value = false;
      }
    }
  }

  void _tryFetchWithOrderId(Completer<void> completer) {
    final String? orderId = _getOrderId();
    if (orderId == null || orderId.isEmpty) {
      if (_confirmedOrder.value == null) {
        _errorMessage.value =
            'No recent order ID found. Please check your order history.';
      }
      completer.complete();
      return;
    }

    (() async {
      try {
        final fetchedOrder = await _orderService.getOrderDetails(
          orderId: orderId,
        );

        // Merge with existing fallback data if names are missing in API response
        if (_confirmedOrder.value != null &&
            _confirmedOrder.value!.items.isNotEmpty) {
          final fallbackOrder = _confirmedOrder.value!;
          bool needsMerge = false;

          for (var item in fetchedOrder.items) {
            if (item.productDetails == null ||
                (item.productDetails!.name.isEmpty &&
                    item.productDetails!.fullName.isEmpty)) {
              needsMerge = true;
              break;
            }
          }

          if (needsMerge) {
            debugPrint(
              '🔄 API response missing product names. Merging with fallback info...',
            );

            final List<OrderItemModel> patchedItems = fetchedOrder.items.map((
              item,
            ) {
              // If this item is missing details, try to find it in the fallback
              if (item.productDetails == null ||
                  (item.productDetails!.name.isEmpty &&
                      item.productDetails!.fullName.isEmpty)) {
                // Try to find a matching item in the fallback order
                // Match by variant name and product ID (if available) or price
                final matchingFallback = fallbackOrder.items.firstWhereOrNull((
                  fi,
                ) {
                  if (fi.variantName != item.variantName) return false;

                  // If we have IDs, use them
                  if (fi.productDetails?.id != null &&
                      item.productDetails?.id != null &&
                      fi.productDetails!.id.isNotEmpty &&
                      fi.productDetails!.id == item.productDetails!.id) {
                    return true;
                  }

                  // Fallback to price matching if IDs are unavailable or don't match
                  return (fi.price - item.price).abs() < 0.01;
                });

                if (matchingFallback != null &&
                    matchingFallback.productDetails != null) {
                  debugPrint(
                    '✅ Found fallback details for item: ${item.variantName}',
                  );
                  return OrderItemModel(
                    id: item.id.isNotEmpty ? item.id : matchingFallback.id,
                    productDetails: matchingFallback.productDetails,
                    variantName: item.variantName,
                    quantity: item.quantity,
                    price: item.price,
                  );
                }
              }
              return item;
            }).toList();

            // Create a patched version of the order
            final orderJson = fetchedOrder.toJson();
            orderJson['items'] = patchedItems.map((i) => i.toJson()).toList();

            _confirmedOrder.value = OrderModel.fromJson(orderJson);
            _errorMessage.value = '';
            completer.complete();
            return;
          }
        }

        _confirmedOrder.value = fetchedOrder;
        _errorMessage.value = '';
      } catch (e) {
        if (_confirmedOrder.value == null) {
          final fallbackOrderData = _getOrderData();
          if (fallbackOrderData != null) {
            try {
              final OrderModel parsedOrder = OrderModel.fromJson(
                fallbackOrderData,
              );
              _confirmedOrder.value = parsedOrder;
              _errorMessage.value =
                  'Could not fetch latest details. Displaying saved info.';
            } catch (parseError) {
              _errorMessage.value =
                  'Unable to load any order details. Please try again.';
            }
          } else {
            _errorMessage.value =
                'Unable to load order details. Please check your connection.';
          }
        }
      } finally {
        completer.complete();
      }
    })();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.white,
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
            _confirmedOrder.value == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: _navigateToMainScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size.fromHeight(60),
              elevation: 8,
              shadowColor: AppColors.primaryPurple.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  "Continue Shopping",
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
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
              'assets/animations/Done.json',
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
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: AppColors.danger,
            ),
            const SizedBox(height: 24),
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
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _lottieController.reset();
                _fetchOrderDetailsAndAnimate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: Text(
                'Try Again',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrders(BuildContext context, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 24),
            Text(
              'No Recent Orders',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'It looks like you haven\'t placed any orders yet. Let\'s get you started!',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textMedium,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToMainScreen,
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                'Start Shopping',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    TextTheme textTheme,
    OrderModel order,
  ) {
    final orderTime = order.createdAt?.toLocal() != null
        ? DateFormat('dd MMM, HH:mm').format(order.createdAt!.toLocal())
        : 'N/A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textTheme, order, orderTime),
          const SizedBox(height: 24),
          _buildSection(
            context,
            textTheme,
            'Delivery Address',
            Icons.location_on,
            _buildAddressCard(context, textTheme, order),
          ),
          _buildSection(
            context,
            textTheme,
            'Shipping Details',
            Icons.local_shipping,
            _buildShippingDetailsCard(context, textTheme, order),
          ),
          _buildSection(
            context,
            textTheme,
            'Order Items',
            Icons.shopping_bag,
            _buildOrderItemsList(context, textTheme, order),
          ),
          _buildSection(
            context,
            textTheme,
            'Payment Summary',
            Icons.receipt_long,
            _buildOrderSummary(context, textTheme, order),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, OrderModel order, String orderTime) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                "Order Confirmed!",
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Order #${order.orderId}",
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Placed at $orderTime",
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    TextTheme textTheme,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    TextTheme textTheme,
    OrderModel order,
  ) {
    String fullAddress = 'Address not available.';
    String recipientName = order.name ?? 'N/A';
    String phoneNumber = order.phoneNo ?? '';

    if (widget.address != null) {
      final List<String?> parts = [
        widget.address!.street,
        widget.address!.city,
        widget.address!.state,
        widget.address!.pinCode,
      ];
      fullAddress = parts
          .where((part) => part != null && part.isNotEmpty)
          .join(', ');
    } else if (order.address is Map) {
      // If the address is a Map, concatenate the parts into a single string.
      final Map<dynamic, dynamic> addressMap = order.address! as Map;
      final String street = addressMap['street']?.toString() ?? '';
      final String city = addressMap['city']?.toString() ?? '';
      final String state = addressMap['state']?.toString() ?? '';
      final String pinCode = addressMap['pinCode']?.toString() ?? '';

      // Join the available parts with commas and spaces.
      final List<String> parts = [
        street,
        city,
        state,
        pinCode,
      ].where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        fullAddress = parts.join(', ');
      }
    } else if (order.address is String && order.address!.isNotEmpty) {
      // If the address is already a non-empty string, use it directly.
      fullAddress = order.address! as String;
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            textTheme,
            Icons.person_outline,
            'Recipient',
            recipientName,
          ),
          _buildDetailRow(
            textTheme,
            Icons.location_on,
            'Delivery Address',
            fullAddress,
            color: AppColors.textDark,
          ),
          if (phoneNumber.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.phone,
              'Phone Number',
              phoneNumber,
            ),
        ],
      ),
    );
  }

  Widget _buildShippingDetailsCard(
    BuildContext context,
    TextTheme textTheme,
    OrderModel order,
  ) {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow(
            textTheme,
            Icons.local_shipping,
            'Shipping Status',
            order.shippingStatus,
            isBold: true,
          ),
          if (order.courierName != null && order.courierName!.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.business,
              'Courier Partner',
              order.courierName!,
            ),
          if (order.awbCode != null && order.awbCode!.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.qr_code,
              'Tracking Number',
              order.awbCode!,
            ),
          if (order.expectedDeliveryDate != null &&
              order.expectedDeliveryDate!.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.schedule,
              'Expected Delivery',
              DateFormat('dd MMM yyyy').format(
                DateTime.tryParse(order.expectedDeliveryDate!) ??
                    DateTime.now(),
              ),
            ),
          if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.check_circle,
              'Delivered On',
              DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.tryParse(order.deliveredAt!) ?? DateTime.now()),
            ),
          _buildDetailRow(
            textTheme,
            Icons.payment,
            'Payment Method',
            order.method,
          ),
          if (order.razorpayPaymentId != null &&
              order.razorpayPaymentId!.isNotEmpty)
            _buildDetailRow(
              textTheme,
              Icons.receipt,
              'Payment ID',
              order.razorpayPaymentId!,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList(
    BuildContext context,
    TextTheme textTheme,
    OrderModel order,
  ) {
    if (order.items.isEmpty) {
      return _buildEmptyItemsCard(context, textTheme);
    }
    return Column(
      children: order.items
          .map((item) => _buildOrderItemCard(context, textTheme, item))
          .toList(),
    );
  }

  Widget _buildOrderItemCard(
    BuildContext context,
    TextTheme textTheme,
    OrderItemModel item,
  ) {
    final String imageUrl =
        item.productDetails != null && item.productDetails!.images.isNotEmpty
        ? item.productDetails!.images.first
        : 'https://via.placeholder.com/80/E8EAF0/757575?text=No+Image';

    return _buildCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: AppColors.textLight,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final p = item.productDetails;
                    if (p == null) return 'Product';
                    if (p.fullName.isNotEmpty) return p.fullName;
                    if (p.name.isNotEmpty) return p.name;
                    return 'Product';
                  }(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName.isNotEmpty &&
                    item.variantName != 'Default')
                  Text(
                    item.variantName,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMedium,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Qty: ${item.quantity}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.simpleCurrency(
                  locale: 'en_IN',
                  decimalDigits: 2,
                ).format(item.price * item.quantity),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Subtotal',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsCard(BuildContext context, TextTheme textTheme) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
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
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    TextTheme textTheme,
    OrderModel order,
  ) {
    return _buildCard(
      child: Column(
        children: [
          _buildSummaryRow(textTheme, "Subtotal", order.subtotal ?? 0.0),
          if (order.discount != null && order.discount! > 0)
            _buildSummaryRow(
              textTheme,
              "Discount",
              -(order.discount!),
              isDiscount: true,
            ),
          _buildSummaryRow(textTheme, "Delivery Fee", order.deliveryCharge),
          _buildSummaryRow(
            textTheme,
            "GST",
            double.tryParse(order.gst ?? '0.0') ?? 0.0,
          ),
          Divider(color: AppColors.neutralBackground, height: 24),
          _buildSummaryRow(
            textTheme,
            "Grand Total",
            order.orderAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    TextTheme textTheme,
    String title,
    double value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final formattedValue = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    ).format(value);
    final titleStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isTotal ? AppColors.textDark : AppColors.textMedium,
    );
    final valueStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: isDiscount ? AppColors.danger : AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          Text(formattedValue, style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.neutralBackground, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(
    TextTheme textTheme,
    IconData icon,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color ?? AppColors.textDark,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
