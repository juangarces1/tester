// lib/data/api/card_auth_api.dart
import 'package:dio/dio.dart' hide Response;
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/helpers/dio_client.dart';

class CardAuthApi {
  final Dio _dio;
  CardAuthApi({Dio? dio}) : _dio = dio ?? DioClient.main;

  // Migración a API nueva (2026-04-18):
  //  - /api/users/* → /api/v1/auth/*
  //  - Body: 'uid' → 'cardUid' (el record CardLoginRequest usa CardUid, JSON lo serializa como cardUid).
  //  - Respuesta del login-card: ya NO envuelve en { empleado: ... }; AuthResponse viene plano
  //    con campos que Empleado.fromApi ya reconoce (cedulaEmpleado, nombre, apellido1/2, turno, tipoempleado).
  Future<void> assignCard({required int cedula, required String uid}) async {
    final resp = await _dio.post(
      '/api/v1/auth/$cedula/cards',
      data: {'cardUid': uid},
    );
    if (resp.statusCode == 204) return;
    if (resp.statusCode == 409) {
      throw Exception('409: Tarjeta ya asignada a otro empleado');
    }
    if (resp.statusCode == 400) {
      throw Exception('400: Solicitud inválida');
    }
    if (resp.statusCode == 403) {
      throw Exception('403: Tarjeta revocada/perdida');
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.data}');
  }

  Future<Empleado> loginByCard({required String uid}) async {
    final resp = await _dio.post(
      '/api/v1/auth/login-card',
      data: {'cardUid': uid},
    );
    if (resp.statusCode == 200) {
      final json = resp.data as Map<String, dynamic>;
      return Empleado.fromApi(json);
    }
    if (resp.statusCode == 401) {
      throw Exception('Tarjeta no registrada o inactiva (401)');
    }
    if (resp.statusCode == 403) {
      throw Exception('Tarjeta revocada (403)');
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.data}');
  }
}
