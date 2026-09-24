import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  late OrderModel _currentOrder;
  StreamSubscription? _wsSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subscribe to live WebSocket events to update tracking status in real time
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
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get _currentStepIndex {
    final status = _currentOrder.status.toLowerCase();
    if (status.contains('cancel')) return -1;
    if (status.contains('deliver')) return 4;
    if (status.contains('out for delivery') || status.contains('courier')) return 3;
    if (status.contains('ship') || status.contains('transit')) return 2;
    if (status.contains('qc') || status.contains('prep') || status.contains('process')) return 1;
    return 0; // Order Placed
  }

  String get _expectedDeliveryText {
    final status = _currentOrder.status.toLowerCase();
    if (status.contains('cancel')) return 'Order Cancelled';
    if (status.contains('deliver')) return 'Delivered on ${_currentOrder.formattedDate}';
    if (status.contains('out for delivery')) return 'Arriving Today by 6:00 PM';
    if (status.contains('ship') || status.contains('transit')) return 'Expected Tomorrow by 2:00 PM';
    return 'Expected in 2–3 Business Days';
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _currentOrder.status.toLowerCase().contains('cancel');
    final stepIdx = _currentStepIndex;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(15),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TRACK ORDER ${_currentOrder.id}',
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _textDark,
                  ),
                ),
                const SizedBox(width: 6),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withAlpha(140),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Real-Time Express Logistics Sync',
              style: GoogleFonts.outfit(fontSize: 10, color: _subtext),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: _goldDark, size: 18),
            tooltip: 'Copy Tracking ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _currentOrder.id));
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied Order ID "${_currentOrder.id}" to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _goldDark,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. REALTIME MAP & SHIPMENT OVERVIEW CARD
            _buildRealtimeMapCard(isCancelled, stepIdx),

            const SizedBox(height: 18),

            // 2. COURIER AGENT & OTP VERIFICATION CARD (Only if active & not cancelled)
            if (!isCancelled && stepIdx >= 2) ...[
              _buildDeliveryAgentCard(),
              const SizedBox(height: 18),
            ],

            // 3. 5-STEP INTERACTIVE TIMELINE
            _buildInteractiveTimeline(isCancelled, stepIdx),

            const SizedBox(height: 18),

            // 4. SHIPPING RECIPIENT CARD
            _buildShippingAddressCard(),

            const SizedBox(height: 18),

            // 5. PACKAGED ITEMS PREVIEW
            _buildPackageItemsCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeMapCard(bool isCancelled, int stepIdx) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Dark Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
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
                          color: _gold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _expectedDeliveryText,
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                    color: _currentOrder.statusColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _currentOrder.statusColor.withAlpha(120)),
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
                        _currentOrder.status.toUpperCase(),
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
          ),

          // Simulated Animated Map Graphic Canvas
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Stack(
              children: [
                // Grid line background decoration
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPatternPainter(),
                  ),
                ),

                // Animated GPS Route Path Line
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Track Line
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Progress Line
                        FractionallySizedBox(
                          widthFactor: isCancelled ? 0.0 : ((stepIdx + 1) / 5).clamp(0.2, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_goldDark, _gold, Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withAlpha(160),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Route Nodes: Warehouse -> Hub -> Courier Van -> Destination
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMapNodeIcon(Icons.storefront_rounded, 'Warehouse', stepIdx >= 0),
                            _buildMapNodeIcon(Icons.inventory_2_rounded, 'QC Hub', stepIdx >= 1),
                            _buildMapNodeIcon(Icons.local_shipping_rounded, 'Express Van', stepIdx >= 2, isActiveNode: stepIdx == 2 || stepIdx == 3),
                            _buildMapNodeIcon(Icons.home_rounded, 'Your Home', stepIdx == 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Live Live GPS Badge
                Positioned(
                  bottom: 10,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          isCancelled
                              ? 'Shipment Cancelled'
                              : (stepIdx == 4 ? 'Package Delivered' : 'Live GPS Sync Active • Waybill #BD-98402'),
                          style: GoogleFonts.outfit(fontSize: 9.5, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
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
          width: isActiveNode ? 36 : 28,
          height: isActiveNode ? 36 : 28,
          decoration: BoxDecoration(
            color: isReached ? (isActiveNode ? _gold : const Color(0xFF10B981)) : const Color(0xFF334155),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActiveNode ? Colors.white : Colors.white.withAlpha(40),
              width: isActiveNode ? 2.0 : 1.0,
            ),
            boxShadow: isActiveNode
                ? [BoxShadow(color: _gold.withAlpha(180), blurRadius: 10)]
                : null,
          ),
          child: Icon(
            icon,
            size: isActiveNode ? 18 : 14,
            color: isReached ? Colors.white : Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 8.5,
            fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
            color: isReached ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAgentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withAlpha(30),
              border: Border.all(color: _gold, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person_pin_rounded, color: _goldDark, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Vikram Singh',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
                          const SizedBox(width: 2),
                          Text('4.9', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'VEXA Priority Logistics Partner',
                  style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Delivery OTP: ',
                      style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _gold.withAlpha(80)),
                      ),
                      child: Text(
                        '4892',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withAlpha(25),
              side: const BorderSide(color: Color(0xFF10B981)),
            ),
            icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling Delivery Agent Vikram Singh (+91 98765 12345)...'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTimeline(bool isCancelled, int stepIdx) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                'SHIPMENT TIMELINE',
                style: GoogleFonts.cinzel(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                isCancelled ? 'Cancelled' : '${stepIdx + 1} of 5 Completed',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? const Color(0xFFEF4444) : _goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 14),

          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Cancelled', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                        const SizedBox(height: 2),
                        Text(
                          _currentOrder.cancelReason ?? 'Cancelled per user request. Refund initiated to source.',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTimelineStep(
              stepNumber: '1',
              title: 'Order Placed & Confirmed',
              subtitle: 'Order ID ${_currentOrder.id} registered in VEXA system',
              timeText: _currentOrder.formattedDate,
              isDone: stepIdx >= 0,
              isActive: stepIdx == 0,
              isLast: false,
            ),
            _buildTimelineStep(
              stepNumber: '2',
              title: 'Garment QC & Custom Packaging',
              subtitle: 'Combed bio-wash inspection passed at Bengaluru hub',
              timeText: stepIdx >= 1 ? 'Inspection Completed' : 'Pending Warehouse Prep',
              isDone: stepIdx >= 1,
              isActive: stepIdx == 1,
              isLast: false,
            ),
            _buildTimelineStep(
              stepNumber: '3',
              title: 'Dispatched via Express Courier',
              subtitle: 'Handed to BlueDart Express • Waybill #BD-98402',
              timeText: stepIdx >= 2 ? 'In Transit' : 'Scheduled',
              isDone: stepIdx >= 2,
              isActive: stepIdx == 2,
              isLast: false,
            ),
            _buildTimelineStep(
              stepNumber: '4',
              title: 'Out for Delivery',
              subtitle: 'Courier executive Vikram Singh assigned for final mile',
              timeText: stepIdx >= 3 ? 'Out for Delivery' : 'Scheduled',
              isDone: stepIdx >= 3,
              isActive: stepIdx == 3,
              isLast: false,
            ),
            _buildTimelineStep(
              stepNumber: '5',
              title: 'Delivered to Recipient',
              subtitle: 'Package signed & delivered to ${_currentOrder.customerName}',
              timeText: stepIdx == 4 ? _currentOrder.formattedDate : 'Pending',
              isDone: stepIdx == 4,
              isActive: stepIdx == 4,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required String timeText,
    required bool isDone,
    required bool isActive,
    required bool isLast,
  }) {
    final stepColor = isDone ? (isActive ? _goldDark : const Color(0xFF10B981)) : _subtext.withAlpha(100);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone ? stepColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 2),
                  boxShadow: isActive
                      ? [BoxShadow(color: stepColor.withAlpha(120), blurRadius: 8)]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(stepNumber, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: stepColor)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? const Color(0xFF10B981) : _border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                            color: isDone ? _textDark : _subtext,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                          color: isDone ? _goldDark : _subtext,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _gold.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded, color: _goldDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY DESTINATION',
                  style: GoogleFonts.cinzel(fontSize: 10.5, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentOrder.customerName,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentOrder.shippingAddress,
                  style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.35),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 12, color: _goldDark),
                    const SizedBox(width: 4),
                    Text(
                      _currentOrder.phone,
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: _textDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PACKAGE CONTENTS (${_currentOrder.items.length})',
                style: GoogleFonts.cinzel(fontSize: 11.5, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
              ),
              Text(
                'Total ₹${_currentOrder.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: _goldDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._currentOrder.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.image.startsWith('assets/')
                        ? Image.asset(item.image, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 44, height: 44, color: Colors.white, child: const Icon(Icons.checkroom)))
                        : Image.network(item.image, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 44, height: 44, color: Colors.white, child: const Icon(Icons.checkroom))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Size ${item.size} • Qty ${item.quantity}',
                          style: GoogleFonts.outfit(fontSize: 10.5, color: _subtext),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: _goldDark),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
