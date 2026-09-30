import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import 'order_tracking_screen.dart';
import 'customer_support_screen.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);
const Color _errorRed = Color(0xFFEF4444);

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onRefreshParent;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.onRefreshParent,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    // Subscribe to live WebSocket updates
    _wsSub = VexaWebSocketService().stream.listen((event) {
      if (mounted) {
        final type = event['type'];
        final data = event['data'];
        if (type == 'ORDER_STATUS_UPDATED' || type == 'ORDERS_UPDATED') {
          if (data != null && data is Map) {
            final orderId = (data['_id'] ?? data['id'] ?? '').toString();
            final cleanCurrent = _currentOrder.id.replaceAll('#', '').toLowerCase().trim();
            final cleanEvent = orderId.replaceAll('#', '').toLowerCase().trim();

            if (cleanCurrent == cleanEvent || cleanCurrent.endsWith(cleanEvent) || cleanEvent.endsWith(cleanCurrent)) {
              final newStatus = (data['status'] ?? '').toString();
              final cancelReason = data['cancelReason']?.toString();
              setState(() {
                _currentOrder.status = newStatus;
                if (cancelReason != null) _currentOrder.cancelReason = cancelReason;
              });
              if (widget.onRefreshParent != null) widget.onRefreshParent!();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<String?> _saveInvoiceFileToDisk(String invoiceNo, OrderModel order) async {
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
      final content = '''
============================================================
                  VEXA LUXURY WEAR - TAX E-INVOICE
                   Vexa Style Hub Pvt. Ltd.
        100ft Road, Indiranagar, Bengaluru - 560038
         GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC
============================================================

INVOICE NO   : $invoiceNo
DATE         : ${order.formattedDate}
ORDER ID     : ${order.id}
PAYMENT      : ${order.paymentMethod}
STATUS       : PAID

BILLED TO:
Name    : ${order.customerName}
Address : ${order.shippingAddress}
Phone   : ${order.phone}

------------------------------------------------------------
ITEMS PURCHASED:
------------------------------------------------------------
${order.items.map((i) => '${i.name.padRight(28)} Size:${i.size} Qty:${i.quantity} Price:₹${i.price} Total:₹${(i.price * i.quantity).toStringAsFixed(0)}').join('\n')}

------------------------------------------------------------
TAX BREAKDOWN:
Subtotal (Taxable Value) : ₹${(order.totalAmount / 1.18).toStringAsFixed(2)}
CGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
SGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
------------------------------------------------------------
TOTAL AMOUNT PAID        : ₹${order.totalAmount.toStringAsFixed(0)}
============================================================
      Thank you for shopping with VEXA Luxury Wear!
============================================================
''';

      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error saving invoice file: $e');
      return null;
    }
  }

  void _showInvoiceModal(BuildContext context, OrderModel order, {bool autoStartDownload = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          bool isDownloading = false;
          bool isDownloaded = false;
          bool hasAutoTriggered = false;

          return StatefulBuilder(
            builder: (modalCtx, setInvoiceState) {
              final invoiceNo = 'INV-2026-${order.id.replaceAll('#', '').replaceAll('-', '')}';
              final totalAmt = order.totalAmount > 0 ? order.totalAmount : 1699.0;
              final subtotal = totalAmt / 1.18;
              final gstTotal = totalAmt - subtotal;
              final cgst = gstTotal / 2;
              final sgst = gstTotal / 2;

              void triggerDownload() async {
                if (isDownloading || isDownloaded) return;
                setInvoiceState(() => isDownloading = true);

                final savedPath = await _saveInvoiceFileToDisk(invoiceNo, order);

                if (modalCtx.mounted) {
                  setInvoiceState(() {
                    isDownloading = false;
                    isDownloaded = true;
                  });

                  ScaffoldMessenger.of(modalCtx).clearSnackBars();
                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              savedPath != null
                                  ? 'Saved $invoiceNo.pdf to Downloads!'
                                  : 'Tax E-Invoice $invoiceNo downloaded & saved!',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  await Future.delayed(const Duration(seconds: 2));
                  if (modalCtx.mounted) {
                    setInvoiceState(() {
                      isDownloaded = false;
                    });
                  }
                }
              }

              if (autoStartDownload && !hasAutoTriggered && !isDownloaded && !isDownloading) {
                hasAutoTriggered = true;
                Future.microtask(() => triggerDownload());
              }

              return Scaffold(
                backgroundColor: _bgColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                  titleSpacing: 0,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: _gold.withAlpha(50), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: _gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAX E-INVOICE', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          Text(invoiceNo, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VEXA LUXURY WEAR', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w900, color: _goldDark, letterSpacing: 1.5)),
                                      const SizedBox(height: 2),
                                      Text('Vexa Style Hub Pvt. Ltd.', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                      Text('100ft Road, Indiranagar, Bengaluru - 560038', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                      Text('GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                                    ),
                                    child: Text('PAID', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('BILLED TO:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Text(order.customerName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text(order.shippingAddress, style: GoogleFonts.outfit(fontSize: 11, color: _subtext, height: 1.3)),
                                        Text('Contact: ${order.phone}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('INVOICE DETAILS:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text('Date: ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      Text('Order ID: ${order.id}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark)),
                                      Text('Payment: ${order.paymentMethod}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Expanded(flex: 4, child: Text('ITEM DESCRIPTION', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              ...order.items.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.8))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                            Text('Size: ${item.size} · Color: ${item.color} | HSN: 610910', style: GoogleFonts.outfit(fontSize: 9, color: _subtext)),
                                          ],
                                        ),
                                      ),
                                      Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${item.price.toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark))),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Taxable Value', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('CGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${cgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('SGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${sgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const Divider(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('GRAND TOTAL (INCL. GST)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text('₹${totalAmt.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: _goldDark)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, size: 40, color: _textDark),
                                      const SizedBox(width: 8),
                                      Text('Scan QR for Digital\nE-Invoice Verification', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, height: 1.2)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('For VEXA STYLE HUB PVT LTD', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _textDark)),
                                      const SizedBox(height: 16),
                                      Text('Authorized Signatory', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: isDownloaded
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Invoice Saved to Downloads ($invoiceNo.pdf)',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: triggerDownload,
                                icon: const Icon(Icons.download_rounded, color: Colors.white),
                                label: Text(
                                  isDownloading ? 'GENERATING E-INVOICE PDF...' : 'DOWNLOAD & SAVE INVOICE PDF',
                                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order #${_currentOrder.id}?', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
        content: Text(
          'Are you sure you want to cancel this order? Instant refund will be processed to your original payment method.',
          style: GoogleFonts.outfit(fontSize: 13, color: _subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Keep Order', style: GoogleFonts.outfit(color: _subtext, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await OrderService.cancelOrder(_currentOrder.id, 'Cancelled by customer via app', context: context, targetOrder: _currentOrder);
              if (success) {
                setState(() {
                  _currentOrder.status = 'Cancelled';
                  _currentOrder.cancelReason = 'Cancelled by customer via app';
                });
                OrderService.notifyOrdersChanged();
                if (widget.onRefreshParent != null) widget.onRefreshParent!();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Order #${_currentOrder.id} cancelled successfully.'),
                    backgroundColor: _errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Confirm Cancel', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _currentOrder.status.toLowerCase() == 'cancelled';
    final isDelivered = _currentOrder.status.toLowerCase() == 'delivered';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ORDER ${_currentOrder.id}',
                          style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _currentOrder.statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _currentOrder.statusColor.withAlpha(90)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5, decoration: BoxDecoration(color: _currentOrder.statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              _currentOrder.status.toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: _currentOrder.statusColor, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: _subtext),
                      const SizedBox(width: 4),
                      Text('Placed on ${_currentOrder.formattedDate}', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: _goldDark, size: 22),
            tooltip: 'Download Invoice',
            onPressed: () => _showInvoiceModal(context, _currentOrder, autoStartDownload: true),
          ),
          IconButton(
            icon: const Icon(Icons.alt_route_rounded, color: _goldDark, size: 20),
            tooltip: 'Track Package',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: _currentOrder)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          // 1. CANCELLATION BANNER (If Cancelled)
          if (isCancelled) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _errorRed.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _errorRed.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: _errorRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Cancelled',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _errorRed),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentOrder.cancelReason ?? 'Cancelled per user request. Refund initiated.',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 2. SHIPPING ADDRESS BLOCK
          Text('SHIPPING ADDRESS', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _gold.withAlpha(20), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded, color: _goldDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentOrder.customerName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 3),
                      Text(_currentOrder.shippingAddress, style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.35)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: _goldDark),
                          const SizedBox(width: 5),
                          Text(_currentOrder.phone, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. ITEMS IN ORDER SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ITEMS IN ORDER (${_currentOrder.items.length})', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
              Text('${_currentOrder.items.fold(0, (sum, i) => sum + i.quantity)} total pcs', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
            ],
          ),
          const SizedBox(height: 8),
          ..._currentOrder.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(3), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: _border)),
                      child: item.image.startsWith('assets/')
                          ? Image.asset(item.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom)))
                          : Image.network(item.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(6)),
                              child: Text('Size ${item.size}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: _textDark)),
                            ),
                            const SizedBox(width: 6),
                            Text('Qty: ${item.quantity}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _goldDark)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // 4. PAYMENT & RECEIPT SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment_rounded, size: 16, color: _subtext),
                        const SizedBox(width: 6),
                        Text('Payment Method', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                        child: Text(
                          _currentOrder.paymentMethod,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text('Shipping Fee', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                      ],
                    ),
                    Text('FREE Express', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _border),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount Paid', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _goldDark,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: _goldDark.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Text('₹${_currentOrder.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (!isCancelled && !isDelivered) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _errorRed),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirmCancelOrder,
                        icon: const Icon(Icons.cancel_outlined, color: _errorRed, size: 18),
                        label: Text(
                          'Cancel Order',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _errorRed),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: widget.order)),
                        );
                      },
                      icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                      label: Text(
                        'Track Order',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerSupportScreen(order: widget.order)),
                    );
                  },
                  icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF10B981), size: 18),
                  label: Text(
                    'Customer Support',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
