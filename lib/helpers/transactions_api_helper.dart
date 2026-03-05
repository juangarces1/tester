// lib/helpers/transacciones_api_helper.dart
import 'package:dio/dio.dart' hide Response;
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/helpers/dio_client.dart';

class TransaccionesApiHelper {
  static Dio get _dio => DioClient.main;

  /// POST /TransaccionesApi  -> y si es necesario GET /TransaccionesApi/{id}
  /// Devuelve la Transaccion completa que vive en la BD.
 static Future<Transaccion> postAndFetchFull(Transaccion tx) async {
  final res = await _dio.post('/api/TransaccionesApi', data: tx.toJson());

  // Éxito normal
  if (res.statusCode == 200 || res.statusCode == 201) {
    if (res.data == null) {
      throw Exception('POST sin body (esperaba el objeto completo).');
    }
    final raw = res.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Formato inesperado: esperaba objeto JSON.');
    }
    return Transaccion.fromJson(raw);
  }

  // Duplicado - el worker ya la grabó, recuperar la existente
  if (res.statusCode == 409) {
    final numero = tx.numero;
    final fecha = DateTime.parse(tx.fechatransaccion);
    final existing = await getByKey(numero, fecha);
    if (existing != null) {
      return existing;
    }
      throw Exception('Transacción duplicada pero no se pudo recuperar la existente.');
  }

  throw Exception('POST falló (${res.statusCode}): ${res.data}');
}

  /// GET /TransaccionesApi/{id}
  static Future<Transaccion> getById(int id) async {
    final res = await _dio.get('/api/TransaccionesApi/$id');
    if (res.statusCode == 200) {
      return Transaccion.fromJson(res.data);
    } else if (res.statusCode == 404) {
      throw Exception('Transacción $id no encontrada');
    }
    throw Exception('GET falló (${res.statusCode}): ${res.data}');
  }

  /// GET /TransaccionesApi/byKey?numero={numero}&fecha={fecha}
  static Future<Transaccion?> getByKey(int numero, DateTime fecha) async {
    final res = await _dio.get(
      '/api/TransaccionesApi/byKey',
      queryParameters: {
        'numero': numero,
        'fecha': fecha.toIso8601String(),
      },
    );

    if (res.statusCode == 200) {
      return Transaccion.fromJson(res.data);
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('GET byKey falló (${res.statusCode}): ${res.data}');
  }
}
