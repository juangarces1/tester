import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tester/helpers/constans.dart';

class DioClient {
  DioClient._();

  static final Dio main = Dio(BaseOptions(
    baseUrl: Constans.getAPIUrl(),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
    },
    validateStatus: (s) => s != null && s < 500,
  ));

  static final Dio console = Dio(BaseOptions(
    baseUrl: Constans.baseUrlConsole,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
    validateStatus: (s) => s != null && s < 500,
  ));

  // ── Dio autenticado para Console API (8087) ────────────────
  // Separado de `console` para no contaminar preset/pump endpoints.
  static Dio? _consoleAuth;
  static String? _consoleToken;

  /// Dio instance con Bearer token para endpoints que requieren auth.
  static Dio? get consoleAuth => _consoleAuth;

  /// Autentica contra la Console API y crea un Dio autenticado separado.
  static Future<bool> loginConsole({
    String username = 'admin',
    String password = 'Admin123!',
  }) async {
    try {
      final res = await console.post('Auth/login', data: {
        'username': username,
        'password': password,
      });

      if (res.statusCode == 200 && res.data['accessToken'] != null) {
        _consoleToken = res.data['accessToken'] as String;
        _consoleAuth = Dio(BaseOptions(
          baseUrl: Constans.baseUrlConsole,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_consoleToken',
          },
          validateStatus: (s) => s != null && s < 500,
        ));
        debugPrint('✅ [DioClient] Console login OK');
        return true;
      }

      debugPrint('❌ [DioClient] Console login failed: ${res.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ [DioClient] Console login exception: $e');
      return false;
    }
  }

  /// true si ya hay token de consola activo.
  static bool get isConsoleAuthenticated => _consoleToken != null;
}
