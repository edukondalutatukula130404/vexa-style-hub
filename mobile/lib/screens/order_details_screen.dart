import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
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
  Timer? _realtimeTicker;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    // Real-time tracking ticker updates progress in real-time every 2 seconds
    _realtimeTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {});
      }
    });

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
    _realtimeTicker?.cancel();
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

  int get _currentStepIndex {
    final status = _currentOrder.status.toLowerCase();
    if (status.contains('cancel')) return -1;
    if (status.contains('deliver')) return 4;
    if (status.contains('out for delivery') || status.contains('courier')) return 3;
    if (status.contains('ship') || status.contains('transit')) return 2;
    if (status.contains('qc')) return 1;

    // Real-time time progression based on order creation
    final elapsedSeconds = DateTime.now().difference(_currentOrder.createdAt).inSeconds;
    if (elapsedSeconds < 25) {
      return 0; // Warehouse
    } else if (elapsedSeconds < 55) {
      return 1; // QC Hub
    } else if (elapsedSeconds < 110) {
      return 2; // Express Van
    } else if (elapsedSeconds < 180) {
      return 3; // Out for Delivery
    } else {
      return 4; // Delivered
    }
  }

  String get _expectedDeliveryText {
    final status = _currentOrder.status.toLowerCase();
    if (status.contains('cancel')) return 'Order Cancelled';
    if (status.contains('deliver')) return 'Delivered on ${_currentOrder.formattedDate}';

    final stepIdx = _currentStepIndex;
    if (stepIdx == 0) return 'Warehouse Dispatch Pending';
    if (stepIdx == 1) return 'QC Inspection in Progress';
    if (stepIdx == 2) return 'In Transit via Express Courier';
    if (stepIdx == 3) return 'Arriving Today by 6:00 PM';
    if (stepIdx == 4) return 'Delivered on ${_currentOrder.formattedDate}';
    return 'Expected in 2–3 Business Days';
  }

  Widget _buildRealtimeMapCard() {
    final isCancelled = _currentOrder.status.toLowerCase().contains('cancel');
    final stepIdx = _currentStepIndex;

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

    String statusDisplay = _currentOrder.status.toUpperCase();
    if (!isCancelled) {
      if (stepIdx == 0) {
        statusDisplay = 'PROCESSING';
      } else if (stepIdx == 1) {
        statusDisplay = 'QC CHECK ACTIVE';
      } else if (stepIdx == 2) {
        statusDisplay = 'IN TRANSIT';
      } else if (stepIdx == 3) {
        statusDisplay = 'OUT FOR DELIVERY';
      } else if (stepIdx == 4) {
        statusDisplay = 'DELIVERED';
      }
    }

    String gpsText = 'Live GPS Sync Active • Waybill #BD-98402';
    if (isCancelled) {
      gpsText = 'Shipment Cancelled';
    } else if (stepIdx == 0) {
      gpsText = 'Warehouse Dispatch Active • Packing Garment';
    } else if (stepIdx == 1) {
      gpsText = 'Quality Check Active at QC Hub • Waybill #BD-98402';
    } else if (stepIdx == 2) {
      gpsText = 'Live GPS Sync Active • Waybill #BD-98402';
    } else if (stepIdx == 3) {
      gpsText = 'Out for Delivery • Courier Arriving Soon';
    } else if (stepIdx == 4) {
      gpsText = 'Package Delivered';
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
                      _expectedDeliveryText,
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
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
                    _buildMapNodeIcon(Icons.storefront_rounded, 'Warehouse', stepIdx >= 0, isActiveNode: stepIdx == 0),
                    _buildMapNodeIcon(Icons.inventory_2_rounded, 'QC Hub', stepIdx >= 1, isActiveNode: stepIdx == 1),
                    _buildMapNodeIcon(Icons.local_shipping_rounded, 'Express Van', stepIdx >= 2, isActiveNode: stepIdx == 2 || stepIdx == 3),
                    _buildMapNodeIcon(Icons.home_rounded, 'Your Home', stepIdx == 4, isActiveNode: stepIdx == 4),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live GPS Sync Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 12),
                const SizedBox(width: 6),
                Text(
                  gpsText,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
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
              final discountAmount = baseSubtotal > _currentOrder.totalAmount ? (baseSubtotal - _currentOrder.totalAmount) : 0.0;
              final gstIncluded = _currentOrder.totalAmount - (_currentOrder.totalAmount / 1.18);
              final hasCoupon = _currentOrder.couponApplied.isNotEmpty;
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

                    // Taxes & Duties Row
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
                        Text('₹${gstIncluded.toStringAsFixed(0)} (Included)', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
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

                    // Total Amount Paid Row
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
                          child: Text('₹${_currentOrder.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
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
