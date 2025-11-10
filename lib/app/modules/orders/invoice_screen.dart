import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/order_model.dart';
import '../../themes/app_theme.dart';

class InvoiceScreen extends StatelessWidget {
  final OrderModel order;

  const InvoiceScreen({super.key, required this.order});

  // 🧮 Financial calculations
  double _calculateTotalMRP() {
    double totalMrp = 0;
    for (var item in order.items) {
      totalMrp += item.price.toDouble() * item.quantity;
    }
    return totalMrp;
  }

  double _calculateProductDiscount() {
    double totalMrp = 0;
    double totalSellingPrice = 0;
    for (var item in order.items) {
      final itemPrice = item.price.toDouble();
      final mrp = item.price.toDouble();
      totalSellingPrice += itemPrice * item.quantity;
      totalMrp += mrp * item.quantity;
    }
    final discount = totalMrp - totalSellingPrice;
    return discount > 0 ? discount : 0;
  }

  // 🧱 Status configuration with AppColors
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'accepted':
        return {
          'color': AppColors.info,
          'bgColor': AppColors.info.withOpacity(0.12),
          'icon': Icons.new_releases_outlined,
        };
      case 'hold':
        return {
          'color': AppColors.accentOrange,
          'bgColor': AppColors.accentOrange.withOpacity(0.12),
          'icon': Icons.pause_circle_outline,
        };
      case 'shipped':
        return {
          'color': AppColors.primaryPurple,
          'bgColor': AppColors.primaryPurple.withOpacity(0.12),
          'icon': Icons.local_shipping_outlined,
        };
      case 'delivered':
        return {
          'color': AppColors.success,
          'bgColor': AppColors.success.withOpacity(0.12),
          'icon': Icons.check_circle_outline,
        };
      case 'cancelled':
      case 'rejected':
      case 'returned':
        return {
          'color': AppColors.danger,
          'bgColor': AppColors.danger.withOpacity(0.12),
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'color': AppColors.textLight,
          'bgColor': AppColors.lightGreyBackground,
          'icon': Icons.info_outline,
        };
    }
  }

  // 🧾 PDF Invoice Generation
  Future<void> _downloadInvoice() async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      pw.MemoryImage? logo;
      try {
        final logoBytes =
        (await rootBundle.load('assets/images/logo_main.png')).buffer.asUint8List();
        logo = pw.MemoryImage(logoBytes);
      } catch (e) {
        logo = null;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 🏷️ Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logo != null)
                          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
                        pw.SizedBox(height: 8),
                        pw.Text('MobiKing Wholesale',
                            style: pw.TextStyle(font: boldFont, fontSize: 20)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(font: boldFont, fontSize: 32)),
                        pw.SizedBox(height: 8),
                        pw.Text('Order ID: ${order.orderId}',
                            style: pw.TextStyle(font: font, fontSize: 11)),
                        pw.Text(
                          'Date: ${DateFormat('dd MMM yyyy').format(order.createdAt!.toLocal())}',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),

                // 🧍 Billing Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                          pw.SizedBox(height: 6),
                          pw.Text(order.name ?? 'N/A', style: pw.TextStyle(font: font, fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text(order.address ?? 'N/A',
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FROM', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                          pw.SizedBox(height: 6),
                          pw.Text('MobiKing Wholesale', style: pw.TextStyle(font: font, fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text('123, Main Street, New Delhi, India',
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('contact@mobiking.com',
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // 🛍️ Items Table
                pw.Table.fromTextArray(
                  headers: ['Item Description', 'Qty', 'Unit Price', 'Amount'],
                  data: order.items.map((item) {
                    final totalPrice = item.price * item.quantity;
                    return [
                      item.productDetails?.fullName ?? 'N/A',
                      item.quantity.toString(),
                      '₹${item.price.toStringAsFixed(0)}',
                      '₹${totalPrice.toStringAsFixed(0)}'
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
                pw.SizedBox(height: 24),

                // 💰 Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      child: pw.Column(
                        children: [
                          _buildPdfSummaryRow('Subtotal',
                              '₹${order.subtotal?.toStringAsFixed(0) ?? '0'}', font),
                          _buildPdfSummaryRow(
                              'Delivery Charge', '₹${order.deliveryCharge.toStringAsFixed(0)}', font),
                          _buildPdfSummaryRow('GST', '₹${order.gst ?? 0}', font),
                          pw.Divider(thickness: 1),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                              pw.Text('₹${order.orderAmount.toStringAsFixed(0)}',
                                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // 🧾 Footer
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Thank you for your business!',
                          style: pw.TextStyle(font: boldFont, fontSize: 12)),
                      pw.SizedBox(height: 4),
                      pw.Text('For queries, contact: support@mobiking.com',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      Get.snackbar(
        'Success',
        'Invoice downloaded successfully!',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
      );
    } catch (e, stackTrace) {
      print('Error downloading invoice: $e\n$stackTrace');
      Get.snackbar(
        'Error',
        'Failed to download invoice. Please try again.',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
      );
    }
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 11)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🌙 Flutter UI Section with AppTheme
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusConfig = _getStatusConfig(order.status);
    final orderDate = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
        : 'N/A';

    String? deliveryTime;
    if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty) {
      try {
        final deliveredDateTime = DateTime.tryParse(order.deliveredAt!) ?? DateTime.now();
        deliveryTime = DateFormat('dd MMM yyyy, h:mm a').format(deliveredDateTime.toLocal());
      } catch (e) {
        deliveryTime = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            onPressed: _downloadInvoice,
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download Invoice',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          order.orderId ?? 'N/A',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Date',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          orderDate,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusConfig['bgColor'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusConfig['icon'],
                                size: 16,
                                color: statusConfig['color'],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order.status.toUpperCase(),
                                style: textTheme.labelMedium?.copyWith(
                                  color: statusConfig['color'],
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (deliveryTime != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivered At',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            deliveryTime,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Customer Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Name', order.name ?? 'N/A', textTheme),
                    const SizedBox(height: 8),
                    _buildDetailRow('Phone', order.phoneNo ?? 'N/A', textTheme),
                    const SizedBox(height: 8),
                    _buildDetailRow('Address', order.address ?? 'N/A', textTheme),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Order Items Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...order.items.map((item) {
                      final totalPrice = item.price * item.quantity;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productDetails?.fullName ?? 'N/A',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${totalPrice.toStringAsFixed(0)}',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Price Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.05),
                      AppColors.lightPurple.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Subtotal',
                      '₹${order.subtotal?.toStringAsFixed(0) ?? '0'}',
                      textTheme,
                      false,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Delivery Charge',
                      '₹${order.deliveryCharge.toStringAsFixed(0)}',
                      textTheme,
                      false,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'GST',
                      '₹${order.gst ?? 0}',
                      textTheme,
                      false,
                    ),
                    const Divider(height: 24, color: AppColors.primaryPurple),
                    _buildSummaryRow(
                      'Total Amount',
                      '₹${order.orderAmount.toStringAsFixed(0)}',
                      textTheme,
                      true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadInvoice,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    'Download Invoice',
                    style: textTheme.labelLarge,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, TextTheme textTheme, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? textTheme.titleMedium?.copyWith(
            color: AppColors.primaryPurple,
          )
              : textTheme.bodyMedium?.copyWith(
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: isTotal
              ? textTheme.titleLarge?.copyWith(
            color: AppColors.primaryPurple,
          )
              : textTheme.bodyMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
