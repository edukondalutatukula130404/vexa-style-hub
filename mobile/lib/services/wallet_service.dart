import 'package:flutter/material.dart';
import 'notification_service.dart';

class WalletService {
  static double _balance = 2500.0;
  static final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Wallet Top-up via GPay UPI',
      'sub': '22 Sep 2026 · 10:45 AM',
      'amount': '+₹2,000',
      'isCredit': true,
    },
    {
      'title': 'Cashback Reward #VEXA-8942',
      'sub': '18 Sep 2026 · 04:20 PM',
      'amount': '+₹500',
      'isCredit': true,
    },
  ];

  static final List<VoidCallback> _listeners = [];

  static double get balance => _balance;
  static List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);

  static void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  static void addBalance(double amount, {required String title, required String sub, bool isCredit = true}) {
    if (isCredit) {
      _balance += amount;
    } else {
      _balance -= amount;
    }
    _transactions.insert(0, {
      'title': title,
      'sub': sub,
      'amount': isCredit ? '+₹${amount.toStringAsFixed(0)}' : '-₹${amount.toStringAsFixed(0)}',
      'isCredit': isCredit,
    });
    notifyListeners();
  }

  /// Process refund directly into VEXA Wallet upon order cancellation
  static void processOrderCancelRefund({
    required String orderId,
    required double amount,
    String? reason,
    BuildContext? context,
  }) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    addBalance(
      amount,
      title: 'Order Refund (#$orderId)',
      sub: '$dateStr · Instant Refund',
      isCredit: true,
    );

    // Notify user about wallet credit
    NotificationService.addNotification(
      title: 'Wallet Refund Credited 💰',
      body: '₹${amount.toStringAsFixed(0)} refunded to your VEXA Wallet for cancelled order $orderId.',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF10B981),
      type: 'WALLET_REFUND',
      data: {'orderId': orderId, 'refundAmount': amount},
      context: context,
    );
  }
}
