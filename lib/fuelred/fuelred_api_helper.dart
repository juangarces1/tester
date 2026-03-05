import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tester/fuelred/fuelred_dio_client.dart';

/// Endpoints REST que la estación consume del backend FuelRed P4S.
/// Todas las respuestas vienen en snake_case.
/// Todos los request bodies van en camelCase.
class FuelRedApiHelper {
  FuelRedApiHelper._();

  static Dio get _dio => FuelRedDioClient.instance;

  // ── Test de conexión ───────────────────────────────────────
  /// Llama GET /transactions/waiting solo para verificar que el API key
  /// funciona y hay conectividad. Devuelve un mapa con el diagnóstico.
  static Future<Map<String, dynamic>> testConnection() async {
    final sw = Stopwatch()..start();
    try {
      final res = await _dio.get('/transactions/waiting');
      sw.stop();
      return {
        'ok': res.statusCode == 200,
        'status': res.statusCode,
        'ms': sw.elapsedMilliseconds,
        'waiting': (res.statusCode == 200)
            ? (res.data['data'] as List?)?.length ?? 0
            : 0,
        'body': res.data?.toString().substring(
            0, (res.data?.toString().length ?? 0).clamp(0, 200)),
      };
    } catch (e) {
      sw.stop();
      return {
        'ok': false,
        'status': 0,
        'ms': sw.elapsedMilliseconds,
        'waiting': 0,
        'body': e.toString().substring(0, e.toString().length.clamp(0, 200)),
      };
    }
  }

  // ── Transacciones esperando (Sello 1 completado) ───────────
  static Future<List<Map<String, dynamic>>> getWaitingTransactions() async {
    try {
      final res = await _dio.get('/transactions/waiting');
      if (res.statusCode == 200) {
        final data = res.data['data'] as List? ?? res.data as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[FuelRedAPI] getWaiting: ${res.statusCode} ${res.data}');
      return [];
    } catch (e) {
      debugPrint('[FuelRedAPI] getWaiting error: $e');
      return [];
    }
  }

  // ── Despachos autorizados pendientes de ejecución ──────────
  static Future<List<Map<String, dynamic>>> getPendingDispatches() async {
    try {
      final res = await _dio.get('/dispatches/pending');
      if (res.statusCode == 200) {
        final data = res.data['data'] as List? ?? res.data as List? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('[FuelRedAPI] getPending: ${res.statusCode} ${res.data}');
      return [];
    } catch (e) {
      debugPrint('[FuelRedAPI] getPending error: $e');
      return [];
    }
  }

  // ── Verificar vehículo + pistero (Sello 2 + 3) ────────────
  static Future<Map<String, dynamic>?> verifyVehicle({
    required int transactionId,
    required String rfidTag,
    required String pisteroId,
  }) async {
    try {
      final res = await _dio.post(
        '/transactions/$transactionId/verify-vehicle',
        data: {
          'rfidTag': rfidTag,
          'pisteroId': pisteroId,
        },
      );
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      debugPrint('[FuelRedAPI] verifyVehicle: ${res.statusCode} ${res.data}');
      return null;
    } catch (e) {
      debugPrint('[FuelRedAPI] verifyVehicle error: $e');
      return null;
    }
  }

  // ── Acknowledge — "Recibí la orden" ────────────────────────
  static Future<bool> acknowledgeDispatch(int dispatchId) async {
    try {
      final res = await _dio.post('/dispatches/$dispatchId/acknowledge');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FuelRedAPI] acknowledge error: $e');
      return false;
    }
  }

  // ── Start — bomba encendida ────────────────────────────────
  static Future<bool> startDispatch(int dispatchId) async {
    try {
      final res = await _dio.post('/dispatches/$dispatchId/start');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FuelRedAPI] start error: $e');
      return false;
    }
  }

  // ── Complete — despacho terminado con litros reales ────────
  static Future<Map<String, dynamic>?> completeDispatch({
    required int dispatchId,
    required double liters,
    required int amount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'liters': liters,
        'amount': amount,
      };
      if (startedAt != null) body['startedAt'] = startedAt.toIso8601String();
      if (completedAt != null) {
        body['completedAt'] = completedAt.toIso8601String();
      }
      final res = await _dio.post(
        '/dispatches/$dispatchId/complete',
        data: body,
      );
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      debugPrint('[FuelRedAPI] complete: ${res.statusCode} ${res.data}');
      return null;
    } catch (e) {
      debugPrint('[FuelRedAPI] complete error: $e');
      return null;
    }
  }

  // ── Cancel — cancelar despacho con razón ───────────────────
  static Future<bool> cancelDispatch({
    required int dispatchId,
    required String reason,
  }) async {
    try {
      final res = await _dio.post(
        '/dispatches/$dispatchId/cancel',
        data: {'reason': reason},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[FuelRedAPI] cancel error: $e');
      return false;
    }
  }
}
