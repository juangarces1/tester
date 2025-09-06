import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tester/ConsoleModels/beach_config_models.dart';




class BeachApiHelper {
  static const String _baseUrl = 'http://gasolineria-aspdemo010.asptienda.com/api/beaches-configuration';

  // Crear configuración de playa
  static Future<BeachConfigDto?> createBeachConfig(BeachConfigUpsertRequest req) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (res.statusCode == 201) {
      return BeachConfigDto.fromJson(jsonDecode(res.body)['data']);
    }
    return null;
  }

  // Listar configuraciones de playa (paginado)
  static Future<BeachConfigListResponse?> getBeachConfigs({String? filter, int? page, int? pageSize}) async {
    final params = <String, String>{};
    if (filter != null) params['filter'] = filter;
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return BeachConfigListResponse.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // Obtener configuración de playa por ID
  static Future<BeachConfigDto?> getBeachConfigById(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode == 200) {
      return BeachConfigDto.fromJson(jsonDecode(res.body)['data']);
    }
    return null;
  }

  // Actualizar configuración de playa
  static Future<BeachConfigDto?> updateBeachConfig(int id, BeachConfigUpsertRequest req) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (res.statusCode == 200) {
      return BeachConfigDto.fromJson(jsonDecode(res.body)['data']);
    }
    return null;
  }

  // Eliminar configuración de playa
  static Future<bool> deleteBeachConfig(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode == 200) {
      return BoolApiResponse.fromJson(jsonDecode(res.body)).data;
    }
    return false;
  }

  // Listar tipos de enlace
  static Future<LinkTypeListResponse?> getLinkTypes({String? filter, int? page, int? pageSize}) async {
    final params = <String, String>{};
    if (filter != null) params['filter'] = filter;
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();

    final uri = Uri.parse('$_baseUrl/LinkType').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return LinkTypeListResponse.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // Asignar usuarios a configuración de playa
  static Future<BeachConfigDto?> assignUsersToBeachConfig(int id, List<BeachUserAssignRequest> users) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/Users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(users.map((u) => u.toJson()).toList()),
    );
    if (res.statusCode == 200) {
      return BeachConfigDto.fromJson(jsonDecode(res.body)['data']);
    }
    return null;
  }

  // Listar configuraciones de playa por usuario
  static Future<List<BeachConfigDto>> getBeachConfigsByUser(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/by-user/$userId'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['data'] as List)
          .map((j) => BeachConfigDto.fromJson(j))
          .toList();
    }
    return [];
  }

  
}
