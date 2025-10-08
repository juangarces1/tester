// lib/helpers/transacciones_api_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tester/Models/transaccion.dart';
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

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('POST falló (${res.statusCode}): ${res.body}');
  }

  if (res.body.isEmpty) {
    throw Exception('POST sin body (esperaba el objeto completo).');
  }

  final raw = jsonDecode(res.body);
  if (raw is! Map<String, dynamic>) {
    throw Exception('Formato inesperado: esperaba objeto JSON.');
  }

  return Transaccion.fromJson(raw); // ← objeto completo del servidor
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

  /// Intenta extraer el id desde diferentes formas de respuesta
  static int? _extractId(Map<String, dynamic> json) {
    // ajusta si tu backend usa otro nombre
    final candidates = ['id', 'idtransaccion', 'Idtransaccion', 'IdTransaccion'];
    for (final k in candidates) {
      final v = json[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
    }
    return null;
  }
}
