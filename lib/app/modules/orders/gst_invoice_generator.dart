import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/order_model.dart';

class GstInvoiceGenerator {
  static Future<void> generateAndDownload(OrderModel order) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).format(order.createdAt.toLocal());

      // Processing items
      final processedItems = order.items.map<Map<String, dynamic>>((item) {
        final double gstRate = 18.0;
        final double exclusiveRate = item.price / (1 + (gstRate / 100));
        final double taxableValue = exclusiveRate * item.quantity;
        final double taxAmount = taxableValue * (gstRate / 100);

        return {
          'name': item.productDetails?.fullName ?? item.variantName,
          'quantity': item.quantity,
          'gstRate': gstRate,
          'exclusiveRate': exclusiveRate,
          'taxableValue': taxableValue,
          'taxAmount': taxAmount,
          'hsn': '85044030',
        };
      }).toList();

      Map<String, dynamic>? deliveryItem;
      if (order.deliveryCharge > 0) {
        final double deliveryGstRate = 18.0;
        final double deliveryExclusive =
            order.deliveryCharge / (1 + (deliveryGstRate / 100));
        final double deliveryTaxAmount =
            deliveryExclusive * (deliveryGstRate / 100);
        deliveryItem = {
          'name': 'Delivery Charges',
          'quantity': 1,
          'gstRate': deliveryGstRate,
          'exclusiveRate': deliveryExclusive,
          'taxableValue': deliveryExclusive,
          'taxAmount': deliveryTaxAmount,
          'hsn': '9967',
        };
      }

      final allItems = [...processedItems];
      if (deliveryItem != null) allItems.add(deliveryItem);

      // Calculations
      final double totalTaxableValue = allItems.fold(
        0.0,
        (sum, item) => sum + (item['taxableValue'] as double),
      );
      final double totalTaxAmount = allItems.fold(
        0.0,
        (sum, item) => sum + (item['taxAmount'] as double),
      );
      final double discountApplied = order.discount;

      double discountRatio = 1.0;
      if (discountApplied > 0 && totalTaxableValue > 0) {
        discountRatio = 1.0 - (discountApplied / totalTaxableValue);
        if (discountRatio < 0) discountRatio = 0.0;
      }

      final double discountedTaxableValue = totalTaxableValue * discountRatio;
      final double discountedTaxAmount = totalTaxAmount * discountRatio;
      final double totalAmount = discountedTaxableValue + discountedTaxAmount;

      final amountInWords = _numberToWords(totalAmount);
      final String invoiceNo = order.orderId;

      final textStyleRegular = pw.TextStyle(font: font, fontSize: 9);
      final textStyleBold = pw.TextStyle(font: boldFont, fontSize: 9);
      final textStyleSmall = pw.TextStyle(font: font, fontSize: 8);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Top TAX INVOICE Header
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    'TAX INVOICE',
                    style: pw.TextStyle(font: boldFont, fontSize: 11),
                  ),
                ),
              ),

              // Box 1: Company details and Invoice details (Using Table for top-to-bottom divider)
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(62),
                  1: const pw.FlexColumnWidth(38),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'MOBIKING WHOLESALE',
                              style: pw.TextStyle(font: boldFont, fontSize: 13),
                            ),
                            pw.Text(
                              '3rd floor B-91 opp.isckon temple east of kailash,',
                              style: textStyleRegular,
                            ),
                            pw.Text(
                              'New Delhi 110065',
                              style: textStyleRegular,
                            ),
                            pw.Text(
                              'Contact : 8587901901',
                              style: textStyleRegular,
                            ),
                            pw.Text(
                              'Email : mobiking507@gmail.com',
                              style: textStyleRegular,
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'GSTIN : 07BESPC8834B1ZG',
                              style: pw.TextStyle(font: boldFont, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(width: 1),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Invoice No.', style: textStyleSmall),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'GST-$invoiceNo',
                                  style: textStyleRegular,
                                ),
                              ],
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Date', style: textStyleSmall),
                                pw.SizedBox(height: 2),
                                pw.Text(invoiceDate, style: textStyleRegular),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Box 2: Bill To
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(6),
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To :',
                      style: pw.TextStyle(font: boldFont, fontSize: 9),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(order.name ?? '', style: textStyleRegular),
                    pw.Text(order.address ?? '', style: textStyleRegular),
                    if (order.city != null ||
                        order.state != null ||
                        order.pincode != null)
                      pw.Text(
                        '${order.city ?? ''} ${order.state ?? ''} ${order.pincode ?? ''}'
                            .trim(),
                        style: textStyleRegular,
                      ),
                    pw.Text(
                      'Contact: ${order.phoneNo ?? ''}',
                      style: textStyleRegular,
                    ),
                    if (order.gst != null &&
                        order.gst != "0" &&
                        order.gst!.isNotEmpty)
                      pw.Text('GST: ${order.gst}', style: textStyleRegular),
                  ],
                ),
              ),

              // Box 3: Main Table
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(8),
                  1: const pw.FlexColumnWidth(40),
                  2: const pw.FlexColumnWidth(12),
                  3: const pw.FlexColumnWidth(8),
                  4: const pw.FlexColumnWidth(12),
                  5: const pw.FlexColumnWidth(8),
                  6: const pw.FlexColumnWidth(12),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _pdfTableCell('S.No.', textStyleBold, isCenter: true),
                      _pdfTableCell(
                        'PARTICULARS',
                        textStyleBold,
                        isCenter: false,
                      ),
                      _pdfTableCell('HSN/SAC', textStyleBold, isCenter: true),
                      _pdfTableCell('QTY', textStyleBold, isCenter: true),
                      _pdfTableCell(
                        'UNIT PRICE',
                        textStyleBold,
                        isCenter: true,
                      ),
                      _pdfTableCell('GST', textStyleBold, isCenter: true),
                      _pdfTableCell('AMOUNT', textStyleBold, isCenter: true),
                    ],
                  ),
                  ...allItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(
                          '${i + 1}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '${item['name']}',
                          textStyleRegular,
                          isCenter: false,
                        ),
                        _pdfTableCell(
                          '${item['hsn']}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '${item['quantity']}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          (item['exclusiveRate'] as double).toStringAsFixed(2),
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '${(item['gstRate'] as double).toStringAsFixed(0)}%',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          (item['taxableValue'] as double).toStringAsFixed(2),
                          textStyleRegular,
                          isCenter: true,
                        ),
                      ],
                    );
                  }),
                  if (discountApplied > 0)
                    pw.TableRow(
                      children: [
                        _pdfTableCell('', textStyleRegular, isCenter: true),
                        _pdfTableCell(
                          'Discount',
                          textStyleRegular,
                          isCenter: false,
                        ),
                        _pdfTableCell('', textStyleRegular, isCenter: true),
                        _pdfTableCell('', textStyleRegular, isCenter: true),
                        _pdfTableCell('', textStyleRegular, isCenter: true),
                        _pdfTableCell('', textStyleRegular, isCenter: true),
                        _pdfTableCell(
                          '-₹ ${discountApplied.toStringAsFixed(2)}',
                          pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            color: PdfColors.red,
                          ),
                          isCenter: true,
                        ),
                      ],
                    ),
                  pw.TableRow(
                    children: [
                      _pdfTableCell('', textStyleRegular, isCenter: true),
                      _pdfTableCell('TOTAL', textStyleBold, isCenter: false),
                      _pdfTableCell('', textStyleRegular, isCenter: true),
                      _pdfTableCell(
                        '${processedItems.fold(0, (int s, it) => s + (it['quantity'] as int))}',
                        textStyleRegular,
                        isCenter: true,
                      ),
                      _pdfTableCell('', textStyleRegular, isCenter: true),
                      _pdfTableCell('', textStyleRegular, isCenter: true),
                      _pdfTableCell(
                        discountedTaxableValue.toStringAsFixed(2),
                        textStyleBold,
                        isCenter: true,
                      ),
                    ],
                  ),
                ],
              ),

              // Sub Total & Tax Floating Right (As a square Box)
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
                child: pw.Container(
                  width: PdfPageFormat.a4.availableWidth * 0.35,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Sub Total', style: textStyleRegular),
                          pw.Text(
                            '₹ ${discountedTaxableValue.toStringAsFixed(2)}',
                            style: textStyleRegular,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tax Amount (+)', style: textStyleRegular),
                          pw.Text(
                            '₹ ${discountedTaxAmount.toStringAsFixed(2)}',
                            style: textStyleRegular,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Box 4: Amount in words (Using Table for full height center divider)
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(62),
                  1: const pw.FlexColumnWidth(38),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Amount in Words :', style: textStyleBold),
                            pw.SizedBox(height: 4),
                            pw.Text(amountInWords, style: textStyleRegular),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('TOTAL AMOUNT', style: textStyleBold),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              '₹ ${totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(font: boldFont, fontSize: 13),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text('Amount Paid', style: textStyleSmall),
                            pw.Text(
                              '₹ ${(order.paymentStatus.toLowerCase() == "paid" || order.paymentStatus.toLowerCase() == "success" ? totalAmount : 0).toStringAsFixed(2)}',
                              style: textStyleRegular,
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text('Balance', style: textStyleSmall),
                            pw.Text(
                              '₹ ${(order.paymentStatus.toLowerCase() == "paid" || order.paymentStatus.toLowerCase() == "success" ? 0 : totalAmount).toStringAsFixed(2)}',
                              style: textStyleRegular,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Box 5: Tax Breakdown Table
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(25),
                  1: const pw.FlexColumnWidth(25),
                  2: const pw.FlexColumnWidth(15),
                  3: const pw.FlexColumnWidth(15),
                  4: const pw.FlexColumnWidth(20),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _pdfTableCell('HSN/SAC', textStyleBold, isCenter: true),
                      _pdfTableCell(
                        'Taxable Amount',
                        textStyleBold,
                        isCenter: true,
                      ),
                      _pdfTableCell('Rate', textStyleBold, isCenter: true),
                      _pdfTableCell('Amount', textStyleBold, isCenter: true),
                      _pdfTableCell(
                        'Total Tax Amount',
                        textStyleBold,
                        isCenter: true,
                      ),
                    ],
                  ),
                  ...allItems.map((item) {
                    final double adjustedTaxableValue =
                        (item['taxableValue'] as double) * discountRatio;
                    final double adjustedTaxAmount =
                        (item['taxAmount'] as double) * discountRatio;
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(
                          '${item['hsn']}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '₹ ${adjustedTaxableValue.toStringAsFixed(2)}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '${(item['gstRate'] as double).toStringAsFixed(0)}%',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '₹ ${adjustedTaxAmount.toStringAsFixed(2)}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                        _pdfTableCell(
                          '₹ ${adjustedTaxAmount.toStringAsFixed(2)}',
                          textStyleRegular,
                          isCenter: true,
                        ),
                      ],
                    );
                  }),
                  pw.TableRow(
                    children: [
                      _pdfTableCell('Total', textStyleBold, isCenter: true),
                      _pdfTableCell(
                        '₹ ${discountedTaxableValue.toStringAsFixed(2)}',
                        textStyleBold,
                        isCenter: true,
                      ),
                      _pdfTableCell('-', textStyleRegular, isCenter: true),
                      _pdfTableCell(
                        '₹ ${discountedTaxAmount.toStringAsFixed(2)}',
                        textStyleBold,
                        isCenter: true,
                      ),
                      _pdfTableCell(
                        '₹ ${discountedTaxAmount.toStringAsFixed(2)}',
                        textStyleBold,
                        isCenter: true,
                      ),
                    ],
                  ),
                ],
              ),

              // Box 6: Terms / Bank Details / Signature
              // Box 6: Terms / Bank Details / Signature (Using Table for top-to-bottom divider)
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(74),
                  1: const pw.FlexColumnWidth(26),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Terms / Declaration', style: textStyleBold),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              '1. Goods once sold will not be taken back or exchange',
                              style: textStyleSmall,
                            ),
                            pw.Text(
                              '2. Mobiking will not be responsible for any warranty',
                              style: textStyleSmall,
                            ),
                            pw.Text(
                              '3. All the disputes are subject to delhi jurisdiction only',
                              style: textStyleSmall,
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text('Bank Details -', style: textStyleBold),
                            pw.Text(
                              'Bank Name : MOBIKING',
                              style: textStyleSmall,
                            ),
                            pw.Text(
                              'Account No. : 50200048030390',
                              style: textStyleSmall,
                            ),
                            pw.Text(
                              'Branch & IFSC : HDFC0000480',
                              style: textStyleSmall,
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('For, Mobiking', style: textStyleBold),
                            pw.SizedBox(height: 50),
                            pw.Text(
                              'Authorised Signatory',
                              style: textStyleSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'This is a computer generated invoice and does not require signature',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        name: "GST_$invoiceNo",
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      rethrow;
    }
  }

  static pw.Widget _pdfTableCell(
    String text,
    pw.TextStyle style, {
    bool isCenter = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: isCenter ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: style,
        textAlign: isCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static String _numberToWords(double amount) {
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
    if (thousands > 0) {
      words += "${_convertLessThanThousand(thousands)} Thousand ";
    }

    if (total > 0) {
      if (words.isNotEmpty && total < 100) words += "and ";
      words += _convertLessThanThousand(total);
    }

    return "${words.trim()} Rupees Only";
  }

  static String _convertLessThanThousand(int n) {
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
}
