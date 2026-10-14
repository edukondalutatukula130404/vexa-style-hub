import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// PRODUCTION TOGGLE FLAG:
  /// true  => Run on ANY server / Live Production (https://clothing.speshway.site/api or any custom cloud server)
  ///          Works across any cellular data (4G/5G) and any Wi-Fi network worldwide.
  /// false => Run ONLY in local development (http://192.168.1.6:5000/api, emulator 10.0.2.2, localhost)
  static const bool isProduction = true;

  static const String productionUrl = 'https://clothing.speshway.site/api';
  static const String cloudTunnelUrl = 'https://vexa-style-hub.loca.lt/api';
  static const String localWifiUrl = 'http://192.168.1.6:5000/api';
  static const String _defaultAndroidUrl = 'http://10.0.2.2:5000/api';

  static String _overrideBaseUrl = '';
  static String _discoveredBaseUrl = '';

  /// Reactive notifier to broadcast server URL updates to all UI components
  static final ValueNotifier<String> baseUrlNotifier = ValueNotifier<String>(
    isProduction ? productionUrl : localWifiUrl,
  );

  /// API State Simulator for testing UI states (normal, slow, empty, error, offline)
  static String simulatedState = 'normal';
  static final ValueNotifier<String> simulationNotifier = ValueNotifier<String>(
    'normal',
  );

  static void setSimulatedState(String state) {
    simulatedState = state;
    simulationNotifier.value = state;
  }

  static List<String> get defaultCandidates {
    if (isProduction) {
      final list = <String>[
        productionUrl,
        cloudTunnelUrl,
      ];
      if (_overrideBaseUrl.isNotEmpty) {
        list.insert(0, _overrideBaseUrl);
      }
      return list.toSet().toList();
    }

    // Local development candidates
    final list = <String>[
      localWifiUrl,
      'http://localhost:5000/api',
      _defaultAndroidUrl,
      cloudTunnelUrl,
    ];

    // Expand discovery across local LAN subnets (192.168.1.x, 192.168.0.x, etc.)
    for (final i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 20, 25, 30, 31, 50, 100, 101, 102]) {
      list.add('http://192.168.1.$i:5000/api');
    }
    for (final i in [1, 2, 3, 4, 5, 6, 100]) {
      list.add('http://192.168.0.$i:5000/api');
      list.add('http://192.168.29.$i:5000/api');
      list.add('http://192.168.43.$i:5000/api');
    }
    return list.toSet().toList();
  }

  /// Cleans and normalizes any server input string into a valid API URL endpoint
  static String normalizeUrl(String input) {
    var raw = input.trim();
    if (raw.isEmpty) return isProduction ? productionUrl : localWifiUrl;

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
      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host) ||
          host == 'localhost') {
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

      // Reset invalid emulator override on physical Android
      if (saved.contains('10.0.2.2') &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
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
    unawaited(
      autoDiscoverBackend().catchError((e) {
        debugPrint('Auto discover error: $e');
        return null;
      }),
    );
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (_discoveredBaseUrl.isNotEmpty) {
      return _discoveredBaseUrl;
    }
    return isProduction ? productionUrl : localWifiUrl;
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
    _discoveredBaseUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_api_url');
    await autoDiscoverBackend();
    _notifyUrlChanged();
  }

  /// Pings a target server URL to test reachability and response latency in milliseconds
  static Future<Map<String, dynamic>> testServerConnection(
    String rawUrl, {
    int timeoutMs = 2500,
  }) async {
    final targetUrl = normalizeUrl(rawUrl);
    final stopwatch = Stopwatch()..start();
    try {
      final healthUri = Uri.parse('$targetUrl/health');
      final res = await http.get(healthUri).timeout(Duration(milliseconds: timeoutMs));
      stopwatch.stop();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message':
              data['message'] ??
              'Connected successfully (${stopwatch.elapsedMilliseconds}ms)',
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
    // 1. Test override if explicitly set by user (allows custom server in both prod and dev)
    if (_overrideBaseUrl.isNotEmpty) {
      final testResult = await testServerConnection(_overrideBaseUrl, timeoutMs: 2500);
      if (testResult['success'] == true) {
        _notifyUrlChanged();
        return _overrideBaseUrl;
      }
    }

    // ─────────────────────────────────────────────────────────────
    // PRODUCTION MODE (isProduction == true):
    // Run on any server / live production endpoint worldwide.
    // ─────────────────────────────────────────────────────────────
    if (isProduction) {
      // Primary check: production cloud endpoint
      final res = await testServerConnection(productionUrl, timeoutMs: 2500);
      if (res['success'] == true) {
        _discoveredBaseUrl = productionUrl;
        _overrideBaseUrl = '';
        _notifyUrlChanged();
        return productionUrl;
      }

      // Secondary check: cloud tunnel
      final tunnelRes = await testServerConnection(cloudTunnelUrl, timeoutMs: 2500);
      if (tunnelRes['success'] == true) {
        _discoveredBaseUrl = cloudTunnelUrl;
        _overrideBaseUrl = '';
        _notifyUrlChanged();
        return cloudTunnelUrl;
      }

      // Production fallback: default to productionUrl so it runs anywhere
      _discoveredBaseUrl = productionUrl;
      _notifyUrlChanged();
      return _discoveredBaseUrl;
    }

    // ─────────────────────────────────────────────────────────────
    // LOCAL DEVELOPMENT MODE (isProduction == false):
    // Run ONLY in local environment (local WiFi, emulator, localhost)
    // ─────────────────────────────────────────────────────────────
    final primaryEndpoints = [
      localWifiUrl,
      'http://localhost:5000/api',
      _defaultAndroidUrl,
      cloudTunnelUrl,
    ];

    for (final endpoint in primaryEndpoints) {
      final res = await testServerConnection(endpoint, timeoutMs: 1500);
      if (res['success'] == true) {
        _discoveredBaseUrl = endpoint;
        _overrideBaseUrl = '';
        _notifyUrlChanged();
        return endpoint;
      }
    }

    // Fallback: probe remaining subnet candidates in parallel
    final otherCandidates = defaultCandidates
        .where((c) => !primaryEndpoints.contains(c))
        .toList();

    final completer = Completer<String?>();
    int pending = otherCandidates.length;

    if (pending == 0) {
      _discoveredBaseUrl = localWifiUrl;
      _notifyUrlChanged();
      return _discoveredBaseUrl;
    }

    for (final candidate in otherCandidates) {
      testServerConnection(candidate, timeoutMs: 1500).then((res) {
        if (res['success'] == true && !completer.isCompleted) {
          completer.complete(candidate);
        } else {
          pending--;
          if (pending <= 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        }
      }).catchError((_) {
        pending--;
        if (pending <= 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    final found = await completer.future.timeout(
      const Duration(milliseconds: 2000),
      onTimeout: () => null,
    );

    if (found != null) {
      _discoveredBaseUrl = found;
      _overrideBaseUrl = '';
      _notifyUrlChanged();
      return found;
    }

    // Local fallback: use local wifi
    _discoveredBaseUrl = localWifiUrl;
    _notifyUrlChanged();
    return _discoveredBaseUrl;
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/users/login';
  static String get registerUrl => '$baseUrl/users/register';
  static String get sendMobileOtpUrl => '$baseUrl/users/send-mobile-otp';
  static String get verifyMobileOtpUrl => '$baseUrl/users/verify-mobile-otp';
  static String get forgotPasswordUrl => '$baseUrl/users/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/users/reset-password';
  static String get usersUrl => '$baseUrl/users';

  // Catalog items and health check endpoints
  static String get itemsUrl => '$baseUrl/items';
  static String get healthUrl => '$baseUrl/health';

  // Razorpay payment endpoints
  static String get razorpayCreateOrderUrl => '$baseUrl/payment/create-order';
  static String get razorpayVerifyPaymentUrl =>
      '$baseUrl/payment/verify-payment';

  // Realtime WebSocket endpoint
  static String get wsUrl {
    final clean = baseUrl.replaceAll(RegExp(r'/api$'), '');
    if (clean.startsWith('https://')) {
      return clean.replaceFirst('https://', 'wss://');
    }
    return clean.replaceFirst('http://', 'ws://');
  }
}
