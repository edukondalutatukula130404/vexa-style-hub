import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import 'order_tracking_screen.dart';
import 'customer_support_screen.dart';
import '../widgets/razorpay_gateway_modal.dart';
import '../services/invoice_pdf_service.dart';

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
  Timer? _pollTimer;
  bool _isRefreshing = false;

  Future<void> _handleManualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _fetchLatestOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Order details refreshed!',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Manual refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    // Fetch latest status immediately
    _fetchLatestOrder();

    // Listen to local OrderService changes
    OrderService.ordersChangeNotifier.addListener(_onOrdersNotifierChanged);

    // Periodic poll every 3 seconds to guarantee real-time sync with admin changes
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchLatestOrder();
      }
    });

    // Subscribe to live WebSocket updates from backend
    _wsSub = VexaWebSocketService().stream.listen((event) {
      if (mounted) {
        final type = event['type'];
        final data = event['data'];
        if (type == 'ORDER_STATUS_UPDATED' || type == 'ORDERS_UPDATED') {
          if (data != null && data is Map) {
            final orderId = (data['_id'] ?? data['id'] ?? '').toString();
            final cleanCurrent = _currentOrder.id.replaceAll('#', '').toLowerCase().trim();
            final cleanEvent = orderId.replaceAll('#', '').toLowerCase().trim();

            final isMatch = cleanCurrent == cleanEvent ||
                (cleanEvent.isNotEmpty && cleanCurrent.endsWith(cleanEvent)) ||
                (cleanCurrent.isNotEmpty && cleanEvent.endsWith(cleanCurrent)) ||
                (cleanEvent.length >= 4 && cleanCurrent.contains(cleanEvent)) ||
                (cleanCurrent.length >= 4 && cleanEvent.contains(cleanCurrent));

            if (isMatch) {
              final newStatus = (data['status'] ?? '').toString();
              final cancelReason = data['cancelReason']?.toString();
              if (newStatus.isNotEmpty) {
                setState(() {
                  _currentOrder.status = newStatus;
                  if (cancelReason != null) _currentOrder.cancelReason = cancelReason;
                });
                OrderService.updateOrderStatusLocally(
                  _currentOrder.id,
                  newStatus,
                  cancelReason: cancelReason,
                  createNotification: false,
                );
                if (widget.onRefreshParent != null) widget.onRefreshParent!();
              }
            }
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrderDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.status != _currentOrder.status || widget.order.id != _currentOrder.id) {
      setState(() {
        _currentOrder = widget.order;
      });
    }
  }

  void _onOrdersNotifierChanged() {
    _fetchLatestOrder();
  }

  Future<void> _fetchLatestOrder() async {
    try {
      final user = await AuthService.getUser();
      final orders = await OrderService.getOrders(email: user?.email);
      final cleanCurrent = _currentOrder.id.replaceAll('#', '').toLowerCase().trim();

      for (final o in orders) {
        final oClean = o.id.replaceAll('#', '').toLowerCase().trim();
        final isMatch = oClean == cleanCurrent ||
            (cleanCurrent.length >= 4 && oClean.endsWith(cleanCurrent)) ||
            (oClean.length >= 4 && cleanCurrent.endsWith(oClean)) ||
            (cleanCurrent.length >= 4 && oClean.contains(cleanCurrent)) ||
            (oClean.length >= 4 && cleanCurrent.contains(oClean));

        if (isMatch) {
          if (mounted) {
            setState(() {
              _currentOrder = o;
            });
            if (widget.onRefreshParent != null) widget.onRefreshParent!();
          }
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    OrderService.ordersChangeNotifier.removeListener(_onOrdersNotifierChanged);
    _wsSub?.cancel();
    super.dispose();
  }

  Future<String?> _saveInvoiceFileToDisk(String invoiceNo, OrderModel order) async {
    return InvoicePdfService.saveInvoiceToDisk(invoiceNo, order);
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
              final itemsSubtotal = order.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
              final subtotal = itemsSubtotal > 0 ? itemsSubtotal : (order.totalAmount > 0 ? order.totalAmount : 1499.0);
              final gstTotal = subtotal * 0.18;
              final cgst = gstTotal / 2;
              final sgst = gstTotal / 2;
              final totalAmt = subtotal + gstTotal;

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

  int get _currentStepIndex {
    final status = _currentOrder.status.toLowerCase().trim();
    if (status.contains('cancel')) return -1;
    if (status == 'delivered' || (status.contains('deliver') && !status.contains('out for delivery'))) {
      return 4;
    }
    if (status.contains('out for delivery') || status.contains('courier')) return 3;
    if (status.contains('ship') || status.contains('transit')) return 2;
    if (status.contains('qc') || status.contains('quality') || status.contains('inspection')) return 1;
    if (status.contains('process') || status.contains('pack')) return 0;
    if (status.contains('confirm') || status.contains('place') || status.contains('pend')) return 0;

    return 0; // Accurately matches initial warehouse/processing status
  }

  String get _deliveryStatusTitle {
    final status = _currentOrder.status.toLowerCase().trim();
    if (status.contains('cancel')) return 'CANCELLED';
    if (status == 'delivered' || (status.contains('deliver') && !status.contains('out for delivery'))) {
      return 'DELIVERED';
    }
    if (status.contains('out for delivery') || status.contains('courier')) {
      return 'OUT FOR DELIVERY';
    }
    if (status.contains('ship') || status.contains('transit')) {
      return 'SHIPPED';
    }
    if (status.contains('qc') || status.contains('quality')) {
      return 'QC INSPECTION';
    }
    if (status.contains('process') || status.contains('pack')) {
      return 'PROCESSING';
    }
    if (status.contains('confirm')) {
      return 'ORDER CONFIRMED';
    }
    if (status.contains('place') || status.contains('pend')) {
      return 'ORDER PLACED';
    }
    return _currentOrder.status.toUpperCase();
  }

  String get _deliverySubtitle {
    final status = _currentOrder.status.toLowerCase().trim();
    if (status.contains('cancel')) return 'Shipment has been cancelled';
    if (status == 'delivered' || (status.contains('deliver') && !status.contains('out for delivery'))) {
      return 'Delivered on ${_currentOrder.formattedDate}';
    }
    if (status.contains('out for delivery') || status.contains('courier')) {
      return 'Arriving Today by 6:00 PM';
    }
    if (status.contains('ship') || status.contains('transit')) {
      return 'In Transit via Express Courier • Arriving in 2–3 Days';
    }
    if (status.contains('qc') || status.contains('quality')) {
      return 'QC Inspection in Progress at Central Hub';
    }
    if (status.contains('process') || status.contains('pack')) {
      return 'Preparing and Packing Garment at Warehouse Studio';
    }
    if (status.contains('confirm')) {
      return 'Order Confirmed • Preparing for Dispatch';
    }
    if (status.contains('place') || status.contains('pend')) {
      return 'Order Placed • Awaiting Warehouse Dispatch';
    }

    return 'Expected in 2–3 Business Days';
  }

  Widget _buildRealtimeMapCard() {
    final isCancelled = _currentOrder.status.toLowerCase().contains('cancel');
    final stepIdx = _currentStepIndex;
    final status = _currentOrder.status.toLowerCase().trim();

    double progressWidthFactor = 0.0;
    if (!isCancelled) {
      if (stepIdx <= 0) {
        progressWidthFactor = 0.12;
      } else if (stepIdx == 1) {
        progressWidthFactor = 0.38;
      } else if (stepIdx == 2) {
        progressWidthFactor = 0.65;
      } else if (stepIdx == 3) {
        progressWidthFactor = 0.88;
      } else {
        progressWidthFactor = 1.0;
      }
    }

    final statusDisplay = _deliveryStatusTitle;

    String gpsText = 'Live GPS Sync Active • Waybill #BD-98402';
    IconData gpsIcon = Icons.my_location_rounded;
    Color gpsColor = const Color(0xFF10B981);

    if (isCancelled) {
      gpsText = 'Order Cancelled';
      gpsIcon = Icons.cancel_outlined;
      gpsColor = _errorRed;
    } else if (status.contains('deliver') && !status.contains('out')) {
      gpsText = 'Package Delivered to Doorstep';
      gpsIcon = Icons.check_circle_outline_rounded;
      gpsColor = const Color(0xFF10B981);
    } else if (status.contains('out for delivery') || status.contains('courier')) {
      gpsText = 'Out for Delivery • Courier Reaching Today';
      gpsIcon = Icons.delivery_dining_rounded;
      gpsColor = const Color(0xFFF59E0B);
    } else if (status.contains('ship') || status.contains('transit')) {
      gpsText = 'Shipped • In Transit via Express Courier (Waybill #BD-98402)';
      gpsIcon = Icons.local_shipping_outlined;
      gpsColor = const Color(0xFF2563EB);
    } else if (status.contains('qc')) {
      gpsText = 'Quality Check Active at QC Hub • Waybill #BD-98402';
      gpsIcon = Icons.inventory_2_outlined;
      gpsColor = _goldDark;
    } else if (status.contains('process') || status.contains('pack')) {
      gpsText = 'Processing • Packing Garment at Warehouse Studio';
      gpsIcon = Icons.storefront_outlined;
      gpsColor = const Color(0xFF3B82F6);
    } else if (status.contains('confirm')) {
      gpsText = 'Order Confirmed • Warehouse Allocation in Progress';
      gpsIcon = Icons.task_alt_rounded;
      gpsColor = const Color(0xFF3B82F6);
    } else {
      gpsText = 'Order Placed • Awaiting Warehouse Processing';
      gpsIcon = Icons.shopping_bag_outlined;
      gpsColor = _goldDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED DELIVERY',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _deliveryStatusTitle,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _deliverySubtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: _subtext,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _currentOrder.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _currentOrder.statusColor.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentOrder.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _currentOrder.statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Route Nodes & Progress Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Base Track Line
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Solid Single Color Progress Line
                FractionallySizedBox(
                  widthFactor: progressWidthFactor,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _goldDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Route Nodes: Warehouse -> QC Hub -> Express Van -> Your Home
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMapNodeIcon(Icons.storefront_rounded, 'Warehouse', stepIdx >= 0 && !isCancelled, isActiveNode: stepIdx == 0 && !isCancelled),
                    _buildMapNodeIcon(Icons.inventory_2_rounded, 'QC Hub', stepIdx >= 1 && !isCancelled, isActiveNode: stepIdx == 1 && !isCancelled),
                    _buildMapNodeIcon(Icons.local_shipping_rounded, 'Express Van', stepIdx >= 2 && !isCancelled, isActiveNode: (stepIdx == 2 || stepIdx == 3) && !isCancelled),
                    _buildMapNodeIcon(Icons.home_rounded, 'Your Home', stepIdx == 4 && !isCancelled, isActiveNode: stepIdx == 4 && !isCancelled),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live Courier & GPS Movement Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: gpsColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gpsColor.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(gpsIcon, color: gpsColor, size: 13),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    gpsText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: gpsColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapNodeIcon(IconData icon, String label, bool isReached, {bool isActiveNode = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActiveNode ? 34 : 26,
          height: isActiveNode ? 34 : 26,
          decoration: BoxDecoration(
            color: isReached ? _goldDark : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isReached ? _goldDark : _border,
              width: isActiveNode ? 2.5 : 1.0,
            ),
            boxShadow: isActiveNode
                ? [BoxShadow(color: _goldDark.withAlpha(100), blurRadius: 8)]
                : null,
          ),
          child: Icon(
            icon,
            size: isActiveNode ? 16 : 13,
            color: isReached ? Colors.white : _subtext,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
            color: isReached ? _textDark : _subtext,
          ),
        ),
      ],
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _gold.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withAlpha(60)),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: _goldDark, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ORDER ${_currentOrder.id}',
                    style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
        actions: [
          if (_currentOrder.isPaid)
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
      body: RefreshIndicator(
        color: _goldDark,
        onRefresh: _handleManualRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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

          // 1.5 ESTIMATED DELIVERY & TRACKING PROGRESS CARD
          _buildRealtimeMapCard(),

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

          // 4. PRICE DETAILS & PAYMENT SUMMARY CARD
          Text('PRICE DETAILS', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final itemsSubtotal = _currentOrder.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
              final baseSubtotal = itemsSubtotal > 0 ? itemsSubtotal : _currentOrder.totalAmount;
              final hasCoupon = _currentOrder.couponApplied.isNotEmpty;
              final discountAmount = hasCoupon ? (baseSubtotal * 0.10) : 0.0;
              final netSubtotal = (baseSubtotal - discountAmount).clamp(0.0, double.infinity);
              final taxAmount = netSubtotal * 0.18;
              final displayTotalAmount = netSubtotal + taxAmount;
              final totalSavings = 150.0 + discountAmount;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Subtotal Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items Subtotal', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                        Text('₹${baseSubtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Discount / Offer Row
                    if (hasCoupon || discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 5),
                              Text(
                                hasCoupon ? 'Discount (${_currentOrder.couponApplied})' : 'Instant Order Discount',
                                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            '-₹${discountAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Shipping Fee Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 15, color: _subtext),
                            const SizedBox(width: 5),
                            Text('Shipping Fee', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('₹150', style: GoogleFonts.outfit(fontSize: 12, color: _subtext, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 6),
                            Text('FREE Express', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Taxes & Duties Row (GST 18% Added)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 15, color: _subtext),
                            const SizedBox(width: 5),
                            Text('Taxes & Duties (GST 18%)', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                          ],
                        ),
                        Text('+₹${taxAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Payment Method Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.credit_card_rounded, size: 15, color: _subtext),
                            const SizedBox(width: 5),
                            Text('Payment Method', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
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

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: _border),
                    ),

                    // Total Amount Paid Row (Base + Tax - Discount)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentOrder.isPaid ? 'Payment Received' : 'Payment Pending',
                              style: GoogleFonts.outfit(fontSize: 11, color: _currentOrder.isPaid ? const Color(0xFF10B981) : const Color(0xFFEAB308), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _goldDark,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: _goldDark.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Text('₹${displayTotalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You saved ₹${totalSavings.toStringAsFixed(0)} on this order with FREE shipping & offers!',
                              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
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
              if (!_currentOrder.isPaid && !isCancelled && !_currentOrder.paymentMethod.toLowerCase().contains('cash') && !_currentOrder.paymentMethod.toLowerCase().contains('cod') && !_currentOrder.paymentMethod.toLowerCase().contains('delivery')) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C2340),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      RazorpayGatewayModal.show(
                        context: context,
                        amount: _currentOrder.totalAmount,
                        customerName: _currentOrder.customerName,
                        customerPhone: _currentOrder.phone,
                        onPaymentSuccess: (methodLabel) {
                          setState(() {
                            _currentOrder.paymentMethod = methodLabel;
                            _currentOrder.status = 'Confirmed';
                          });
                          OrderService.updateOrderStatusLocally(
                            _currentOrder.id,
                            'Confirmed',
                            paymentMethod: methodLabel,
                            context: context,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Payment of ₹${_currentOrder.totalAmount.toStringAsFixed(0)} verified via Razorpay!',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: const Color(0xFF00A859),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded, color: Color(0xFFFFD700), size: 20),
                    label: Text(
                      'Pay Now via Razorpay',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
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
                          MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: _currentOrder)),
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
                      MaterialPageRoute(builder: (_) => CustomerSupportScreen(order: _currentOrder)),
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
