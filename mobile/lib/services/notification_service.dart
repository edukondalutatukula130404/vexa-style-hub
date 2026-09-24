import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationService {
  /// Global notifier triggered whenever notifications change
  static final ValueNotifier<int> notificationNotifier = ValueNotifier<int>(0);

  /// Central notification list accessible across the app
  static final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'Limited Edition Drop Live! 🚀',
      'body': 'Urban Silhouette 240 GSM Collection is now live. Claim yours before stocks run out.',
      'time': '10m ago',
      'isRead': false,
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFB8860B),
      'type': 'GENERAL',
    },
    {
      'id': '2',
      'title': 'Order Dispatched 📦',
      'body': 'Your order #VX-8834 is out for delivery. Track package in your profile.',
      'time': '2h ago',
      'isRead': false,
      'icon': Icons.local_shipping_outlined,
      'color': const Color(0xFF2563EB),
      'type': 'ORDER_STATUS',
    },
    {
      'id': '3',
      'title': 'VIP Loyalty Access Unlocked 👑',
      'body': 'You earned 150 VEXA Points! Enjoy early preview for next week\'s dropped styles.',
      'time': '1d ago',
      'isRead': false,
      'icon': Icons.workspace_premium_outlined,
      'color': const Color(0xFFD97706),
      'type': 'GENERAL',
    },
  ];

  static int get unreadCount => notifications.where((n) => n['isRead'] == false).length;

  static void notifyListeners() {
    notificationNotifier.value++;
  }

  /// Add a new notification to the app and trigger UI update + optional in-app banner
  static void addNotification({
    required String title,
    required String body,
    IconData icon = Icons.notifications_active_rounded,
    Color color = const Color(0xFFB8860B),
    String type = 'GENERAL',
    Map<String, dynamic>? data,
    BuildContext? context,
  }) {
    // Avoid duplicate notifications with the exact same title & body created within 2 seconds
    final existingIndex = notifications.indexWhere(
      (n) => n['title'] == title && n['body'] == body,
    );
    if (existingIndex != -1 && existingIndex < 2) {
      return;
    }

    final newNotif = {
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'time': 'Just now',
      'isRead': false,
      'icon': icon,
      'color': color,
      'type': type,
      'data': data,
    };

    notifications.insert(0, newNotif);
    notifyListeners();

    if (context != null && context.mounted) {
      showInAppBanner(context, title: title, body: body, icon: icon, color: color);
    }
  }

  /// Mark all notifications as read
  static void markAllAsRead() {
    for (var n in notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }

  /// Clear all notifications
  static void clearAll() {
    notifications.clear();
    notifyListeners();
  }

  /// Mark single notification as read
  static void markAsRead(String id) {
    for (var n in notifications) {
      if (n['id'] == id) {
        n['isRead'] = true;
        break;
      }
    }
    notifyListeners();
  }

  /// Remove single notification
  static void removeNotification(String id) {
    notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }

  /// Display a floating pop-up snackbar banner on the screen
  static void showInAppBanner(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications_active_rounded,
    Color color = const Color(0xFFB8860B),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
