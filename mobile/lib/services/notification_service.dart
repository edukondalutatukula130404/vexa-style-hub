import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAYcJD2bB-2M8Hsk8DgL_MswLbvoPouRBU',
      appId: '1:141733607007:android:75805444471b582a3e0dea',
      messagingSenderId: '141733607007',
      projectId: 'vexa-c0fc4',
      storageBucket: 'vexa-c0fc4.firebasestorage.app',
    ),
  );
  debugPrint("Handling a background FCM message: ${message.messageId}");
}

class NotificationService {
  /// Global notifier triggered whenever notifications change
  static final ValueNotifier<int> notificationNotifier = ValueNotifier<int>(0);

  /// Stream controller for user notification tap events
  static final StreamController<String> onNotificationTap = StreamController<String>.broadcast();

  /// Flutter Local Notifications Plugin instance
  static final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  /// FCM Token store
  static String? fcmToken;

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

  /// Initialize Firebase Messaging & Local Notifications for Mobile
  static Future<void> initializeFirebaseMessaging() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAYcJD2bB-2M8Hsk8DgL_MswLbvoPouRBU',
          appId: '1:141733607007:android:75805444471b582a3e0dea',
          messagingSenderId: '141733607007',
          projectId: 'vexa-c0fc4',
          storageBucket: 'vexa-c0fc4.firebasestorage.app',
        ),
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permissions (iOS & Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // Set up Flutter Local Notifications for Android Foreground Banners
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local Notification Tapped! Payload: ${response.payload}');
          onNotificationTap.add(response.payload ?? 'OPEN_NOTIFICATIONS');
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for VEXA Push Notifications.',
        importance: Importance.high,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Get FCM Token
      fcmToken = await messaging.getToken();
      debugPrint('FCM Mobile Token: $fcmToken');

      messaging.onTokenRefresh.listen((token) {
        fcmToken = token;
        debugPrint('FCM Mobile Token Refreshed: $token');
      });

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null) {
          addNotification(
            title: notification.title ?? 'VEXA Alert',
            body: notification.body ?? '',
            type: message.data['type']?.toString() ?? 'PUSH',
            data: message.data,
          );

          if (android != null) {
            localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      });

      // Handle message tap from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null) {
          addNotification(
            title: message.notification!.title ?? 'VEXA Alert',
            body: message.notification!.body ?? '',
            type: message.data['type']?.toString() ?? 'PUSH',
            data: message.data,
          );
        }
        onNotificationTap.add('OPEN_NOTIFICATIONS');
      });

      // Handle initial message from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.notification != null) {
        addNotification(
          title: initialMessage.notification!.title ?? 'VEXA Alert',
          body: initialMessage.notification!.body ?? '',
          type: initialMessage.data['type']?.toString() ?? 'PUSH',
          data: initialMessage.data,
        );
        onNotificationTap.add('OPEN_NOTIFICATIONS');
      }
    } catch (e) {
      debugPrint('Firebase Messaging initialization error: $e');
    }
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
    // 1. Deduplicate by orderId if present
    final orderId = data?['orderId'] ?? data?['_id'] ?? data?['id'];
    if (orderId != null && orderId.toString().isNotEmpty) {
      final isDuplicate = notifications.any((n) {
        final nOrderId = n['data']?['orderId'] ?? n['data']?['_id'] ?? n['data']?['id'];
        if (nOrderId != null && nOrderId.toString() == orderId.toString() && (n['type'] == 'ORDER_PLACED' || n['type'] == type)) {
          return true;
        }
        if (n['type'] == 'ORDER_PLACED' && (n['body'].toString().contains(orderId.toString()) || n['title'] == title)) {
          return true;
        }
        return false;
      });
      if (isDuplicate) return;
    }

    // 2. Avoid duplicate notifications with the exact same title & body created recently
    final existingIndex = notifications.indexWhere(
      (n) => n['title'] == title && (n['body'] == body || n['type'] == type),
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

    // Trigger system notification banner
    try {
      localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for VEXA Push Notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error triggering local notification banner: $e');
    }

    if (context != null && context.mounted) {
      showInAppBanner(context, title: title, body: body, icon: icon, color: color);
    }
  }

  /// Send a test push notification to verify push notifications on mobile
  static void sendTestNotification({BuildContext? context}) {
    addNotification(
      title: '⚡ VEXA Push Notification',
      body: 'Push notifications are working perfectly on your mobile device!',
      type: 'TEST_PUSH',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFB8860B),
      context: context,
    );
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
