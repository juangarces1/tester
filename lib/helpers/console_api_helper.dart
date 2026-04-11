import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';
import 'package:tester/helpers/dio_client.dart';

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
  static Dio get _dio => DioClient.console;

  /// Autoriza un preset por **monto** (₡) en la manguera indicada.
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
        presetType: 0,
      ));

  /// Autoriza un preset por **volumen** (litros) en la manguera indicada.
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
        presetType: 1,
      ));

  /// Autoriza **tanque lleno** en la manguera indicada.
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
        presetType: 0,
      ));

  /// Obtiene los precios actuales de combustible desde /api/Prices/current.
  /// Requiere login previo (`DioClient.loginConsole()`).
  /// Retorna Map<String, double> donde key = nombre del producto en minúscula.
  static Future<Map<String, double>> getCurrentPrices() async {
    try {
      if (!DioClient.isConsoleAuthenticated) {
        await DioClient.loginConsole();
      }

      final authDio = DioClient.consoleAuth;
      if (authDio == null) return {};

      final res = await authDio.get('Prices/current');

      if (res.statusCode == 200 && res.data is List) {
        final Map<String, double> prices = {};
        for (final item in res.data as List) {
          final name = (item['productName'] as String?)?.toLowerCase() ?? '';
          final price = (item['currentPrice'] as num?)?.toDouble() ?? 0.0;
          if (name.isNotEmpty) prices[name] = price;
        }
        debugPrint('💰 [ConsoleApi] Precios actuales: $prices');
        return prices;
      }

      debugPrint('❌ [ConsoleApi] getCurrentPrices failed: ${res.statusCode}');
      return {};
    } catch (e) {
      debugPrint('❌ [ConsoleApi] getCurrentPrices exception: $e');
      return {};
    }
  }

  static Future<bool> _sendPreset(PresetWithTagRequest req) async {
    final body = req.toJson();

    debugPrint('🚀 [ConsoleApi] POST pump/preset-with-tag');
    debugPrint('   baseUrl: ${_dio.options.baseUrl}');
    debugPrint('   headers: ${_dio.options.headers}');
    debugPrint('   body: $body');

    try {
      final res = await _dio.post('pump/preset-with-tag', data: body);

      debugPrint('   statusCode: ${res.statusCode}');
      debugPrint('   responseHeaders: ${res.headers}');
      debugPrint('   responseData: ${res.data}');

      if (res.statusCode == 200) {
        debugPrint('✅ [ConsoleApi] preset-with-tag OK');
        return true;
      } else {
        debugPrint('❌ [ConsoleApi] preset-with-tag FAILED: ${res.statusCode}');
        return false;
      }
    } catch (e, st) {
      debugPrint('❌ [ConsoleApi] preset-with-tag EXCEPTION: $e');
      debugPrint('   stackTrace: $st');
      return false;
    }
  }

}
