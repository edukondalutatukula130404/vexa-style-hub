import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

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

    return OrderModel(
      id: json['id'] ?? (json['_id'] != null ? '#VX-${json['_id'].toString().substring(0, 6).toUpperCase()}' : '#VX-1001'),
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

  static void notifyOrdersChanged() {
    ordersChangeNotifier.value++;
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

          // Merge server orders with local in-memory orders, eliminating duplicates by ID
          final Map<String, OrderModel> merged = {};
          for (var o in _inMemoryOrders) {
            merged[o.id] = o;
          }
          for (var o in serverOrders) {
            merged[o.id] = o;
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

  /// Create and register a new order
  static Future<OrderModel> createOrder({
    required String customerName,
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
    required double totalAmount,
    required String couponApplied,
    required List<OrderItem> items,
    String? email,
  }) async {
    final orderId = '#VX-${(1000 + _inMemoryOrders.length + DateTime.now().millisecond % 8999)}';
    String userEmail = (email != null && email.isNotEmpty) ? email : '';
    if (userEmail.isEmpty) {
      final user = await AuthService.getUser();
      userEmail = user?.email ?? 'admin@vexa.com';
    }

    final newOrder = OrderModel(
      id: orderId,
      customerName: customerName.isNotEmpty ? customerName : 'Valued Customer',
      shippingAddress: shippingAddress.isNotEmpty ? shippingAddress : 'Indiranagar 100ft Road, Bengaluru',
      phone: phone.isNotEmpty ? phone : '+91 98765 43210',
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      couponApplied: couponApplied,
      status: 'Confirmed',
      createdAt: DateTime.now(),
      items: items,
    );

    // Save to local in-memory list immediately at top of list
    _inMemoryOrders.insert(0, newOrder);

    // Notify all listening UI components (My Orders screens, Profile, Home)
    notifyOrdersChanged();

    // Sync to backend asynchronously
    try {
      final body = {
        'userEmail': userEmail,
        'userName': customerName,
        'shippingAddress': shippingAddress,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'couponApplied': couponApplied,
        'items': items.map((i) => i.toJson()).toList(),
      };

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Sync order to backend note: $e');
    }

    return newOrder;
  }

  /// Cancel an order
  static Future<bool> cancelOrder(String orderId, String reason) async {
    for (var order in _inMemoryOrders) {
      if (order.id == orderId) {
        order.status = 'Cancelled';
        order.cancelReason = reason;
        break;
      }
    }

    notifyOrdersChanged();

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
