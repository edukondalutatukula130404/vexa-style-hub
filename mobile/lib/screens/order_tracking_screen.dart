import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import 'customer_support_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _currentOrder;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

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
    super.dispose();
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

  String _formatDateShort(DateTime dt) {
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[dt.weekday - 1];
    final day = dt.day;
    final suffix = (day == 1 || day == 21 || day == 31)
        ? 'st'
        : (day == 2 || day == 22)
            ? 'nd'
            : (day == 3 || day == 23)
                ? 'rd'
                : 'th';
    final month = monthNames[dt.month - 1];
    final yearShort = dt.year.toString().substring(2);
    return '$dayName, $day$suffix $month \'$yearShort';
  }

  String _formatDateTimeShort(DateTime dt) {
    final datePart = _formatDateShort(dt);
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$datePart - $hour:$minute$ampm';
  }

  String get _destinationCity {
    final addr = _currentOrder.shippingAddress.toLowerCase();
    if (addr.contains('hyderabad')) return 'HYDERABAD';
    if (addr.contains('mumbai')) return 'MUMBAI';
    if (addr.contains('bengaluru') || addr.contains('bangalore')) return 'BENGALURU';
    if (addr.contains('delhi')) return 'DELHI';
    if (addr.contains('chennai')) return 'CHENNAI';
    if (addr.contains('pune')) return 'PUNE';
    return 'HYDERABAD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineView(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: SizedBox(
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
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    final stepIdx = _currentStepIndex;
    final isCancelled = _currentOrder.status.toLowerCase().contains('cancel');

    final baseDate = _currentOrder.createdAt;
    final waybillNo = 'VX-EXPRESS-${_currentOrder.id.replaceAll('#', '').replaceAll('-', '').toUpperCase()}657034';
    final city = _destinationCity;

    final confirmedDateStr = _formatDateShort(baseDate);
    final shippedDateStr = _formatDateShort(baseDate.add(const Duration(days: 1)));
    final expectedDeliveryDateStr = _formatDateShort(baseDate.add(const Duration(days: 3)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. ORDER CONFIRMED NODE ──────────────────────────────────────────
        _buildTimelineNode(
          isDone: stepIdx >= 0 && !isCancelled,
          showLineBelow: true,
          lineIsDone: stepIdx >= 1 && !isCancelled,
          title: 'Order Confirmed',
          titleDate: confirmedDateStr,
          children: [
            _buildSubDetailItem(
              title: 'Your Order has been placed.',
              subtitle: _formatDateTimeShort(baseDate),
            ),
            const SizedBox(height: 12),
            _buildSubDetailItem(
              title: 'VEXA Brand Studio has processed your order.',
              subtitle: _formatDateTimeShort(baseDate.add(const Duration(hours: 4))),
            ),
            const SizedBox(height: 12),
            _buildSubDetailItem(
              title: 'Your item has been picked up by VEXA delivery partner.',
              subtitle: _formatDateTimeShort(baseDate.add(const Duration(hours: 12))),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── 2. SHIPPED NODE ──────────────────────────────────────────────────
        _buildTimelineNode(
          isDone: stepIdx >= 2 && !isCancelled,
          showLineBelow: true,
          lineIsDone: stepIdx >= 3 && !isCancelled,
          title: 'Shipped',
          titleDate: shippedDateStr,
          children: [
            Text(
              'VEXA Express Logistics - $waybillNo',
              style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 3),
            Text(
              'Your luxury garment has been shipped.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            Text(
              _formatDateTimeShort(baseDate.add(const Duration(days: 1, hours: 1))),
              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),

            // Nested VEXA Facility Movement Updates
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubDetailItem(
                    title: 'Your item has arrived at VEXA Central Hub',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 1, hours: 1)))} - BENGALURU',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item passed 240 GSM Quality Check',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 1, hours: 3)))} - BENGALURU',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has left VEXA Central Hub',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 1, hours: 11)))} - BENGALURU',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has arrived at VEXA Sorting Hub',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 2, hours: 17)))} - $city',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has left VEXA Sorting Hub',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 3, hours: 2)))} - $city',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has arrived at VEXA Express Facility',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 3, hours: 7)))} - $city',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has departed VEXA Express Facility',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 3, hours: 11)))} - $city',
                  ),
                  const SizedBox(height: 10),
                  _buildSubDetailItem(
                    title: 'Your item has arrived at Local VEXA Hub',
                    subtitle: '${_formatDateTimeShort(baseDate.add(const Duration(days: 3, hours: 14)))} - $city',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'Item yet to reach doorstep delivery agent.',
              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── 3. OUT FOR DELIVERY NODE ─────────────────────────────────────────
        _buildTimelineNode(
          isDone: stepIdx >= 3 && !isCancelled,
          showLineBelow: true,
          lineIsDone: stepIdx >= 4 && !isCancelled,
          title: 'Out For Delivery',
          titleDate: '',
          children: [
            Text(
              stepIdx >= 3 ? 'VEXA priority courier agent out for doorstep delivery.' : 'Item yet to be delivered.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── 4. DELIVERY EXPECTED BY NODE ─────────────────────────────────────
        _buildTimelineNode(
          isDone: stepIdx == 4 && !isCancelled,
          showLineBelow: false,
          lineIsDone: false,
          title: 'Delivery Expected By $expectedDeliveryDateStr',
          titleDate: '',
          children: [
            Text(
              stepIdx == 4 ? 'Package Delivered successfully!' : 'Item yet to be delivered.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            if (stepIdx < 4) ...[
              const SizedBox(height: 2),
              Text(
                'Expected by $expectedDeliveryDateStr',
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode({
    required bool isDone,
    required bool showLineBelow,
    required bool lineIsDone,
    required String title,
    required String titleDate,
    required List<Widget> children,
  }) {
    const greenColor = Color(0xFF16A34A);
    const greyColor = Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Connecting Line Column
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDone ? greenColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? greenColor : greyColor,
                      width: isDone ? 0 : 2,
                    ),
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineIsDone ? greenColor : greyColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (titleDate.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        titleDate,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isDone ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ...children,
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubDetailItem({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}
