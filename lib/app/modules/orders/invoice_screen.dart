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
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      final mediumFont = await PdfGoogleFonts.robotoMedium();
      final italicFont = await PdfGoogleFonts.robotoItalic();

      // Calculation variables
      final double totalAmount = order.orderAmount;
      final double deliveryCharge = order.deliveryCharge;
      final double totalGst = double.tryParse(order.gst ?? '0') ?? 0;
      final double cgst = totalGst / 2;
      final double sgst = totalGst / 2;
      final double taxableSubtotal = totalAmount - totalGst - deliveryCharge;

      final String invoiceNo =
          "GST-${order.orderId.substring(order.orderId.length >= 6 ? order.orderId.length - 6 : 0).toUpperCase()}";
      final String actualDate = DateFormat('dd/MM/yyyy').format(
        order.createdAt != null ? order.createdAt.toLocal() : DateTime.now(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: TAX INVOICE
                pw.Center(
                  child: pw.Text(
                    'TAX INVOICE',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Company Info and Invoice Details Row (Converted to Table for equal heights)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        // Left: Company Details
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'MOBIKING WHOLESALE',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 14,
                                ),
                              ),
                              pw.Text(
                                '3rd floor B-91 opp.isckon temple east of kailash,',
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                              pw.Text(
                                'New Delhi 110065',
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                              pw.Text(
                                'Contact: 8587901901',
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                              pw.Text(
                                'Email: mobiking507@gmail.com',
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'GSTIN: 07BESPC8834B1ZG',
                                style: pw.TextStyle(
                                  font: mediumFont,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right: Invoice No. and Date
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: PdfColors.grey),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Invoice No.',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    invoiceNo,
                                    style: pw.TextStyle(
                                      font: mediumFont,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Date',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    actualDate,
                                    style: pw.TextStyle(
                                      font: mediumFont,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Bill To Section (Seamlessly attached without doubling the top border)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey),
                      right: pw.BorderSide(color: PdfColors.grey),
                      bottom: pw.BorderSide(color: PdfColors.grey),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(font: mediumFont, fontSize: 10),
                      ),
                      pw.Text(
                        order.name ?? 'N/A',
                        style: pw.TextStyle(font: boldFont, fontSize: 11),
                      ),
                      pw.Text(
                        'Contact: ${order.phoneNo ?? 'N/A'}',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      if (order.address != null)
                        pw.Text(
                          '${order.address!}${order.city != null ? ", ${order.city}" : ""}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      if (order.state != null || order.pincode != null)
                        pw.Text(
                          '${order.state ?? ""} ${order.pincode ?? ""}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                    ],
                  ),
                ),

                // Main Items Table (Omit top border to avoid 2px thickness with Bill To section)
                pw.Table(
                  border: const pw.TableBorder(
                    left: pw.BorderSide(color: PdfColors.grey),
                    right: pw.BorderSide(color: PdfColors.grey),
                    bottom: pw.BorderSide(color: PdfColors.grey),
                    verticalInside: pw.BorderSide(color: PdfColors.grey),
                    horizontalInside: pw.BorderSide(color: PdfColors.grey),
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FixedColumnWidth(60),
                    3: const pw.FixedColumnWidth(25),
                    4: const pw.FixedColumnWidth(60),
                    5: const pw.FixedColumnWidth(35),
                    6: const pw.FixedColumnWidth(60),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('S.No', boldFont, 8, isHeader: true),
                        _buildTableCell(
                          'PARTICULARS',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                        _buildTableCell('HSN/SAC', boldFont, 8, isHeader: true),
                        _buildTableCell('QTY', boldFont, 8, isHeader: true),
                        _buildTableCell(
                          'EXCL PRICE',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                        _buildTableCell('GST %', boldFont, 8, isHeader: true),
                        _buildTableCell('TAXABLE', boldFont, 8, isHeader: true),
                      ],
                    ),
                    // Item Rows
                    ...List.generate(order.items.length, (index) {
                      final item = order.items[index];
                      final double taxableValuePerItem = item.price / 1.18;
                      final double totalTaxablePerItem =
                          taxableValuePerItem * item.quantity;

                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            (index + 1).toString(),
                            font,
                            9,
                            isHeader: true,
                          ),
                          _buildTableCell(
                            item.productDetails?.fullName ?? 'N/A',
                            font,
                            9,
                          ),
                          _buildTableCell('85044030', font, 9, isHeader: true),
                          _buildTableCell(
                            item.quantity.toString(),
                            font,
                            9,
                            isHeader: true,
                          ),
                          _buildTableCell(
                            taxableValuePerItem.toStringAsFixed(2),
                            font,
                            9,
                            isHeader: true,
                          ),
                          _buildTableCell('18%', font, 9, isHeader: true),
                          _buildTableCell(
                            totalTaxablePerItem.toStringAsFixed(2),
                            font,
                            9,
                            isHeader: true,
                          ),
                        ],
                      );
                    }),
                    // Total Row
                    pw.TableRow(
                      children: [
                        _buildTableCell('', boldFont, 9),
                        _buildTableCell('TOTAL', boldFont, 9, isHeader: true),
                        _buildTableCell('', font, 9),
                        _buildTableCell(
                          order.items
                              .fold(
                                0,
                                (sum, item) => (sum as int) + item.quantity,
                              )
                              .toString(),
                          mediumFont,
                          9,
                          isHeader: true,
                        ),
                        _buildTableCell('', font, 9),
                        _buildTableCell('', font, 9),
                        _buildTableCell(
                          taxableSubtotal.toStringAsFixed(2),
                          boldFont,
                          10,
                          isHeader: true,
                        ),
                      ],
                    ),
                  ],
                ),

                // Combined Summary Section (Converted to Table)
                pw.Table(
                  border: const pw.TableBorder(
                    left: pw.BorderSide(color: PdfColors.grey),
                    right: pw.BorderSide(color: PdfColors.grey),
                    bottom: pw.BorderSide(color: PdfColors.grey),
                    verticalInside: pw.BorderSide(color: PdfColors.grey),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        // Amount in Words Box
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Amount in Words:',
                                style: pw.TextStyle(
                                  font: mediumFont,
                                  fontSize: 9,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                _numberToWords(totalAmount),
                                style: pw.TextStyle(
                                  font: italicFont,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Totals Breakdown Box
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            // Small Summary Rows
                            pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Column(
                                children: [
                                  _buildSummaryRowSmall(
                                    'Taxable Value',
                                    'INR ${taxableSubtotal.toStringAsFixed(2)}',
                                    font,
                                  ),
                                  _buildSummaryRowSmall(
                                    'CGST (9%) (+)',
                                    'INR ${cgst.toStringAsFixed(2)}',
                                    font,
                                  ),
                                  _buildSummaryRowSmall(
                                    'SGST (9%) (+)',
                                    'INR ${sgst.toStringAsFixed(2)}',
                                    font,
                                  ),
                                  if (deliveryCharge > 0)
                                    _buildSummaryRowSmall(
                                      'Delivery Charge',
                                      'INR ${deliveryCharge.toStringAsFixed(2)}',
                                      font,
                                    ),
                                ],
                              ),
                            ),
                            // Prominent Total Amount
                            pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100,
                                border: pw.Border(
                                  top: pw.BorderSide(color: PdfColors.grey),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'TOTAL AMOUNT',
                                    style: pw.TextStyle(
                                      font: mediumFont,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  pw.Text(
                                    'INR ${totalAmount.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 16,
                                    ),
                                  ),
                                  pw.Divider(
                                    color: PdfColors.grey,
                                    thickness: 0.5,
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Mode',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Text(
                                        order.method.toUpperCase(),
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // GST Breakdown Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('HSN/SAC', boldFont, 8, isHeader: true),
                        _buildTableCell(
                          'Taxable Amt',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          'CGST (9%)',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          'SGST (9%)',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          'Total Tax',
                          boldFont,
                          8,
                          isHeader: true,
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('85044030', font, 9, isHeader: true),
                        _buildTableCell(
                          taxableSubtotal.toStringAsFixed(2),
                          font,
                          9,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          cgst.toStringAsFixed(2),
                          font,
                          9,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          sgst.toStringAsFixed(2),
                          font,
                          9,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          totalGst.toStringAsFixed(2),
                          font,
                          9,
                          isHeader: true,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Terms and Bank Details block (Converted to Table)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        // Left: Terms and Bank
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Terms / Declaration',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 9,
                                ),
                              ),
                              pw.Text(
                                '1. Goods once sold will not be taken back or exchange',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.Text(
                                '2. Mobiking will not be responsible for any warranty',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.Text(
                                '3. All the disputes are subject to delhi jurisdiction only',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.SizedBox(height: 10),
                              pw.Text(
                                'Bank Details -',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 9,
                                ),
                              ),
                              pw.Text(
                                'Bank Name : MOBIKING',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.Text(
                                'Account No. : 50200048030390',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.Text(
                                'Branch & IFSC : HDFC0000480',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                        // Right: Signature
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'For, Mobiking',
                                style: pw.TextStyle(
                                  font: mediumFont,
                                  fontSize: 9,
                                ),
                              ),
                              pw.SizedBox(
                                height: 40,
                              ), // Force distance between elements
                              pw.Text(
                                'Authorised Signatory',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated invoice and does not require signature',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      Get.snackbar(
        'Invoice',
        'Invoice document generated for printing/saving.',
        backgroundColor: AppColors.primaryPurple,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      print('Error generating invoice: $e\n$stackTrace');
      Get.snackbar(
        'Error',
        'Failed to generate invoice.',
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
      );
    }
  }

  // Updated to include structural wrapping for absolute centering/alignment
  pw.Widget _buildTableCell(
    String text,
    pw.Font font,
    double fontSize, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: isHeader ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildSummaryRowSmall(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
        ],
      ),
    );
  }

  String _numberToWords(double amount) {
    int total = amount.floor();
    if (total == 0) return "Zero Rupees Only";

    String words = "";

    int crores = total ~/ 10000000;
    total %= 10000000;
    if (crores > 0) words += "${_convertLessThanThousand(crores)} Crore ";

    int lakhs = total ~/ 100000;
    total %= 100000;
    if (lakhs > 0) words += "${_convertLessThanThousand(lakhs)} Lakh ";

    int thousands = total ~/ 1000;
    total %= 1000;
    if (thousands > 0)
      words += "${_convertLessThanThousand(thousands)} Thousand ";

    if (total > 0) words += _convertLessThanThousand(total);

    return "${words.trim()} Rupees Only";
  }

  String _convertLessThanThousand(int n) {
    final units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
    ];
    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ];

    if (n < 20) return units[n];
    if (n < 100)
      return "${tens[n ~/ 10]}${n % 10 != 0 ? " ${units[n % 10]}" : ""}";
    return "${units[n ~/ 100]} Hundred${n % 100 != 0 ? " and ${_convertLessThanThousand(n % 100)}" : ""}";
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
        final deliveredDateTime =
            DateTime.tryParse(order.deliveredAt!) ?? DateTime.now();
        deliveryTime = DateFormat(
          'dd MMM yyyy, h:mm a',
        ).format(deliveredDateTime.toLocal());
      } catch (e) {
        deliveryTime = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: textTheme.headlineMedium?.copyWith(color: AppColors.white),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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

              // 🚩 Rejected Request Reason (Return/Cancel)
              ...order.requests
                  .where((r) => r.status.toLowerCase() == 'rejected')
                  .map((request) {
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${request.type} Request Rejected',
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (request.reason != null &&
                              request.reason!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Rejection Reason:',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.reason!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

              // 🚫 Main Order Rejection/Cancellation Reason
              if ((order.status.toLowerCase() == 'rejected' ||
                      order.status.toLowerCase() == 'cancelled') &&
                  order.reason != null &&
                  order.reason!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order ${order.status.capitalizeFirst}',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reason:',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.reason!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
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
                    _buildDetailRow(
                      'Address',
                      order.address ?? 'N/A',
                      textTheme,
                    ),
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
                  label: Text('Download Invoice', style: textTheme.labelLarge),
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
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
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

  Widget _buildSummaryRow(
    String label,
    String value,
    TextTheme textTheme,
    bool isTotal,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? textTheme.titleMedium?.copyWith(color: AppColors.primaryPurple)
              : textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
        ),
        Text(
          value,
          style: isTotal
              ? textTheme.titleLarge?.copyWith(color: AppColors.primaryPurple)
              : textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
