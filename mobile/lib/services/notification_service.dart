import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
      'type': 'order_status_update',
      'data': {'orderId': '#VX-8834'},
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

  /// Register/Sync user FCM token with backend server
  static Future<void> registerFcmTokenWithBackend({String? email, String? token}) async {
    final targetToken = token ?? fcmToken;
    if (targetToken == null || targetToken.trim().isEmpty) return;

    String userEmail = email?.trim() ?? '';
    if (userEmail.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        userEmail = prefs.getString('vexa_user_email') ?? '';
        if (userEmail.isEmpty) {
          final userJson = prefs.getString('auth_user');
          if (userJson != null) {
            final Map<String, dynamic> map = jsonDecode(userJson);
            userEmail = (map['email'] ?? '').toString().trim();
            if (userEmail.isNotEmpty) {
              await prefs.setString('vexa_user_email', userEmail.toLowerCase().trim());
            }
          }
        }
      } catch (_) {}
    }

    if (userEmail.isEmpty) return;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/fcm-token');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': userEmail.toLowerCase().trim(),
          'fcmToken': targetToken.trim()
        }),
      );
      if (res.statusCode == 200) {
        debugPrint('✅ FCM device token synced with backend server for $userEmail');
      }
    } catch (e) {
      debugPrint('FCM token registration note: $e');
    }
  }

  /// Sync notification history from backend for specific logged-in user
  static Future<void> syncRemoteNotifications(String email) async {
    if (email.isEmpty) return;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications?email=${Uri.encodeComponent(email)}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data'] as List?;
        if (list != null && list.isNotEmpty) {
          for (var item in list) {
            final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? 'Order Notification';
            final message = item['message']?.toString() ?? '';
            final status = item['status']?.toString() ?? '';
            final orderId = item['orderId']?.toString() ?? '';
            final isRead = item['read'] == true;

            final exists = notifications.any((n) => n['id'] == id || (n['title'] == title && n['body'] == message));
            if (!exists) {
              notifications.insert(0, {
                'id': id.isNotEmpty ? id : 'notif_${DateTime.now().millisecondsSinceEpoch}',
                'title': title,
                'body': message,
                'time': 'Just now',
                'isRead': isRead,
                'icon': _getIconForStatus(status),
                'color': _getColorForStatus(status),
                'type': item['type']?.toString() ?? 'order_status_update',
                'data': {'orderId': orderId, 'status': status},
              });
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Sync remote notifications note: $e');
    }
  }

  static IconData _getIconForStatus(String status) {
    if (status == 'Shipped' || status == 'Out for Delivery') return Icons.local_shipping_rounded;
    if (status == 'Delivered') return Icons.check_circle_rounded;
    if (status == 'Cancelled') return Icons.cancel_rounded;
    if (status == 'Order Confirmed') return Icons.verified_rounded;
    return Icons.inventory_2_rounded;
  }

  static Color _getColorForStatus(String status) {
    if (status == 'Delivered') return const Color(0xFF10B981);
    if (status == 'Cancelled') return const Color(0xFFEF4444);
    if (status == 'Shipped' || status == 'Out for Delivery') return const Color(0xFF2563EB);
    return const Color(0xFFB8860B);
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

      // Explicitly request Android 13+ runtime local notification permission
      final androidLocalPlugin = localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidLocalPlugin != null) {
        await androidLocalPlugin.requestNotificationsPermission();
      }

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
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidLocalPlugin?.createNotificationChannel(channel);

      // Get FCM Token
      fcmToken = await messaging.getToken();
      debugPrint('FCM Mobile Token: $fcmToken');
      if (fcmToken != null) {
        registerFcmTokenWithBackend(token: fcmToken);
      }

      messaging.onTokenRefresh.listen((token) {
        fcmToken = token;
        debugPrint('FCM Mobile Token Refreshed: $token');
        registerFcmTokenWithBackend(token: token);
      });

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        final data = message.data;

        final title = notification?.title ?? data['title'] ?? 'VEXA Order Update 📦';
        final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
        final status = data['status']?.toString() ?? '';
        final orderId = data['orderId']?.toString() ?? data['id']?.toString() ?? '';

        addNotification(
          title: title,
          body: body,
          type: data['type']?.toString() ?? 'order_status_update',
          icon: _getIconForStatus(status),
          color: _getColorForStatus(status),
          data: data,
        );

        if (android != null || notification != null) {
          localNotifications.show(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: body,
            payload: orderId.isNotEmpty ? orderId : 'OPEN_NOTIFICATIONS',
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        }
      });

      // Handle message tap from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final notification = message.notification;
        final data = message.data;

        final title = notification?.title ?? data['title'] ?? 'VEXA Order Update 📦';
        final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
        final status = data['status']?.toString() ?? '';
        final targetOrderId = data['orderId']?.toString() ?? data['id']?.toString();

        addNotification(
          title: title,
          body: body,
          type: data['type']?.toString() ?? 'order_status_update',
          icon: _getIconForStatus(status),
          color: _getColorForStatus(status),
          data: data,
        );

        onNotificationTap.add(targetOrderId ?? 'OPEN_NOTIFICATIONS');
      });

      // Handle initial message from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        final notification = initialMessage.notification;
        final data = initialMessage.data;

        final title = notification?.title ?? data['title'] ?? 'VEXA Order Update 📦';
        final body = notification?.body ?? data['body'] ?? data['message'] ?? '';
        final status = data['status']?.toString() ?? '';
        final targetOrderId = data['orderId']?.toString() ?? data['id']?.toString();

        addNotification(
          title: title,
          body: body,
          type: data['type']?.toString() ?? 'order_status_update',
          icon: _getIconForStatus(status),
          color: _getColorForStatus(status),
          data: data,
        );

        onNotificationTap.add(targetOrderId ?? 'OPEN_NOTIFICATIONS');
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
    // Avoid duplicate notifications with the exact same title & body created recently
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
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
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
