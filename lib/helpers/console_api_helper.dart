import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/ConsoleModels/dispenser_last_info_response.dart';
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';
import 'package:tester/ConsoleModels/nozzle_info.dart';
import 'package:tester/ConsoleModels/pump_faces_model.dart';
import 'package:tester/ConsoleModels/success_response.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/helpers/constans.dart';

class ConsoleApiHelper {
  // URL base para la API de Horustec Dispatches

  /// GET /api/user/{UserMail} -> { "data": "<uuid>" }
  Future<String> getUserIdByEmail(String email) async {
    final uri = Uri.parse(
        '${Constans.baseUrlHorustec}user/${Uri.encodeComponent(email)}');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final id = decoded?['data'];
    if (id is String && id.isNotEmpty) {
      return id;
    }
    throw Exception('Respuesta inválida al resolver userId');
  }

  // 8. Pre-despacho
  static Future<bool> preDispense(
      int hoseId, double amount, String userIdentifier,
      {bool authorize = true}) async {
    final uri = Uri.parse(
        '${Constans.baseUrlHorustec}Dispense/PreDispense?hoseId=$hoseId&amount=$amount&userIdentifier=$userIdentifier&authorize=$authorize');
    final res = await http.post(uri);
    if (res.statusCode == 200) {
      return SuccessResponse.fromJson(jsonDecode(res.body)).success;
    }
    return false;
  }

  // 9. Post-despacho
  static Future<bool> postDispense(int hoseId) async {
    final uri = Uri.parse(
        '${Constans.baseUrlHorustec}Dispense/PostDispense?hoseId=$hoseId');
    final res = await http.post(uri);
    if (res.statusCode == 200) {
      return SuccessResponse.fromJson(jsonDecode(res.body)).success;
    }
    return false;
  }

  // 10. Finalizar despacho por dispenserId
  static Future<bool> endDispense(int dispenserId) async {
    final uri = Uri.parse(
        '${Constans.baseUrlCoreWeb}Dispense/EndDispense?dispenserId=$dispenserId');
    final res = await http.post(uri);
    if (res.statusCode == 200) {
      return SuccessResponse.fromJson(jsonDecode(res.body)).success;
    }
    return false;
  }

  /// Finaliza/cancela un despacho por ID de dispensador.
  /// Utiliza el endpoint api/Dispense/EndDispense de Horus.
  static Future<bool> endDispenseByDispenser(int dispenserId) async {
    final uri = Uri.parse(
      '${Constans.baseUrlHorustec}Dispense/EndDispense?dispenserId=$dispenserId',
    );
    debugPrint(
        '🛑 [API] CALLING endDispenseByDispenser: dispenserId=$dispenserId');

    try {
      final res = await http.post(uri);
      if (res.statusCode == 200) {
        final success = SuccessResponse.fromJson(jsonDecode(res.body)).success;
        debugPrint('✅ [API] endDispenseByDispenser SUCCESS: $success');
        return success;
      } else {
        debugPrint('❌ [API] endDispenseByDispenser FAILED: ${res.statusCode}');
        debugPrint('RESPONSE BODY: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [API] endDispenseByDispenser EXCEPTION: $e');
      return false;
    }
  }

  // 11. Obtener información del último despacho de un dispensador
  static Future<DispenserLastInfoResponse?> getDispenserLastInfo(
      int dispenserId) async {
    final uri = Uri.parse(
        '${Constans.baseUrlCoreWeb}Manager/GetDispenserLastInfo?dispenserId=$dispenserId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return DispenserLastInfoResponse.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // 12. Obtener estado de todos los dispensadores
  static Future<List<DispenserStatus>> getDispensersStatus() async {
    final url =
        Uri.parse('${Constans.baseUrlHorustec}Manager/GetDispensersStatus');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return DispensersStatusResponse.fromJson(jsonDecode(res.body)).dispensers;
    }
    throw Exception(
        'Error al obtener estado de dispensadores: HTTP ${res.statusCode}');
  }

  /// Endpoint alternativo más simple: /api/Connector/Statuses
  /// Devuelve un array de strings donde cada 3 elementos corresponden a un dispensador.
  /// Ej: [0-2] = Dispensador 1, [3-5] = Dispensador 2, etc.
  static Future<List<String>> getConnectorStatuses() async {
    final url = Uri.parse('${Constans.baseUrlHorustec}Connector/Statuses');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final statuses = json['statuses'];
      if (statuses is List) {
        return statuses.cast<String>();
      }
      throw Exception(
          'Formato de respuesta inválido: statuses no es una lista');
    }
    throw Exception(
        'Error al obtener Connector/Statuses: HTTP ${res.statusCode}');
  }

  // 14. Obtener último despacho por manguera (nozzle)
  // static Future<DispatchModel?> getLastDispatchByNozzle(int nozzleNumber) async {
  //   final uri = Uri.parse(
  //     '${Constans.baseUrlCoreWeb}horustech/dispatches/nozzle/$nozzleNumber/last'
  //   );
  //   final res = await http.get(uri);
  //   if (res.statusCode == 200) {
  //     final body = jsonDecode(res.body);
  //     // El JSON viene en { "data": { "id":…, "nozzleNumber":…, "volume":… } }
  //     return DispatchModel.fromJson(body['data']);
  //   }
  //   return null;
  // }

  static Future<List<PumpData>> getPumpsAndFaces() async {
    final url = Uri.parse(
        '${Constans.baseUrlCoreWeb}pumps-beaches-configuration'); // O la ruta correcta de tu endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      final pumpResponse = PumpFacesResponse.fromJson(jsonMap);
      return pumpResponse.data;
    } else {
      throw Exception('Error al obtener pumps: ${response.statusCode}');
    }
  }

  static Future<List<NozzleInfo>> getNozzles() async {
    final url = Uri.parse('${Constans.baseUrlCoreWeb}horustech/nozzles');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      final nozzleResponse = NozzleApiResponse.fromJson(jsonMap);
      return nozzleResponse.data;
    } else {
      throw Exception('Error al obtener nozzles: ${response.statusCode}');
    }
  }

  // 13. Eliminar despacho Horustech
  static Future<bool> deleteDispatch(int dispatchId) async {
    // Ajusta la base URL si tu Constans.baseUrlCoreWeb ya incluye /api/
    final uri =
        Uri.parse('${Constans.baseUrlCoreWeb}horustech/dispatches/$dispatchId');

    final res = await http.delete(uri);

    if (res.statusCode == 200) {
      // La API responde: { "data": true }
      return SuccessResponse.fromJson(jsonDecode(res.body)).success;
    }
    return false;
  }

  /// Autoriza tanque lleno
  static Future<bool> postDispenseV2(int nozzleNumber, String userIdentifier,
      {bool authorize = true}) async {
    final uri = Uri.parse(
      '${Constans.baseUrlHorustec}Dispense/PostDispense'
      '?hoseId=$nozzleNumber'
      '&userIdentifier=$userIdentifier'
      '&authorize=$authorize',
    );
    debugPrint(
        '🚀 [API] CALLING postDispenseV2: nozzle=$nozzleNumber, user=$userIdentifier');
    final res = await http.post(uri);
    if (res.statusCode == 200) {
      debugPrint('✅ [API] postDispenseV2 SUCCESS');
    } else {
      debugPrint('❌ [API] postDispenseV2 FAILED: URI=$uri');
      debugPrint('STATUS CODE: ${res.statusCode}');
      debugPrint('RESPONSE BODY: ${res.body}');
    }
    return res.statusCode == 200;
  }

  /// Autoriza preset
  static Future<bool> preDispenseV2(
    int nozzleNumber,
    num amount,
    String userIdentifier, {
    required bool volumeDispatch,
    bool authorize = true,
  }) async {
    final uri = Uri.parse(
      '${Constans.baseUrlHorustec}Dispense/PreDispense'
      '?hoseId=$nozzleNumber'
      '&amount=$amount'
      '&userIdentifier=$userIdentifier'
      '&authorize=$authorize'
      '&volumeDispatch=$volumeDispatch',
    );
    debugPrint(
        '🚀 [API] CALLING preDispenseV2: nozzle=$nozzleNumber, amount=$amount, user=$userIdentifier');
    final res = await http.post(uri);
    if (res.statusCode == 200) {
      debugPrint('✅ [API] preDispenseV2 SUCCESS');
    } else {
      debugPrint('❌ [API] preDispenseV2 FAILED: URI=$uri');
      debugPrint('STATUS CODE: ${res.statusCode}');
      debugPrint('RESPONSE BODY: ${res.body}');
    }
    return res.statusCode == 200;
  }

  /// Última transacción SIN PAGO por manguera (nozzle).
  /// Devuelve null si no hay registro.

  static Future<Response> getLastUnpaidByNozzle(
    int nozzle, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse(
      '${Constans.baseUrlCoreWeb}horustech/dispatches/nozzle/$nozzle/last-unpaid',
    );

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);

        // A: si usas la clase refactorizada (con _unwrap), puedes pasar raw (si es Map)
        if (raw is! Map) {
          throw const FormatException(
              'Se esperaba un objeto JSON (Map), pero llegó otra cosa.');
        }
        final tx = ConsoleTransaction.fromJson(raw.cast<String, dynamic>());
        return Response(isSuccess: true, message: 'Éxito', result: tx);
      } else if (response.statusCode == 204) {
        // No content
        return Response(isSuccess: true, message: '', result: []);
      } else {
        // Handle other statuses, maybe something went wrong
        return Response(isSuccess: false, message: "Error: ${response.body}");
      }
    } on TimeoutException {
      return Response(
          isSuccess: false, message: 'Tiempo de espera agotado', result: null);
    } catch (e) {
      return Response(isSuccess: false, message: 'Error: $e', result: null);
    }
  }

  static Future<Response> getTransactionLastByNozzle(
    int nozzle, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final uri = Uri.parse(
      '${Constans.baseUrlCoreWeb}horustech/dispatches/nozzle/$nozzle/last',
    );

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);

        // A: si usas la clase refactorizada (con _unwrap), puedes pasar raw (si es Map)
        if (raw is! Map) {
          throw const FormatException(
              'Se esperaba un objeto JSON (Map), pero llegó otra cosa.');
        }
        final tx = ConsoleTransaction.fromJson(raw.cast<String, dynamic>());
        return Response(isSuccess: true, message: 'Éxito', result: tx);
      } else if (response.statusCode == 204) {
        // No content
        return Response(isSuccess: true, message: '', result: []);
      } else {
        // Handle other statuses, maybe something went wrong
        return Response(isSuccess: false, message: "Error: ${response.body}");
      }
    } on TimeoutException {
      return Response(
          isSuccess: false, message: 'Tiempo de espera agotado', result: null);
    } catch (e) {
      return Response(isSuccess: false, message: 'Error: $e', result: null);
    }
  }
}
