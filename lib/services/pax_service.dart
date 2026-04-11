import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tester/Models/Pax/pax_response.dart';
import 'package:tester/Models/Pax/transaccion_pax.dart';
import 'package:tester/helpers/api_helper.dart';

/// Communicates with the PAX A920 terminal via its HTTP Web Service.
/// The terminal runs a web server on port 8080 when the financial app is open.
class PaxService {
  static const int _defaultTimeout = 60000; // 60s - time for customer to swipe card
  static const int _tamanoLinea = 42;
  static const String _delimitador = '|';

  /// Send a sale command to the PAX terminal.
  /// [monto] must be in cents (no decimals): 10.00 = 1000
  static Future<PaxResponse> venta({
    required String ip,
    required int puerto,
    required int monto,
    int? propina,
    int? impuesto,
    int timeout = _defaultTimeout,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{
      'monto': monto,
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
      'timeout': timeout,
    };
    if (propina != null && propina > 0) params['propina'] = propina;
    if (impuesto != null && impuesto > 0) params['impuesto'] = impuesto;

    return _execute(
        ip: ip, puerto: puerto, path: '/venta', params: params, timeout: timeout, cancelToken: cancelToken);
  }

  /// Send a void command to the PAX terminal.
  /// [recibo] is the receipt number from the original sale.
  static Future<PaxResponse> anulacion({
    required String ip,
    required int puerto,
    required String recibo,
    int timeout = _defaultTimeout,
  }) async {
    final params = <String, dynamic>{
      'recibo': recibo,
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
    };

    return _execute(
        ip: ip, puerto: puerto, path: '/anulacion', params: params, timeout: timeout);
  }

  /// Send a batch close command to the PAX terminal.
  static Future<PaxResponse> cierre({
    required String ip,
    required int puerto,
    int timeout = _defaultTimeout,
  }) async {
    final params = <String, dynamic>{
      'tamanoLinea': _tamanoLinea,
      'delimitador': _delimitador,
    };

    return _execute(
        ip: ip, puerto: puerto, path: '/cierre', params: params, timeout: timeout);
  }

  static Future<PaxResponse> _execute({
    required String ip,
    required int puerto,
    required String path,
    required Map<String, dynamic> params,
    required int timeout,
    CancelToken? cancelToken,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://$ip:$puerto',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: Duration(milliseconds: timeout + 5000),
    ));

    try {
      final response = await dio.get(path,
          queryParameters: params, cancelToken: cancelToken);

      if (response.data is Map<String, dynamic>) {
        return PaxResponse.fromJson(response.data);
      }

      return PaxResponse(respCode: 'WE');
    } on DioException catch (e) {
      debugPrint('PaxService error: ${e.type} - ${e.message}');

      if (e.type == DioExceptionType.cancel) {
        return PaxResponse(respCode: 'CANCELLED');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return PaxResponse(respCode: 'CONNECT TIMEOUT');
      }

      if (e.type == DioExceptionType.receiveTimeout) {
        return PaxResponse(respCode: 'NA');
      }

      return PaxResponse(respCode: 'CE');
    }
  }
}

/// Executes a PAX void and saves the result to the backend.
/// Shows a progress dialog while waiting.
/// Returns true if the void was approved.
Future<bool> executePaxAnulacion({
  required BuildContext context,
  required String ip,
  required int puerto,
  required String recibo,
  int? idCierre,
  int? idDatafono,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Color(0xFF1A2332),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF22C55E)),
            SizedBox(height: 16),
            Text('Procesando anulacion...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  );

  final paxResponse = await PaxService.anulacion(
    ip: ip,
    puerto: puerto,
    recibo: recibo,
  );

  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  if (paxResponse.isApproved) {
    final tx = TransaccionPax.fromPaxResponse(
      paxResponse,
      idCierre: idCierre,
      idDatafono: idDatafono,
    );
    await ApiHelper.postTransaccionPax(tx.toJson());
    return true;
  }

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Anulacion Denegada',
            style: TextStyle(color: Colors.red)),
        content: Text(paxResponse.errorMessage,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  return false;
}
