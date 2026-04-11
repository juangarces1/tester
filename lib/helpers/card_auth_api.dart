// lib/data/api/card_auth_api.dart
import 'package:dio/dio.dart' hide Response;
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/helpers/dio_client.dart';

class CardAuthApi {
  final Dio _dio;
  CardAuthApi({Dio? dio}) : _dio = dio ?? DioClient.main;

  Future<void> assignCard({required int cedula, required String uid}) async {
    final resp = await _dio.post(
      '/api/users/$cedula/cards',
      data: {'uid': uid},
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
      '/api/users/login-card',
      data: {'uid': uid},
    );
    if (resp.statusCode == 200) {
      final json = resp.data as Map<String, dynamic>;
      final emp = json['empleado'] as Map<String, dynamic>;
      return Empleado.fromApi(emp);
    }
    if (resp.statusCode == 404) {
      throw Exception('Tarjeta no registrada o inactiva (404)');
    }
    if (resp.statusCode == 403) {
      throw Exception('Tarjeta revocada (403)');
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.data}');
  }
}
