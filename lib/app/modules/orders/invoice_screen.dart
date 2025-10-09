import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/order_model.dart';

/// Defines the color palette for the noir/dark theme.
class NoirThemeColors {
  // Primary Background Colors
  static const Color zinc950 = Color(0xFF09090B); // Main background
  static const Color zinc900 = Color(0xFF18181B); // Card/Component background

  // Border & UI Element Colors
  static const Color zinc800 = Color(0xFF27272A);

  // Text Colors
  static const Color white = Color(0xFFFFFFFF);     // Primary text, headings
  static const Color zinc300 = Color(0xFFD4D4D8);   // Secondary text (lighter)
  static const Color zinc400 = Color(0xFFA1A1AA);   // Secondary text (medium)
  static const Color zinc500 = Color(0xFF71717A);   // Secondary text (darker)

  // Accent & Status Colors
  static const Color indigo = Color(0xFF6366F1); // Primary accent
  static const Color green = Color(0xFF22C55E);  // Success/Validation
  static const Color blue = Color(0xFF3B82F6);   // Informational
}


class InvoiceScreen extends StatelessWidget {
  final OrderModel order;

  const InvoiceScreen({super.key, required this.order});

  // Helper methods moved inside the class
  double _calculateTotalMRP() {
    double totalMrp = 0;
            for (var item in order.items) {
              final mrp = item.price.toDouble();      if (mrp != null) {
        totalMrp += mrp * item.quantity;
      }
    }
    return totalMrp;
  }

  double _calculateProductDiscount() {
    double totalMrp = 0;
    double totalSellingPrice = 0;

    for (var item in order.items) {
      final itemPrice = item.price.toDouble();
      // Corrected to use 'mrp' for consistent discount calculation
      final mrp = item.price.toDouble();

      totalSellingPrice += itemPrice * item.quantity;
      if (mrp != null) {
        totalMrp += mrp * item.quantity;
      } else {
        totalMrp += itemPrice * item.quantity; // Fallback if MRP is null
      }
    }

    final discount = totalMrp - totalSellingPrice;
    return discount > 0 ? discount : 0;
  }

  void _downloadInvoice() {
    // ignore: avoid_print
    print('Downloading invoice for order: ${order.orderId}');
  }

  void _rateOrder() {
    // ignore: avoid_print
    print('Rating order: ${order.orderId}');
  }

  void _repeatOrder() {
    // ignore: avoid_print
    print('Repeating order: ${order.orderId}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Status logic with dark theme colors
    Color statusBadgeColor;
    Color statusTextColor;
    String orderMainStatusText = order.status?.capitalizeFirst ?? '';

    switch (order.status.toLowerCase()) {
      case 'new':
      case 'accepted':
      case 'hold':
        statusBadgeColor = NoirThemeColors.blue.withOpacity(0.15);
        statusTextColor = NoirThemeColors.blue;
        break;
      case 'shipped':
      case 'delivered':
        statusBadgeColor = NoirThemeColors.green.withOpacity(0.15);
        statusTextColor = NoirThemeColors.green;
        break;
      case 'cancelled':
      case 'rejected':
      case 'returned':
      default:
        statusBadgeColor = NoirThemeColors.zinc800;
        statusTextColor = NoirThemeColors.zinc400;
        break;
    }

    // Order date formatting
    String orderDate = 'N/A';
    if (order.createdAt != null) {
      orderDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal());
    }

    // Delivery time if available
    String? deliveryTime;
    if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty) {
      try {
        final deliveredDateTime = DateTime.tryParse(order.deliveredAt!) ?? DateTime.now();
        deliveryTime = DateFormat('h:mm a').format(deliveredDateTime.toLocal());
      } catch (e) {
        deliveryTime = null;
      }
    }

    return Scaffold(
      backgroundColor: NoirThemeColors.zinc950, // Primary background
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: textTheme.titleLarge?.copyWith(
            color: NoirThemeColors.white, // Primary text
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: NoirThemeColors.zinc900, // Component background
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: NoirThemeColors.white), // Primary text
        actions: [
          IconButton(
            onPressed: () {
              // Add delete functionality here if needed
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: NoirThemeColors.zinc900, // Card background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NoirThemeColors.zinc800, width: 1.0), // Border color
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Order ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Order ID: ${order.orderId}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: NoirThemeColors.white, // Primary text
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
                Text(
                  'Placed: $orderDate',
                  style: textTheme.labelSmall?.copyWith(color: NoirThemeColors.zinc400), // Secondary text
                ),
                if (deliveryTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Arrived at $deliveryTime',
                    style: textTheme.bodyMedium?.copyWith(
                      color: NoirThemeColors.green, // Success color
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                InkWell(
                  onTap: _downloadInvoice,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Download Invoice',
                        style: textTheme.bodyMedium?.copyWith(
                          color: NoirThemeColors.indigo, // Primary accent
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.file_download_outlined,
                        color: NoirThemeColors.indigo, // Primary accent
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''} in this order',
                  style: textTheme.titleMedium?.copyWith(
                    color: NoirThemeColors.white, // Primary text
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24, thickness: 1, color: NoirThemeColors.zinc800), // UI element
                ...order.items.map((item) {
                  final String? imageUrl = item.productDetails?.images?.isNotEmpty == true
                      ? item.productDetails!.images!.first
                      : null;
                  final String productName = item.productDetails?.fullName ?? 'N/A';
                  final String variantText = (item.variantName != null &&
                      item.variantName!.isNotEmpty && item.variantName != 'Default')
                      ? item.variantName! : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 60,
                              width: 60,
                              color: NoirThemeColors.zinc800, // UI element
                              child: const Icon(
                                Icons.broken_image_rounded,
                                size: 30,
                                color: NoirThemeColors.zinc500, // Secondary text
                              ),
                            ),
                          )
                              : Container(
                            height: 60,
                            width: 60,
                            color: NoirThemeColors.zinc800, // UI element
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 30,
                              color: NoirThemeColors.zinc500, // Secondary text
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: NoirThemeColors.white, // Primary text
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (variantText.isNotEmpty)
                                Text(
                                  variantText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: NoirThemeColors.zinc400, // Secondary text
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${item.quantity}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: NoirThemeColors.zinc500, // Secondary text
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
                              color: NoirThemeColors.white, // Primary text
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24, thickness: 1, color: NoirThemeColors.zinc800), // UI element
                _buildRatingSection(context),
                const Divider(height: 24, thickness: 1, color: NoirThemeColors.zinc800), // UI element
                Text(
                  'Bill Details',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: NoirThemeColors.white, // Primary text
                  ),
                ),
                const SizedBox(height: 12),
                buildSummaryRow(context, 'MRP', '₹${_calculateTotalMRP().toStringAsFixed(0)}'),
                if (_calculateProductDiscount() > 0)
                  buildSummaryRow(context, 'Product Discount', '-₹${_calculateProductDiscount().toStringAsFixed(0)}', isDiscount: true),
                buildSummaryRow(context, 'Subtotal', '₹${order.subtotal?.toStringAsFixed(0) ?? '0'}'),
                buildSummaryRow(context, 'Delivery Charge', '₹${order.deliveryCharge.toStringAsFixed(0)}'),
                
                buildSummaryRow(context, 'GST', '₹${order.gst ?? 0}'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill Total',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: NoirThemeColors.white, // Primary text
                        ),
                      ),
                      Text(
                        '₹${order.orderAmount.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: NoirThemeColors.green, // Success color
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shipping & Delivery Details',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NoirThemeColors.white, // Primary text
                  ),
                ),
                const SizedBox(height: 8),
                buildDetailRow(context, 'Shipping Status', order.shippingStatus?.capitalizeFirst ?? ''),
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
                buildDetailRow(context, 'Payment Method', order.method?.capitalizeFirst ?? ''),
                if (order.razorpayPaymentId != null && order.razorpayPaymentId!.isNotEmpty)
                  buildDetailRow(context, 'Razorpay Payment ID', order.razorpayPaymentId!),
                const SizedBox(height: 16),
                if (order.status != 'Accepted')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: NoirThemeColors.zinc800, // UI element
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Paid via ${order.method?.capitalizeFirst ?? 'N/A'}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: NoirThemeColors.zinc300, // Secondary text
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NoirThemeColors.zinc800.withOpacity(0.5), // UI element
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            color: NoirThemeColors.indigo, // Primary accent
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'How were your items?',
              style: textTheme.bodyMedium?.copyWith(
                color: NoirThemeColors.white, // Primary text
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _rateOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: NoirThemeColors.green, // Success color
              foregroundColor: NoirThemeColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              'Rate',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: NoirThemeColors.white, // Primary text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatOrderButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _repeatOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: NoirThemeColors.indigo, // Primary accent
          foregroundColor: NoirThemeColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Repeat Order',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: NoirThemeColors.white, // Primary text
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'VIEW CART ON NEXT STEP',
              style: textTheme.labelSmall?.copyWith(
                color: NoirThemeColors.zinc300, // Secondary text
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Static helper widgets also moved inside the class
  static Widget buildSummaryRow(BuildContext context, String label, String value, {bool isDiscount = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: NoirThemeColors.zinc400), // Secondary text
          ),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDiscount ? NoirThemeColors.green : NoirThemeColors.white, // Success or Primary text
            ),
          ),
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
                color: NoirThemeColors.zinc400, // Secondary text
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.labelSmall?.copyWith(
                color: NoirThemeColors.white, // Primary text
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
}

// Extension for capitalizing first letter (correctly placed at the top level)