// lib/helpers/transacciones_api_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/helpers/constans.dart'; // <- donde tengas baseUrl

class TransaccionesApiHelper {
  static const Duration _timeout = Duration(seconds: 12);

  static Map<String, String> _headers() => const {
        'content-type': 'application/json',
        'accept': 'application/json',
      };

  /// POST /TransaccionesApi  -> y si es necesario GET /TransaccionesApi/{id}
  /// Devuelve la Transaccion completa que vive en la BD.
 static Future<Transaccion> postAndFetchFull(Transaccion tx) async {
  final postUri = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi');

  final res = await http
      .post(postUri, headers: _headers(), body: jsonEncode(tx.toJson()))
      .timeout(_timeout);

  // Éxito normal
  if (res.statusCode == 200 || res.statusCode == 201) {
    if (res.body.isEmpty) {
      throw Exception('POST sin body (esperaba el objeto completo).');
    }
    final raw = jsonDecode(res.body);
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

  throw Exception('POST falló (${res.statusCode}): ${res.body}');
}


  /// GET /TransaccionesApi/{id}
  static Future<Transaccion> getById(int id) async {
    final getUri = Uri.parse('${Constans.getAPIUrl()}/api/TransaccionesApi/$id');
    final res = await http.get(getUri, headers: _headers()).timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Transaccion.fromJson(data);
    } else if (res.statusCode == 404) {
      throw Exception('Transacción $id no encontrada');
    }
    throw Exception('GET falló (${res.statusCode}): ${res.body}');
  }

  /// GET /TransaccionesApi/byKey?numero={numero}&fecha={fecha}
  /// Busca transacción existente por su clave única (Numero, Fechatransaccion)
  static Future<Transaccion?> getByKey(int numero, DateTime fecha) async {
    final uri = Uri.parse(
      '${Constans.getAPIUrl()}/api/TransaccionesApi/byKey'
    ).replace(queryParameters: {
      'numero': numero.toString(),
      'fecha': fecha.toIso8601String(),
    });

    final res = await http.get(uri, headers: _headers()).timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return Transaccion.fromJson(data);
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('GET byKey falló (${res.statusCode}): ${res.body}');
  }

  
}
