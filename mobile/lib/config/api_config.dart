import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// PRODUCTION TOGGLE FLAG:
  /// true  => Live Production Server (https://clothing.speshway.site/api) - Works on ANY network (4G, 5G, Cellular Data, Wi-Fi worldwide)
  /// false => Local Development Server (http://192.168.1.31:5000/api or localhost / emulator)
  static const bool isProduction = false;

  static const String productionUrl = 'https://clothing.speshway.site/api';
  static const String localWifiUrl = 'http://192.168.1.31:5000/api';
  static const String _defaultAndroidUrl = 'http://10.0.2.2:5000/api';
  static const String _defaultStandardUrl = productionUrl;

  static String _overrideBaseUrl = '';
  static String _discoveredBaseUrl = '';

  /// Reactive notifier to broadcast server URL updates to all UI components
  static final ValueNotifier<String> baseUrlNotifier = ValueNotifier<String>(
    isProduction ? productionUrl : localWifiUrl,
  );

  static const List<String> defaultCandidates = [
    productionUrl,
    localWifiUrl,
    _defaultAndroidUrl,
    _defaultStandardUrl,
    'http://localhost:5000/api',
    'http://192.168.1.100:5000/api',
    'http://192.168.0.100:5000/api',
  ];

  /// Cleans and normalizes any server input string into a valid API URL endpoint
  static String normalizeUrl(String input) {
    var raw = input.trim();
    if (raw.isEmpty) return productionUrl;

    // Strip trailing slashes
    raw = raw.replaceAll(RegExp(r'/*$'), '');

    // Ensure scheme (http:// or https://)
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }

    // Append default port :5000 if raw has no port and is IP format (e.g. 192.168.x.x)
    final uri = Uri.tryParse(raw);
    if (uri != null && !uri.hasPort) {
      final host = uri.host;
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host) || host == 'localhost') {
        raw = '${uri.scheme}://$host:5000${uri.path}';
      }
    }

    // Ensure /api path suffix
    if (!raw.endsWith('/api') && !raw.contains('/api/')) {
      raw = '$raw/api';
    }

    return raw.replaceAll(RegExp(r'/*$'), '');
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_api_url') ?? '';
      
      // Reset invalid emulator override on real mobile devices
      if (saved.contains('10.0.2.2') && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await prefs.remove('custom_api_url');
        _overrideBaseUrl = '';
      } else if (saved.isNotEmpty) {
        _overrideBaseUrl = normalizeUrl(saved);
      }
    } catch (e) {
      debugPrint('ApiConfig init error: $e');
    }

    _notifyUrlChanged();

    // Discover active backend asynchronously in background without blocking app launch UI
    unawaited(autoDiscoverBackend().catchError((e) {
      debugPrint('Auto discover error: $e');
      return null;
    }));
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (isProduction) {
      return productionUrl;
    }
    if (_discoveredBaseUrl.isNotEmpty) {
      return _discoveredBaseUrl;
    }
    return localWifiUrl;
  }

  static void _notifyUrlChanged() {
    baseUrlNotifier.value = baseUrl;
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final cleanUrl = normalizeUrl(url);
    _overrideBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_url', _overrideBaseUrl);
    _notifyUrlChanged();
  }

  static Future<void> resetToAuto() async {
    _overrideBaseUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_api_url');
    await autoDiscoverBackend();
    _notifyUrlChanged();
  }

  /// Pings a target server URL to test reachability and response latency in milliseconds
  static Future<Map<String, dynamic>> testServerConnection(String rawUrl) async {
    final targetUrl = normalizeUrl(rawUrl);
    final stopwatch = Stopwatch()..start();
    try {
      final healthUri = Uri.parse('$targetUrl/health');
      final res = await http.get(healthUri).timeout(const Duration(seconds: 3));
      stopwatch.stop();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': data['message'] ?? 'Connected successfully (${stopwatch.elapsedMilliseconds}ms)',
          'url': targetUrl,
        };
      }
    } catch (e) {
      stopwatch.stop();
    }
    return {
      'success': false,
      'latencyMs': -1,
      'message': 'Failed to reach server at $targetUrl',
      'url': targetUrl,
    };
  }

  static Future<String?> autoDiscoverBackend() async {
    // 1. Test override if explicitly set by user
    if (_overrideBaseUrl.isNotEmpty) {
      final testResult = await testServerConnection(_overrideBaseUrl);
      if (testResult['success'] == true) {
        _notifyUrlChanged();
        return _overrideBaseUrl;
      }
    }

    // 2. Probe default candidates for live server
    for (final candidate in defaultCandidates) {
      final testResult = await testServerConnection(candidate);
      if (testResult['success'] == true) {
        _discoveredBaseUrl = candidate;
        _notifyUrlChanged();
        return candidate;
      }
    }

    // 3. Default fallback for physical Android / Desktop
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _discoveredBaseUrl = localWifiUrl;
    } else {
      _discoveredBaseUrl = _defaultStandardUrl;
    }
    _notifyUrlChanged();
    return _discoveredBaseUrl;
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/users/login';
  static String get registerUrl => '$baseUrl/users/register';
  static String get forgotPasswordUrl => '$baseUrl/users/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/users/reset-password';
  static String get usersUrl => '$baseUrl/users';

  // Catalog items and health check endpoints
  static String get itemsUrl => '$baseUrl/items';
  static String get healthUrl => '$baseUrl/health';

  // Razorpay payment endpoints
  static String get razorpayCreateOrderUrl => '$baseUrl/payment/create-order';
  static String get razorpayVerifyPaymentUrl => '$baseUrl/payment/verify-payment';
}
