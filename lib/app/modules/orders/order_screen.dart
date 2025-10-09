import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/query_getx_controller.dart';
import '../../data/order_model.dart';
import '../../themes/app_theme.dart';

import '../home/home_screen.dart' hide SizedBox;
import '../profile/query/Query_Detail_Screen.dart';
import 'package:mobiking/app/modules/orders/add_review_screen.dart';
import 'shipping_details_screen.dart';
import 'package:mobiking/app/modules/profile/query/Raise_query.dart';

import 'invoice_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final QueryGetXController queryController = Get.find<QueryGetXController>();
  final ScrollController _scrollController = ScrollController();
  final OrderController controller = Get.find<OrderController>();

  Timer? _pollingTimer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    controller.fetchOrderHistory();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isScrolling && mounted) {
        controller.fetchOrderHistory(isPoll: true);
      }
    });
  }

  void _pausePolling() => _isScrolling = true;
  void _resumePolling() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _isScrolling = false;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.lightGreyBackground,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          GetX<OrderController>(
            builder: (_) {
              if (controller.orderHistory.isNotEmpty && !controller.isLoadingOrderHistory.value) {
                return IconButton(
                  onPressed: () => controller.fetchOrderHistory(),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Orders',
                );
              }
              return const SizedBox(width: 8);
            },
          ),
        ],
      ),
      body: GetX<OrderController>(
        builder: (_) {
          if (controller.isLoadingOrderHistory.value && controller.orderHistory.isEmpty) {
            return _buildInitialLoadingView(textTheme);
          } else if (controller.orderHistoryErrorMessage.isNotEmpty && controller.orderHistory.isEmpty) {
            return _buildErrorView(textTheme);
          } else if (controller.orderHistory.isEmpty && !controller.isLoadingOrderHistory.value) {
            return _buildEmptyView(textTheme);
          } else {
            return _buildOrdersList(textTheme);
          }
        },
      ),
    );
  }

  Widget _buildInitialLoadingView(TextTheme textTheme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your orders...',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we fetch your order history',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorView(TextTheme textTheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Orders',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'re having trouble connecting to our servers. Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (controller.orderHistoryErrorMessage.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutralBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.orderHistoryErrorMessage.value,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(
                      'Go Back',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      side: BorderSide(color: AppColors.textMedium.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.fetchOrderHistory(),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                    label: Text(
                      'Try Again',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyView(TextTheme textTheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.primaryPurple.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Orders Yet!',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't placed any orders yet.\nStart exploring our products and make your first purchase!",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.offAll(() => HomeScreen()),
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.white),
                label: Text(
                  'Start Shopping',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => controller.fetchOrderHistory(),
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.textMedium,
              ),
              label: Text(
                'Refresh',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildOrdersList(TextTheme textTheme) {
    return Column(
      children: [
        // Show connection status banner if there's an error but we have cached data
        if (controller.orderHistoryErrorMessage.isNotEmpty && controller.orderHistory.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.accentOrange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 20,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing cached orders. Pull to refresh for latest updates.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.fetchOrderHistory(),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.accentOrange,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        // Main orders list
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo is ScrollStartNotification) _pausePolling();
              else if (scrollInfo is ScrollEndNotification) _resumePolling();
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () => controller.fetchOrderHistory(),
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.white,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.orderHistory.length + (controller.isLoadingOrderHistory.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end when refreshing
                  if (index == controller.orderHistory.length) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryPurple,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Updating orders...',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final order = controller.orderHistory[index];
                  return _OrderCard(
                    order: order,
                    controller: controller,
                    queryController: queryController,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// -- ORDER CARD ---
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderController controller;
  final QueryGetXController queryController;

  const _OrderCard({
    super.key,
    required this.order,
    required this.controller,
    required this.queryController,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Typical status logic...
    Color statusBadgeColor;
    Color statusTextColor;
    String orderMainStatusText = order.status.capitalizeFirst ?? 'Unknown';

    switch (order.status.toLowerCase()) {
      case 'new':
      case 'accepted':
        statusBadgeColor = AppColors.danger.withOpacity(0.15);
        statusTextColor = AppColors.danger;
        break;
      case 'shipped':
      case 'delivered':
        statusBadgeColor = AppColors.success.withOpacity(0.15);
        statusTextColor = AppColors.success;
        break;
      case 'cancelled':
      case 'rejected':
      case 'returned':
        statusBadgeColor = AppColors.textLight.withOpacity(0.1);
        statusTextColor = AppColors.textLight;
        break;
      case 'hold':
        statusBadgeColor = AppColors.accentOrange.withOpacity(0.15);
        statusTextColor = AppColors.accentOrange;
        break;
      default:
        statusBadgeColor = AppColors.textLight.withOpacity(0.1);
        statusTextColor = AppColors.textLight;
    }

    String orderDate = 'N/A';
    if (order.createdAt != null) {
      orderDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal());
    }

    // Logic for Query Button: delivered & has order.id
    bool canRaiseQuery = (order.status.toLowerCase() == 'delivered' && order.id != null);

    // Main rendered UI:
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: ID + STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('Order ID: #${order.orderId}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderMainStatusText,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Placed: $orderDate', style: textTheme.labelSmall?.copyWith(color: AppColors.textMedium)),
            const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

            // --- PRODUCT LIST ---
            ...order.items.map((item) {
              final String? imageUrl = item.productDetails?.images?.isNotEmpty == true
                  ? item.productDetails!.images!.first
                  : null;
              final String productName = item.productDetails?.fullName ?? 'N/A';
              final String variantText =
              (item.variantName != null && item.variantName!.isNotEmpty && item.variantName != 'Default')
                  ? item.variantName! : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, height: 60, width: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 60, width: 60, color: AppColors.neutralBackground,
                          child: const Icon(Icons.broken_image_rounded, size: 30, color: AppColors.textLight),
                        ),
                      )
                          : Container(
                        height: 60, width: 60, color: AppColors.neutralBackground,
                        child: const Icon(Icons.image_not_supported_rounded, size: 30, color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          if (variantText.isNotEmpty)
                            Text(variantText,
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text('Qty: ${item.quantity}',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

            // --- SUMMARY ---
            buildSummaryRow(context, 'Subtotal', '₹${order.subtotal?.toStringAsFixed(0) ?? '0'}'),
            buildSummaryRow(context, 'Delivery Charge', '₹${order.deliveryCharge.toStringAsFixed(0)}'),
            buildSummaryRow(context, 'GST', '₹${order.gst ?? '0'}'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total',
                    style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.textDark
                    ),
                  ),
                  Text('₹${order.orderAmount.toStringAsFixed(0)}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SHIPPING/DELIVERY ---
            Text('Shipping & Delivery Details',
                style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            buildDetailRow(context, 'Shipping Status', order.shippingStatus.capitalizeFirst ?? 'N/A'),
            if (order.courierName != null && order.courierName!.isNotEmpty)
              buildDetailRow(context, 'Courier', order.courierName!),
            if (order.awbCode != null && order.awbCode!.isNotEmpty)
              buildDetailRow(context, 'AWB Code', order.awbCode!),
            if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty)
              buildDetailRow(
                context,
                'Expected Delivery',
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.tryParse(order.expectedDeliveryDate!) ?? DateTime.now(),
                ),
              ),
            if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty)
              buildDetailRow(
                context,
                'Delivered On',
                DateFormat('dd MMM yyyy, hh:mm a').format(
                  DateTime.tryParse(order.deliveredAt!) ?? DateTime.now(),
                ),
              ),
            buildDetailRow(context, 'Payment Method', order.method.capitalizeFirst ?? 'N/A'),
            if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
              buildDetailRow(context, 'Razorpay Payment ID', order.razorpayPaymentId!),
            const SizedBox(height: 16),
            // --- TRACK SHIPMENT AND PAYMENT TAG ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.scans?.isNotEmpty == true)
                  OutlinedButton(
                    onPressed: () {
                      Get.to(() => ShippingDetailsScreen(order: order));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.info),
                      foregroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Track Shipment',
                      style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info),
                    ),
                  ),
                if (order.scans?.isNotEmpty == true) const SizedBox(width: 12),
                if (order.status.toLowerCase() == 'delivered')
                  OutlinedButton(
                    onPressed: () {
                      Get.to(() => InvoiceScreen(order: order));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.success),
                      foregroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Download Invoice',
                      style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ),
                if (order.status == "Accepted")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neutralBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Paid via ${order.method.capitalizeFirst ?? 'N/A'}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- ACTION BUTTONS: QUERY, CANCEL, RETURN ---
            Builder(
                builder: (innerContext) {
                  bool showAnyActionButton = controller.showCancelButton(order) || controller.showReturnButton(order) || controller.showReviewButton(order);
                  final activeRequests = order.requests?.where((req) {
                    final String status = req.status.toLowerCase();
                    return status != 'rejected' && status != 'resolved';
                  }).toList() ?? [];

                  bool hasActiveOrResolvedQuery = order.requests?.any((req) =>
                  req.type.toLowerCase() == 'query' &&
                      (req.status.toLowerCase() != 'rejected' && req.status.toLowerCase() != 'cancelled')
                  ) ?? false;

                  if (!showAnyActionButton &&
                      activeRequests.isEmpty &&
                      !canRaiseQuery &&
                      !hasActiveOrResolvedQuery) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),
                      if (activeRequests.isNotEmpty) ...[
                        Text(
                          'Active Requests:',
                          style: Theme.of(innerContext).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...activeRequests.map((req) {
                          final String type = req.type.capitalizeFirst!;
                          final String status = req.status.capitalizeFirst!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '$type Request: $status',
                              style: Theme.of(innerContext).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMedium,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                      ],
                      if (activeRequests.isNotEmpty && (showAnyActionButton || canRaiseQuery || hasActiveOrResolvedQuery))
                        const Divider(height: 24, thickness: 1, color: AppColors.neutralBackground),

                      if (order.id != null)
                        Obx(() {
                          final String? orderId = order.id;
                          if (orderId == null) return const SizedBox.shrink();

                          final bool hasQueryForThisOrder = queryController.myQueries.any(
                                  (query) => query.orderId != null && query.orderId == orderId
                          );

                          if (hasQueryForThisOrder) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(() => QueryDetailScreen(order: order));
                                  },
                                  icon: const Icon(Icons.info_outline, size: 20, color: AppColors.white),
                                  label: Text(
                                    'View Query',
                                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            );
                          } else if (canRaiseQuery) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.dialog(RaiseQueryDialog(orderId: order.id!));
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.white),
                                  label: Text(
                                    'Raise Query',
                                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkPurple,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),

                      if (controller.showCancelButton(order))
                        buildActionButton(
                          innerContext,
                          label: 'Cancel Order',
                          icon: Icons.cancel_outlined,
                          color: AppColors.danger,
                          onPressed: () => controller.sendOrderRequest(order.id, 'Cancel'),
                          isLoadingObservable: controller.isLoading,
                        ),
                      if (controller.showReturnButton(order))
                        buildActionButton(
                          innerContext,
                          label: 'Request Return',
                          icon: Icons.keyboard_return_outlined,
                          color: AppColors.info,
                          onPressed: () => controller.sendOrderRequest(order.id, 'Return'),
                          isLoadingObservable: controller.isLoading,
                        ),
                      if (controller.showReviewButton(order))
                        buildActionButton(
                          innerContext,
                          label: 'Add Review',
                          icon: Icons.star_outline,
                          color: AppColors.success,
                          onPressed: () {
                            Get.to(() => AddReviewScreen(order: order));
                          },
                          isLoadingObservable: controller.isLoading,
                        ),
                    ],
                  );
                }
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSummaryRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium)),
          Text(value, style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          )),
        ],
      ),
    );
  }

  static Widget buildDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
        required RxBool isLoadingObservable,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: Obx(() {
          final bool isLoading = isLoadingObservable.value;
          return ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
                : Icon(icon, size: 20, color: AppColors.white),
            label: Text(
              isLoading ? 'Processing...' : label,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: color.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          );
        }),
      ),
    );
  }
}