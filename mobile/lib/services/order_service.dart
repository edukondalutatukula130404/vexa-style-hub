import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'websocket_service.dart';

class OrderItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String color;
  final String size;
  final String image;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.color,
    required this.size,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['itemId'] ?? json['id'] ?? '',
      name: json['name'] ?? 'VEXA Product',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      quantity: json['quantity'] ?? 1,
      color: json['color'] ?? 'Standard',
      size: json['size'] ?? 'M',
      image: json['image'] ?? 'assets/images/hero_luxury_tshirt.png',
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'color': color,
        'size': size,
        'image': image,
      };
}

class OrderModel {
  final String id;
  final String customerName;
  final String shippingAddress;
  final String phone;
  final String paymentMethod;
  final double totalAmount;
  final String couponApplied;
  String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  String? cancelReason;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.shippingAddress,
    required this.phone,
    required this.paymentMethod,
    required this.totalAmount,
    this.couponApplied = '',
    required this.status,
    required this.createdAt,
    required this.items,
    this.cancelReason,
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'shipped':
      case 'out for delivery':
        return const Color(0xFFD4AF37);
      case 'processing':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFD4AF37);
    }
  }

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[createdAt.month - 1];
    final year = createdAt.year;
    final hour = createdAt.hour > 12 ? createdAt.hour - 12 : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $ampm';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItem> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList();
    }

    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final String parsedId = (json['id'] != null && json['id'].toString().isNotEmpty)
        ? json['id'].toString()
        : (json['_id'] != null
            ? (json['_id'].toString().startsWith('#')
                ? json['_id'].toString()
                : '#VX-${json['_id'].toString().substring(0, json['_id'].toString().length > 6 ? 6 : json['_id'].toString().length).toUpperCase()}')
            : '#VX-1001');

    return OrderModel(
      id: parsedId,
      customerName: json['userName'] ?? json['customer'] ?? 'Valued Customer',
      shippingAddress: json['shippingAddress'] ?? json['address'] ?? 'Indiranagar 100ft Road, Bengaluru',
      phone: json['phone'] ?? '+91 98765 43210',
      paymentMethod: json['paymentMethod'] ?? 'Razorpay UPI',
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      couponApplied: json['couponApplied'] ?? '',
      status: json['status'] ?? 'Processing',
      createdAt: parsedDate,
      items: itemsList,
      cancelReason: json['cancelReason'],
    );
  }
}

class OrderService {
  /// Notifier triggered whenever orders are created, updated, or cancelled
  static final ValueNotifier<int> ordersChangeNotifier = ValueNotifier<int>(0);
  static Timer? _pollingTimer;

  static void notifyOrdersChanged() {
    ordersChangeNotifier.value++;
  }

  /// Automatic periodic polling disabled to prevent unnecessary screen refreshing; real-time events handled via WebSocket.
  static void startAutoPoll({String? email}) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  static void stopAutoPoll() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Update order status locally in memory and notify listeners
  static void updateOrderStatusLocally(
    String orderId,
    String newStatus, {
    String? cancelReason,
    BuildContext? context,
  }) {
    final cleanTarget = orderId.replaceAll('#', '').toLowerCase().trim();

    for (var order in _inMemoryOrders) {
      final cleanOrd = order.id.replaceAll('#', '').toLowerCase().trim();
      if (order.id == orderId ||
          cleanOrd == cleanTarget ||
          (cleanTarget.length >= 4 && cleanOrd.contains(cleanTarget)) ||
          (cleanOrd.length >= 4 && cleanTarget.contains(cleanOrd)) ||
          cleanOrd.endsWith(cleanTarget) ||
          cleanTarget.endsWith(cleanOrd)) {
        order.status = newStatus;
        if (cancelReason != null && cancelReason.isNotEmpty) {
          order.cancelReason = cancelReason;
        }
      }
    }

    final isCancelled = newStatus.toLowerCase() == 'cancelled';
    NotificationService.addNotification(
      title: isCancelled ? 'Order Cancelled ❌' : 'Order Status Update 🚚',
      body: isCancelled
          ? 'Order $orderId has been cancelled.${cancelReason != null && cancelReason.isNotEmpty ? " Reason: $cancelReason" : ""}'
          : 'Order $orderId status changed to "$newStatus"${cancelReason != null && cancelReason.isNotEmpty ? " ($cancelReason)" : ""}.',
      icon: isCancelled ? Icons.cancel_rounded : Icons.local_shipping_rounded,
      color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
      type: isCancelled ? 'ORDER_CANCELLED' : 'ORDER_STATUS_UPDATED',
      data: {'orderId': orderId, 'status': newStatus, 'cancelReason': cancelReason},
      context: context,
    );

    notifyOrdersChanged();
  }

  static final List<OrderModel> _inMemoryOrders = [
    OrderModel(
      id: '#VX-8834',
      customerName: 'Aarav Sharma',
      shippingAddress: 'Flat 402, Royal Residency, Indiranagar, Bengaluru - 560038',
      phone: '+91 98765 43210',
      paymentMethod: 'Razorpay UPI (GPay)',
      totalAmount: 2499.0,
      status: 'Out for Delivery',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      items: [
        OrderItem(
          itemId: 'vx-08',
          name: 'Emerald Acid Wash Boxy Tee',
          price: 1899.0,
          quantity: 1,
          color: 'Emerald Green',
          size: 'L',
          image: 'assets/images/tee-emerald.png',
        ),
      ],
    ),
    OrderModel(
      id: '#VX-7412',
      customerName: 'Aarav Sharma',
      shippingAddress: 'Flat 402, Royal Residency, Indiranagar, Bengaluru - 560038',
      phone: '+91 98765 43210',
      paymentMethod: 'Credit Card (HDFC **** 4819)',
      totalAmount: 3899.0,
      status: 'Delivered',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      items: [
        OrderItem(
          itemId: 'vx-00',
          name: 'Gold-Embroidered Luxe Tee',
          price: 1799.0,
          quantity: 2,
          color: 'Luxury Cream & Gold',
          size: 'XL',
          image: 'assets/images/hero_luxury_tshirt.png',
        ),
      ],
    ),
  ];

  /// Retrieve all user orders (combining in-memory + backend API if accessible)
  static Future<List<OrderModel>> getOrders({String? email}) async {
    try {
      String userEmail = (email != null && email.isNotEmpty) ? email : '';
      if (userEmail.isEmpty) {
        final user = await AuthService.getUser();
        userEmail = user?.email ?? 'admin@vexa.com';
      }

      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/orders/myorders?email=$userEmail'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List serverData = body['data'];
          final serverOrders = serverData.map((j) => OrderModel.fromJson(j)).toList();

          // Merge server orders with local in-memory orders, matching by ID or details
          final Map<String, OrderModel> merged = {};
          for (var o in _inMemoryOrders) {
            merged[o.id] = o;
          }
          for (var s in serverOrders) {
            final sClean = s.id.replaceAll('#', '').toLowerCase().trim();
            bool matchedInMemory = false;

            for (var mem in _inMemoryOrders) {
              final memClean = mem.id.replaceAll('#', '').toLowerCase().trim();
              if (mem.id == s.id ||
                  memClean == sClean ||
                  (sClean.length >= 4 && memClean.contains(sClean)) ||
                  (memClean.length >= 4 && sClean.contains(memClean)) ||
                  (mem.customerName.toLowerCase() == s.customerName.toLowerCase() && (mem.totalAmount - s.totalAmount).abs() < 1.0)) {
                mem.status = s.status;
                if (s.cancelReason != null && s.cancelReason!.isNotEmpty) {
                  mem.cancelReason = s.cancelReason;
                }
                merged[mem.id] = s;
                matchedInMemory = true;
              }
            }
            if (!matchedInMemory) {
              merged[s.id] = s;
            }
          }

          final result = merged.values.toList();
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return result;
        }
      }
    } catch (_) {
      // Backend unreachable or offline, fallback to in-memory list
    }

    _inMemoryOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(_inMemoryOrders);
  }

  /// Create and register a new order — broadcasts in real-time to Admin Dashboard
  static Future<OrderModel> createOrder({
    required String customerName,
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    required double totalAmount,
    required String couponApplied,
    required List<OrderItem> items,
    String? email,
    BuildContext? context,
  }) async {
    final orderId = '#VX-${(1000 + _inMemoryOrders.length + DateTime.now().millisecond % 8999)}';
    String userEmail = (email != null && email.isNotEmpty) ? email : '';
    if (userEmail.isEmpty) {
      final user = await AuthService.getUser();
      userEmail = user?.email ?? 'mobile@vexa.com';
    }

    final newOrder = OrderModel(
      id: orderId,
      customerName: customerName.isNotEmpty ? customerName : 'Valued Customer',
      shippingAddress: shippingAddress.isNotEmpty ? shippingAddress : 'Indiranagar 100ft Road, Bengaluru',
      phone: phone.isNotEmpty ? phone : '+91 98765 43210',
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      couponApplied: couponApplied,
      status: 'Processing',
      createdAt: DateTime.now(),
      items: items,
    );

    // 1. Save to local in-memory list immediately
    _inMemoryOrders.insert(0, newOrder);

    // 2. Add notification and notify all listening UI components
    NotificationService.addNotification(
      title: 'Order Confirmed! 📦',
      body: 'Your order $orderId for ₹${totalAmount.toStringAsFixed(0)} was placed successfully. Track package in your profile.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF10B981),
      type: 'ORDER_PLACED',
      data: {'orderId': orderId},
      context: (context != null && context.mounted) ? context : null,
    );

    notifyOrdersChanged();

    // 3. Build full order payload for broadcast
    final orderPayload = {
      '_id': orderId,
      'id': orderId,
      'userEmail': userEmail,
      'userName': newOrder.customerName,
      'shippingAddress': newOrder.shippingAddress,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'couponApplied': couponApplied,
      'status': 'Processing',
      'createdAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };

    // 4. PRIMARY PATH: POST to backend REST API
    bool backendSuccess = false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderPayload),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 201 || response.statusCode == 200) {
        backendSuccess = true;
        debugPrint('✅ [OrderService] Order synced to backend — WebSocket broadcast triggered automatically.');
      }
    } catch (e) {
      debugPrint('⚠️ [OrderService] Backend POST failed: $e');
    }

    if (!backendSuccess) {
      debugPrint('⚡ [OrderService] Backend unreachable — sending ORDER_CREATED directly via WebSocket.');
    }
    
    // Always send via WebSocket as extra guarantee
    VexaWebSocketService().send('ORDER_CREATED', orderPayload);
    VexaWebSocketService().send('ORDERS_UPDATED', orderPayload);

    return newOrder;
  }

  /// Cancel an order
  static Future<bool> cancelOrder(String orderId, String reason, {BuildContext? context}) async {
    for (var order in _inMemoryOrders) {
      if (order.id == orderId) {
        order.status = 'Cancelled';
        order.cancelReason = reason;
        break;
      }
    }

    NotificationService.addNotification(
      title: 'Order Cancelled ❌',
      body: 'Order $orderId has been cancelled. Reason: $reason',
      icon: Icons.cancel_rounded,
      color: const Color(0xFFEF4444),
      type: 'ORDER_CANCELLED',
      data: {'orderId': orderId, 'cancelReason': reason},
      context: context,
    );

    notifyOrdersChanged();

    final cancelPayload = {
      '_id': orderId,
      'id': orderId,
      'status': 'Cancelled',
      'cancelReason': reason,
    };

    VexaWebSocketService().send('ORDER_CANCELLED', cancelPayload);
    VexaWebSocketService().send('ORDER_STATUS_UPDATED', cancelPayload);
    VexaWebSocketService().send('ORDERS_UPDATED', cancelPayload);

    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'Cancelled', 'cancelReason': reason}),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    return true;
  }
}
