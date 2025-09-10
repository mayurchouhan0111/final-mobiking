// Path: lib/app/modules/order_history/shipping_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobiking/app/data/scan_model.dart';
import 'package:animated_milestone/view/milestone_timeline.dart';
import 'package:animated_milestone/model/milestone.dart' as am_milestone;

import '../../data/order_model.dart';
import '../../themes/app_theme.dart';

class ShippingDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const ShippingDetailsScreen({Key? key, required this.order}) : super(key: key);

  // ✅ REFACTORED: Moved status determination logic into a helper function for clarity.
  int _getCurrentMilestoneIndex(List<Scan> scans) {
    if (scans.isEmpty) {
      return 0; // Default to 'Order Placed' if no scans exist
    }

    final String latestStatus = scans.last.status.toUpperCase();
    final String latestSrStatusLabel = scans.last.srStatusLabel.toUpperCase();

    // The order of these checks is important (most advanced status first).
    if (latestStatus.contains('DELIVERED')) {
      return 4; // Delivered
    }
    if (latestStatus.contains('OUT_FOR_DELIVERY') || latestSrStatusLabel.contains('OUT FOR DELIVERY')) {
      return 3; // Out for Delivery
    }
    if (latestStatus.contains('IN_TRANSIT') || latestSrStatusLabel.contains('IN TRANSIT')) {
      return 2; // In Transit
    }
    if (latestStatus.contains('SHIPPED') || latestStatus.contains('PICKED_UP')) {
      return 1; // Shipped
    }

    // Default to Order Placed if none of the above match.
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Scan> scans = order.scans ?? [];

    // --- Data Preparation ---
    String currentActivity = 'Your order has been placed.';
    String currentLocation = 'N/A';
    DateTime? lastScanDateTime;

    if (scans.isNotEmpty) {
      final Scan lastScan = scans.last;
      currentActivity = lastScan.activity;
      currentLocation = lastScan.location;
      try {
        lastScanDateTime = DateTime.parse(lastScan.date);
      } catch (e) {
        debugPrint('Error parsing date for last scan: ${lastScan.date} - $e');
      }
    }

    final List<String> overallMilestones = [
      'Order Placed',
      'Shipped',
      'In Transit',
      'Out for Delivery',
      'Delivered',
    ];

    final int currentMilestoneIndex = _getCurrentMilestoneIndex(scans);

    // ✅ FIXED: Use the actual expected delivery date from the order model.
    String estimatedDelivery = 'Not available';
    if (order.expectedDeliveryDate != null && order.expectedDeliveryDate!.isNotEmpty) {
      try {
        final dt = DateTime.parse(order.expectedDeliveryDate!);
        estimatedDelivery = DateFormat('EEEE, MMM d').format(dt.toLocal());
      } catch (e) {
        estimatedDelivery = order.expectedDeliveryDate!;
      }
    }

    if (currentMilestoneIndex == 4 && lastScanDateTime != null) {
      estimatedDelivery = 'on ${DateFormat('EEEE, MMM d').format(lastScanDateTime.toLocal())}';
    }


    // --- Timeline Building ---
    List<am_milestone.Milestone> timelineMilestones = [];

    // 1. Build the Overall Progress section
    for (int i = 0; i < overallMilestones.length; i++) {
      final bool isCompleted = i < currentMilestoneIndex;
      final bool isActive = i == currentMilestoneIndex;
      final bool isPending = i > currentMilestoneIndex;

      // ✅ ENHANCED: Use a specific date for completed milestones if possible
      String description = '';
      if (isCompleted) {
        // Find the first scan that corresponds to this completed status
        final relevantScan = scans.firstWhere(
              (s) => _getCurrentMilestoneIndex([s]) >= i,
          orElse: () => scans.first,
        );
        final completedDate = DateTime.tryParse(relevantScan.date);
        description = completedDate != null
            ? 'Completed on ${DateFormat('dd MMM').format(completedDate.toLocal())}'
            : 'Completed';
      } else if (isActive) {
        description = 'In Progress';
      }

      timelineMilestones.add(
        am_milestone.Milestone(
          isActive: isCompleted || isActive,
          title: Text(
            overallMilestones[i],
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPending ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          child: Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          ),
          // ✅ ENHANCED: Use distinct icons for different states
          icon: isCompleted
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24)
              : isActive
              ? const Icon(Icons.radio_button_checked_rounded, color: AppColors.info, size: 24)
              : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textLight, size: 24),
        ),
      );
    }

    // 2. Add Detailed History section if scans are available
    if (scans.isNotEmpty) {
      timelineMilestones.add(
        am_milestone.Milestone(
          isActive: true,
          title: Text('Detailed History', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          child: const SizedBox.shrink(),
          icon: const Icon(Icons.history, color: AppColors.textDark, size: 24),
        ),
      );

      for (final scan in scans.reversed) { // Show newest first
        final String formattedDate = DateTime.tryParse(scan.date) != null
            ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(scan.date).toLocal())
            : 'N/A';

        timelineMilestones.add(
          am_milestone.Milestone(
            isActive: true, // All history items are "active" in the timeline sense
            icon: const Icon(Icons.circle, color: AppColors.textLight, size: 12),
            title: Text(scan.activity, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate, style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium)),
                Text(scan.location, style: textTheme.bodySmall?.copyWith(color: AppColors.textMedium)),
              ],
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text('Shipment Tracking', style: textTheme.titleLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: #${order.orderId}',
                    style: textTheme.labelLarge?.copyWith(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overallMilestones[currentMilestoneIndex],
                    style: textTheme.headlineSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latest Update: $currentActivity',
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.textDark),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.textMedium, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        currentMilestoneIndex == 4 ? 'Delivered ' : 'Estimated Delivery: ',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                      ),
                      Text(
                        estimatedDelivery,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: MilestoneTimeline(
                milestones: timelineMilestones,
                color: AppColors.success,
                stickThickness: 2,
                activeWithStick: true,
                milestoneIntervalDurationInMillis: 200,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}