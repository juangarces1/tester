// lib/data/api/card_auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/helpers/constans.dart';


class CardAuthApi {
  final http.Client _client;
  CardAuthApi({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('${Constans.getAPIUrl()}$path');

  Future<void> assignCard({required int cedula, required String uid}) async {
    final resp = await _client.post(
      _u('/api/users/$cedula/cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
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
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }

  Future<Empleado> loginByCard({required String uid}) async {
    final resp = await _client.post(
      _u('/api/users/login-card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final emp = json['empleado'] as Map<String, dynamic>;
      return Empleado.fromApi(emp);
      // Si NO quieres modelo, devuelve: return emp;
    }
    if (resp.statusCode == 404) {
      throw Exception('Tarjeta no registrada o inactiva (404)');
    }
    if (resp.statusCode == 403) {
      throw Exception('Tarjeta revocada (403)');
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }
}
