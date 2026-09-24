import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class VexaWebSocketService {
  static final VexaWebSocketService _instance = VexaWebSocketService._internal();
  factory VexaWebSocketService() => _instance;
  VexaWebSocketService._internal();

  WebSocket? _socket;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _disposed = false;

  // Queue messages sent before connection is ready
  final List<Map<String, dynamic>> _sendQueue = [];

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _eventController.stream;

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  void connect() async {
    if (_disposed) return;
    if (_isConnecting || isConnected) return;

    _isConnecting = true;
    final wsUrl = ApiConfig.wsUrl;

    try {
      debugPrint('⚡ [VexaWS] Connecting to: $wsUrl');
      _socket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 6));
      _isConnecting = false;

      debugPrint('✅ [VexaWS] Connected! Flushing ${_sendQueue.length} queued messages.');
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Flush all queued messages now that socket is open
      _flushQueue();

      // Start a periodic ping to keep the connection alive
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendRaw({'type': 'PING', 'timestamp': DateTime.now().millisecondsSinceEpoch});
      });

      _socket!.listen(
        (data) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(data as String);
            _eventController.add(parsed);
          } catch (e) {
            debugPrint('[VexaWS] Parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('[VexaWS] Error: $error');
          _onDisconnected();
        },
        onDone: () {
          debugPrint('[VexaWS] Connection closed.');
          _onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnecting = false;
      debugPrint('[VexaWS] Connection failed: $e');
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _socket = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      connect();
    });
  }

  void _flushQueue() {
    final pending = List<Map<String, dynamic>>.from(_sendQueue);
    _sendQueue.clear();
    for (final msg in pending) {
      _sendRaw(msg);
    }
  }

  void _sendRaw(Map<String, dynamic> payload) {
    if (isConnected) {
      try {
        _socket!.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('[VexaWS] Send error: $e');
      }
    }
  }

  /// Send a typed event message. Queues automatically if not yet connected.
  void send(String type, Map<String, dynamic> data) {
    final payload = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (isConnected) {
      _sendRaw(payload);
      debugPrint('⚡ [VexaWS] Sent: $type');
    } else {
      // Queue the message and ensure we are connecting
      _sendQueue.add(payload);
      debugPrint('📦 [VexaWS] Queued: $type (will send when connected)');
      connect();
    }
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socket?.close();
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}
