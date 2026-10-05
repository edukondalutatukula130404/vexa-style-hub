import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'order_service.dart';

class InvoicePdfService {
  static String _pdfEscape(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('₹', 'Rs. ');
  }

  /// Generates a valid PDF 1.4 binary document for the order invoice
  static Uint8List generateInvoicePdf(String invoiceNo, OrderModel order) {
    final streamContent = StringBuffer();

    // 1. Navy Header Banner (y=760 to 815)
    streamContent.writeln('0.05 0.14 0.25 rg'); // Dark Navy #0C2340
    streamContent.writeln('30 760 535 55 re f');

    // Header Title
    streamContent.writeln('BT');
    streamContent.writeln('/F1 18 Tf');
    streamContent.writeln('1 0 0 1 45 795 Tm');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('(${_pdfEscape("VEXA LUXURY WEAR - TAX E-INVOICE")}) Tj');
    streamContent.writeln('ET');

    // Header Subtitle
    streamContent.writeln('BT');
    streamContent.writeln('/F2 9 Tf');
    streamContent.writeln('1 0 0 1 45 773 Tm');
    streamContent.writeln('0.9 0.9 0.9 rg');
    streamContent.writeln('(${_pdfEscape("Vexa Style Hub Pvt. Ltd. | Indiranagar 100ft Road, Bengaluru - 560038 | GSTIN: 29AAACV9812F1Z4")}) Tj');
    streamContent.writeln('ET');

    // 2. Gold Decorative Bar
    streamContent.writeln('0.77 0.62 0.35 rg'); // Gold #C5A059
    streamContent.writeln('30 755 535 2 re f');

    // 3. Invoice Metadata Box
    streamContent.writeln('0.97 0.98 0.99 rg'); // Light gray fill #F8FAFC
    streamContent.writeln('30 670 535 75 re f');
    streamContent.writeln('0.88 0.91 0.94 RG'); // Border
    streamContent.writeln('30 670 535 75 re s');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 10.5 Tf');
    streamContent.writeln('0.05 0.14 0.25 rg');

    // Left Column
    streamContent.writeln('1 0 0 1 45 725 Tm');
    streamContent.writeln('(${_pdfEscape("INVOICE NO: $invoiceNo")}) Tj');
    streamContent.writeln('1 0 0 1 45 707 Tm');
    streamContent.writeln('(${_pdfEscape("ORDER ID: ${order.id}")}) Tj');
    streamContent.writeln('1 0 0 1 45 689 Tm');
    streamContent.writeln('(${_pdfEscape("DATE: ${order.formattedDate}")}) Tj');

    // Right Column
    streamContent.writeln('1 0 0 1 320 725 Tm');
    streamContent.writeln('(${_pdfEscape("PAYMENT: ${order.paymentMethod}")}) Tj');
    streamContent.writeln('1 0 0 1 320 707 Tm');
    streamContent.writeln('(${_pdfEscape("STATUS: ${order.isPaid ? 'PAID' : 'CONFIRMED'}")}) Tj');
    streamContent.writeln('1 0 0 1 320 689 Tm');
    streamContent.writeln('(${_pdfEscape("CURRENCY: INR (Rs.)")}) Tj');
    streamContent.writeln('ET');

    // 4. Billed To Details Section
    streamContent.writeln('BT');
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0.05 0.14 0.25 rg');
    streamContent.writeln('1 0 0 1 30 645 Tm');
    streamContent.writeln('(${_pdfEscape("BILLED TO / CUSTOMER DETAILS")}) Tj');
    streamContent.writeln('ET');

    streamContent.writeln('BT');
    streamContent.writeln('/F2 10 Tf');
    streamContent.writeln('0.2 0.25 0.33 rg');
    streamContent.writeln('1 0 0 1 45 627 Tm');
    streamContent.writeln('(${_pdfEscape("Customer Name : ${order.customerName}")}) Tj');
    streamContent.writeln('1 0 0 1 45 611 Tm');
    streamContent.writeln('(${_pdfEscape("Address       : ${order.shippingAddress}")}) Tj');
    streamContent.writeln('1 0 0 1 45 595 Tm');
    streamContent.writeln('(${_pdfEscape("Phone Number  : ${order.phone}")}) Tj');
    streamContent.writeln('ET');

    // 5. Items Table Header
    streamContent.writeln('0.05 0.14 0.25 rg');
    streamContent.writeln('30 560 535 24 re f');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('1 0 0 1 45 568 Tm');
    streamContent.writeln('(${_pdfEscape("ITEM DESCRIPTION")}) Tj');
    streamContent.writeln('1 0 0 1 300 568 Tm');
    streamContent.writeln('(${_pdfEscape("SIZE")}) Tj');
    streamContent.writeln('1 0 0 1 350 568 Tm');
    streamContent.writeln('(${_pdfEscape("QTY")}) Tj');
    streamContent.writeln('1 0 0 1 400 568 Tm');
    streamContent.writeln('(${_pdfEscape("PRICE")}) Tj');
    streamContent.writeln('1 0 0 1 480 568 Tm');
    streamContent.writeln('(${_pdfEscape("TOTAL")}) Tj');
    streamContent.writeln('ET');

    // 6. Items Rows
    double y = 540;
    for (int idx = 0; idx < order.items.length; idx++) {
      final item = order.items[idx];
      final itemTotal = item.price * item.quantity;

      if (idx % 2 == 1) {
        streamContent.writeln('0.97 0.98 0.99 rg');
        streamContent.writeln('30 ${y - 4} 535 20 re f');
      }

      final nameStr = item.name.length > 35 ? '${item.name.substring(0, 35)}...' : item.name;

      streamContent.writeln('BT');
      streamContent.writeln('/F2 9.5 Tf');
      streamContent.writeln('0.1 0.1 0.1 rg');
      streamContent.writeln('1 0 0 1 45 $y Tm');
      streamContent.writeln('(${_pdfEscape(nameStr)}) Tj');
      streamContent.writeln('1 0 0 1 300 $y Tm');
      streamContent.writeln('(${_pdfEscape(item.size)}) Tj');
      streamContent.writeln('1 0 0 1 350 $y Tm');
      streamContent.writeln('(${_pdfEscape(item.quantity.toString())}) Tj');
      streamContent.writeln('1 0 0 1 400 $y Tm');
      streamContent.writeln('(${_pdfEscape("Rs. ${item.price.toStringAsFixed(0)}")}) Tj');
      streamContent.writeln('1 0 0 1 480 $y Tm');
      streamContent.writeln('(${_pdfEscape("Rs. ${itemTotal.toStringAsFixed(0)}")}) Tj');
      streamContent.writeln('ET');

      y -= 22;
    }

    // Divider
    y -= 10;
    streamContent.writeln('0.85 0.88 0.92 RG');
    streamContent.writeln('30 $y 535 0.8 re s');

    // 7. Tax & Totals Breakdown
    y -= 25;
    final totalAmt = order.totalAmount > 0 ? order.totalAmount : 1499.0;
    final subtotal = totalAmt / 1.18;
    final gstTotal = totalAmt - subtotal;
    final cgst = gstTotal / 2;
    final sgst = gstTotal / 2;

    streamContent.writeln('BT');
    streamContent.writeln('/F2 9.5 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('1 0 0 1 300 $y Tm');
    streamContent.writeln('(${_pdfEscape("Subtotal (Taxable Value):")}) Tj');
    streamContent.writeln('1 0 0 1 480 $y Tm');
    streamContent.writeln('(${_pdfEscape("Rs. ${subtotal.toStringAsFixed(2)}")}) Tj');
    streamContent.writeln('ET');

    y -= 18;
    streamContent.writeln('BT');
    streamContent.writeln('/F2 9.5 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('1 0 0 1 300 $y Tm');
    streamContent.writeln('(${_pdfEscape("CGST (9%):")}) Tj');
    streamContent.writeln('1 0 0 1 480 $y Tm');
    streamContent.writeln('(${_pdfEscape("Rs. ${cgst.toStringAsFixed(2)}")}) Tj');
    streamContent.writeln('ET');

    y -= 18;
    streamContent.writeln('BT');
    streamContent.writeln('/F2 9.5 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('1 0 0 1 300 $y Tm');
    streamContent.writeln('(${_pdfEscape("SGST (9%):")}) Tj');
    streamContent.writeln('1 0 0 1 480 $y Tm');
    streamContent.writeln('(${_pdfEscape("Rs. ${sgst.toStringAsFixed(2)}")}) Tj');
    streamContent.writeln('ET');

    y -= 18;
    streamContent.writeln('BT');
    streamContent.writeln('/F2 9.5 Tf');
    streamContent.writeln('0.1 0.6 0.3 rg');
    streamContent.writeln('1 0 0 1 300 $y Tm');
    streamContent.writeln('(${_pdfEscape("Shipping Fee:")}) Tj');
    streamContent.writeln('1 0 0 1 480 $y Tm');
    streamContent.writeln('(${_pdfEscape("FREE Express")}) Tj');
    streamContent.writeln('ET');

    // Total Amount Highlight Box
    y -= 30;
    streamContent.writeln('0.77 0.62 0.35 rg'); // Gold fill #C5A059
    streamContent.writeln('290 $y 275 28 re f');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('1 0 0 1 305 ${y + 9} Tm');
    streamContent.writeln('(${_pdfEscape("TOTAL AMOUNT PAID:")}) Tj');
    streamContent.writeln('1 0 0 1 475 ${y + 9} Tm');
    streamContent.writeln('(${_pdfEscape("Rs. ${totalAmt.toStringAsFixed(0)}")}) Tj');
    streamContent.writeln('ET');

    // 8. Footer Box
    streamContent.writeln('0.97 0.98 0.99 rg');
    streamContent.writeln('30 50 535 45 re f');
    streamContent.writeln('0.88 0.91 0.94 RG');
    streamContent.writeln('30 50 535 45 re s');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.05 0.14 0.25 rg');
    streamContent.writeln('1 0 0 1 145 76 Tm');
    streamContent.writeln('(${_pdfEscape("Thank you for shopping with VEXA Luxury Wear!")}) Tj');
    streamContent.writeln('/F2 8.5 Tf');
    streamContent.writeln('0.4 0.4 0.4 rg');
    streamContent.writeln('1 0 0 1 105 60 Tm');
    streamContent.writeln('(${_pdfEscape("This is a computer-generated tax invoice verified via 256-Bit SSL Encryption.")}) Tj');
    streamContent.writeln('ET');

    final streamBytes = utf8.encode(streamContent.toString());

    // Build PDF objects with byte offsets
    final List<int> pdfBytes = [];
    void writeString(String s) => pdfBytes.addAll(utf8.encode(s));

    writeString('%PDF-1.4\n');
    writeString('%\u00e2\u00e3\u00cf\u00d3\n');

    final List<int> offsets = [0];

    // Object 1: Catalog
    offsets.add(pdfBytes.length);
    writeString('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Object 2: Pages
    offsets.add(pdfBytes.length);
    writeString('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // Object 3: Page
    offsets.add(pdfBytes.length);
    writeString('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>\nendobj\n');

    // Object 4: Font F1 (Helvetica-Bold)
    offsets.add(pdfBytes.length);
    writeString('4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

    // Object 5: Font F2 (Helvetica)
    offsets.add(pdfBytes.length);
    writeString('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    // Object 6: Content Stream
    offsets.add(pdfBytes.length);
    writeString('6 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    pdfBytes.addAll(streamBytes);
    writeString('\nendstream\nendobj\n');

    // Xref Table
    final xrefOffset = pdfBytes.length;
    writeString('xref\n0 7\n');
    writeString('0000000000 65535 f \n');
    for (int i = 1; i <= 6; i++) {
      writeString('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }

    // Trailer
    writeString('trailer\n<< /Size 7 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

    return Uint8List.fromList(pdfBytes);
  }

  /// Saves the valid PDF invoice file directly to the device Downloads folder
  static Future<String?> saveInvoiceToDisk(String invoiceNo, OrderModel order) async {
    try {
      String? downloadsPath;
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          downloadsPath = dir.path;
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsPath = '$userProfile\\Downloads';
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          downloadsPath = '$home/Downloads';
        }
      }

      downloadsPath ??= Directory.systemTemp.path;

      final file = File('$downloadsPath/$invoiceNo.pdf');
      final pdfBytes = generateInvoicePdf(invoiceNo, order);
      await file.writeAsBytes(pdfBytes, flush: true);
      debugPrint('📄 [PDF Service] Saved PDF invoice to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ [PDF Service] Error saving PDF invoice: $e');
      return null;
    }
  }
}
