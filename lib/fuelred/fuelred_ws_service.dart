import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tester/helpers/constans.dart';

/// Servicio WebSocket para recibir eventos en tiempo real de FuelRed P4S.
///
/// Eventos:
///   - `transaction:waiting` → llegó chofer FuelRed a una bomba (Sello 1 ok)
///   - `dispatch:ready`      → despacho autorizado, listo para ejecutar
///   - `dispatch:update`     → cambio de estado en despacho existente
class FuelRedWsService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _retryCount = 0;
  static const int _maxRetryDelay = 30;

  // ── Streams públicos ────────────────────────────────────────
  final _transactionWaitingCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _dispatchReadyCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _dispatchUpdateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _transactionCancelledCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusCtrl = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onTransactionWaiting =>
      _transactionWaitingCtrl.stream;
  Stream<Map<String, dynamic>> get onDispatchReady =>
      _dispatchReadyCtrl.stream;
  Stream<Map<String, dynamic>> get onDispatchUpdate =>
      _dispatchUpdateCtrl.stream;
  Stream<Map<String, dynamic>> get onTransactionCancelled =>
      _transactionCancelledCtrl.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusCtrl.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  /// Callback opcional que se ejecuta al reconectar (para re-sincronizar REST).
  VoidCallback? onReconnect;

  // ── Conexión ────────────────────────────────────────────────
  void connect() {
    if (_disposed) return;
    final apiKey = Constans.fuelRedApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[FuelRedWS] No API key configurada, no se conecta.');
      return;
    }

    final uri = Uri.parse('${Constans.fuelRedWsUrl}?apiKey=$apiKey');
    debugPrint('[FuelRedWS] Conectando a $uri');

    try {
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          debugPrint('[FuelRedWS] Error: $error');
          _setConnected(false);
          _scheduleReconnect();
        },
        onDone: () {
          final code = _channel?.closeCode;
          debugPrint('[FuelRedWS] Cerrado (code=$code)');
          _setConnected(false);
          // code 1008 = API key inválida, no reintentar
          if (code != 1008) {
            _scheduleReconnect();
          } else {
            debugPrint('[FuelRedWS] API key inválida, reconnect deshabilitado.');
          }
        },
        cancelOnError: false,
      );

      _setConnected(true);
      _retryCount = 0;
    } catch (e) {
      debugPrint('[FuelRedWS] Error al conectar: $e');
      _setConnected(false);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = msg['event'] as String?;
      final data = msg['data'] as Map<String, dynamic>? ?? {};

      debugPrint('[FuelRedWS] Evento: $event');

      switch (event) {
        case 'transaction:waiting':
          _transactionWaitingCtrl.add(data);
          break;
        case 'dispatch:ready':
          _dispatchReadyCtrl.add(data);
          break;
        case 'dispatch:update':
          _dispatchUpdateCtrl.add(data);
          break;
        case 'transaction:cancelled':
          _transactionCancelledCtrl.add(data);
          break;
        default:
          debugPrint('[FuelRedWS] Evento desconocido: $event → $data');
      }
    } catch (e) {
      debugPrint('[FuelRedWS] Error parseando mensaje: $e');
    }
  }

  // ── Envío de mensajes ──────────────────────────────────────

  /// Envía un mensaje JSON por el WS.
  void send(String event, Map<String, dynamic> data) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  /// Envía progreso de despacho FuelRed al backend.
  void sendDispatchProgress({
    required int transactionId,
    required double liters,
    required double amount,
    required String status,
  }) {
    send('dispatch:progress', {
      'transaction_id': transactionId,
      'liters': liters,
      'amount': amount,
      'status': status,
    });
  }

  // ── Reconnect con backoff lineal ────────────────────────────
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _retryCount++;
    final delay = (_retryCount * 3).clamp(3, _maxRetryDelay);
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect();
      onReconnect?.call();
    });
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    _connectionStatusCtrl.add(value);
  }

  // ── Desconexión ─────────────────────────────────────────────
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setConnected(false);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _transactionWaitingCtrl.close();
    _dispatchReadyCtrl.close();
    _dispatchUpdateCtrl.close();
    _transactionCancelledCtrl.close();
    _connectionStatusCtrl.close();
  }
}
