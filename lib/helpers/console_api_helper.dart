import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/helpers/constans.dart';

/// Modelo de request para el endpoint /api/pump/preset-with-tag
class PresetWithTagRequest {
  final String nozzleCode;
  final String tagId;
  final int identifierType; // 0=Frentista, 1=Cliente
  final bool authorize;
  final double
      presetValue; // Valor directo en colones o litros (0 = tanque lleno)
  final int timeoutSeconds;
  final int presetType; // 0=Monto(₡), 1=Volumen(litros)
  final int priceLevel; // 0=À vista, 1=Crédito, 2=Débito

  const PresetWithTagRequest({
    required this.nozzleCode,
    required this.tagId,
    this.identifierType = 0,
    this.authorize = true,
    required this.presetValue,
    this.timeoutSeconds = 30,
    required this.presetType,
    this.priceLevel = 0,
  });

  Map<String, dynamic> toJson() => {
        'nozzleCode': nozzleCode,
        'tagId': tagId,
        'identifierType': identifierType,
        'authorize': authorize,
        'presetValue': presetValue,
        'timeoutSeconds': timeoutSeconds,
        'presetType': presetType,
        'priceLevel': priceLevel,
      };
}

class ConsoleApiHelper {
  static String get _base => Constans.baseUrlConsole;

  // ─────────────────────────────────────────────────────────────────────────
  // Preset con tag RFID — endpoint único para monto, volumen y tanque lleno
  // POST /api/pump/preset-with-tag
  // ─────────────────────────────────────────────────────────────────────────

  /// Autoriza un preset por **monto** (₡) en la manguera indicada.
  /// [nozzleCode] debe ser "01".."48" (string con cero a la izquierda).
  /// [amount] en colones, valor directo (ej: 5000.0).
  /// [tagId] identificador RFID del frentista (16 chars hex).
  static Future<bool> presetByAmount({
    required String nozzleCode,
    required double amount,
    required String tagId,
    bool authorize = true,
    int timeoutSeconds = 10,
  }) =>
      _sendPreset(PresetWithTagRequest(
        nozzleCode: nozzleCode,
        tagId: tagId,
        authorize: authorize,
        presetValue: amount,
        timeoutSeconds: timeoutSeconds,
        presetType: 0, // Monto
      ));

  /// Autoriza un preset por **volumen** (litros) en la manguera indicada.
  /// [liters] en litros, valor directo (ej: 20.0).
  static Future<bool> presetByVolume({
    required String nozzleCode,
    required double liters,
    required String tagId,
    bool authorize = true,
    int timeoutSeconds = 10,
  }) =>
      _sendPreset(PresetWithTagRequest(
        nozzleCode: nozzleCode,
        tagId: tagId,
        authorize: authorize,
        presetValue: liters,
        timeoutSeconds: timeoutSeconds,
        presetType: 1, // Volumen
      ));

  /// Autoriza **tanque lleno** en la manguera indicada.
  /// Envía presetValue=0 que el concentrador interpreta como sin límite.
  static Future<bool> presetTankFull({
    required String nozzleCode,
    required String tagId,
    bool authorize = true,
    int timeoutSeconds = 10,
  }) =>
      _sendPreset(PresetWithTagRequest(
        nozzleCode: nozzleCode,
        tagId: tagId,
        authorize: authorize,
        presetValue: 0,
        timeoutSeconds: timeoutSeconds,
        presetType: 0, // Monto con 0 = tanque lleno
      ));

  // ─────────────────────────────────────────────────────────────────────────
  // Interno
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> _sendPreset(PresetWithTagRequest req) async {
    final uri = Uri.parse('${_base}pump/preset-with-tag');
    final body = jsonEncode(req.toJson());

    debugPrint('🚀 [ConsoleApi] POST $uri');
    debugPrint('   body: $body');

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        debugPrint('✅ [ConsoleApi] preset-with-tag OK');
        return true;
      } else {
        debugPrint('❌ [ConsoleApi] preset-with-tag FAILED: ${res.statusCode}');
        debugPrint('   response: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ConsoleApi] preset-with-tag EXCEPTION: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Última venta por manguera — POST /api/pump/last-sale
  // ─────────────────────────────────────────────────────────────────────────

  /// Consulta la última venta registrada en la consola para [nozzleCode].
  /// [since] filtra solo transacciones con fecha ≥ ese instante.
  /// Retorna un `Product` listo para facturar, o `null` si no hay resultados.
  static Future<Product?> getLastSaleByNozzle(
    String nozzleCode, {
    DateTime? since,
  }) async {
    final uri = Uri.parse('${_base}pump/last-sale');

    final Map<String, dynamic> body = {
      'nozzleCode': nozzleCode,
      if (since != null) 'since': since.toUtc().toIso8601String(),
    };

    debugPrint('🔍 [ConsoleApi] POST $uri');
    debugPrint('   body: ${jsonEncode(body)}');

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // El response puede ser { data: {...} }, { result: {...} } o directamente el objeto
        final Map<String, dynamic>? prodJson =
            decoded is Map<String, dynamic> ? decoded : null;

        if (prodJson == null || prodJson.isEmpty) {
          debugPrint('⚠️ [ConsoleApi] last-sale: respuesta vacía');
          return null;
        }

        debugPrint('✅ [ConsoleApi] last-sale OK para manguera $nozzleCode');
        return Product.fromJson(prodJson);
      } else {
        debugPrint(
            '❌ [ConsoleApi] last-sale FAILED: ${res.statusCode} → ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ConsoleApi] last-sale EXCEPTION: $e');
      return null;
    }
  }
}
