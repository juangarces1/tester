import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/nozzle_mapping.dart';
import 'package:tester/Models/LogIn/inventory_item.dart' show InventoryItem;
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/ResumenCierre/cierre_caja_general.dart';
import 'package:tester/Models/FuelRed/all_fact.dart';
import 'package:tester/Models/FuelRed/bank.dart';
import 'package:tester/Models/FuelRed/cashback.dart';
import 'package:tester/Models/FuelRed/cierreactivo.dart';
import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/empleado.dart';

import 'package:tester/Models/FuelRed/datafono.dart';
import 'package:tester/Models/Pax/transaccion_pax.dart';
import 'package:tester/Models/FuelRed/deposito.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/Models/FuelRed/money.dart';
import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/tranferview.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/Models/FuelRed/transparcial.dart';
import 'package:tester/Models/FuelRed/viatico.dart';

import 'package:tester/helpers/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/helpers/dio_client.dart';

class ApiHelper {
  static Dio get _dio => DioClient.main;

  static Future<Response> getCierre(String cierre) async {
    final response = await _dio.get('/api/v1/caja/cierre/$cierre');

    if (response.statusCode == 200) {
      return Response(
          isSuccess: true,
          result: CierreCajaGeneral.fromJson(response.data));
    } else if (response.statusCode == 204) {
      return Response(isSuccess: true, message: '', result: []);
    } else {
      return Response(
          isSuccess: false, message: "Error: ${response.data}");
    }
  }

  /// Firma conservada: el Flutter pasa la zona como String (hereda del viejo).
  static Future<Response> getCierreActivo(String cierre) async {
    final response =
        await _dio.get('/api/v1/caja/cierre-activo/$cierre');

    if (response.statusCode == 200) {
      return Response(
          isSuccess: true,
          result: CierreCajaGeneral.fromJson(response.data));
    } else if (response.statusCode == 204) {
      return Response(isSuccess: true, message: '', result: []);
    } else {
      return Response(
          isSuccess: false, message: "Error: ${response.data}");
    }
  }

  /// Pasa el cierre a STANBY (pre-cierre). Migrado 2026-04-18.
  /// Viejo: GET /api/Facturacion/SranbyCierre/{cierre}
  /// Nuevo: POST /api/v1/caja/cierre/{id}/pasar-stanby
  static Future<Response> preCierre(String cierre) async {
    try {
      final response =
          await _dio.post('/api/v1/caja/cierre/$cierre/pasar-stanby');
      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }
      return Response(isSuccess: true, result: response.data);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  /// PENDIENTE DE MIGRAR — el viejo hace FacturacionController.CrearCierre
  /// (SetCierreFinal): genera ticket de cuadre vía sp_Facturar_Venta,
  /// respalda inventario final, marca cierre REVISADO. Pesado — portar aparte.
  static Future<Response> setCierre(String cierre) async {
    return Response(
        isSuccess: false,
        message: 'setCierre pendiente de migrar al API nuevo');
  }

  /// Deprecado — el Flutter ya no llama a este (sólo getLogInNuevo).
  /// Se deja el método por compatibilidad hasta borrarlo en una limpieza posterior.
  static Future<Response> getLogIn(int? zona, int? cedula) async {
    return getLogInNuevo(zona, cedula);
  }

  /// Login (bootstrap mínimo) — migrado 2026-04-18 al API nueva.
  ///
  /// **Observación importante**: el API vieja `GetLogInNuevo` NO traía clientes,
  /// transacciones ni productos — esos campos estaban comentados; sólo llenaba
  /// `cierreActivo` + arrays vacíos. La data real la cargan los providers después
  /// bajo demanda (ClientesProvider, MapProvider, etc.). Replicamos ese contrato.
  ///
  /// Flujo:
  ///   1. POST /auth/login → token + idCierre + info del empleado
  ///   2. Guardar token en Dio para las siguientes llamadas
  ///   3. Si idCierre == null (zona Cerrada / user no-cajero del Stanby):
  ///      AllFact con CierreActivo vacío + cajero = user (→ Flutter va a Invent).
  ///   4. Si idCierre existe: GET /caja/cierre-activo/{zona} para tener el shape
  ///      completo (cierreFinal + cajero + usuario).
  static Future<Response> getLogInNuevo(int? zona, int? cedula) async {
    try {
      final loginResp = await _dio.post(
        '/api/v1/auth/login',
        data: {'zona': zona, 'cedula': cedula},
      );

      if (loginResp.statusCode == 401) {
        return Response(
            isSuccess: false,
            message: 'Cédula incorrecta o sin cierre abierto para la zona.');
      }
      if (loginResp.statusCode! >= 400) {
        return Response(
            isSuccess: false,
            message: 'Error ${loginResp.statusCode}: ${loginResp.data}');
      }

      final loginData = loginResp.data as Map<String, dynamic>;
      final token = loginData['token'] as String?;
      final idCierre = loginData['idCierre'] as int?;

      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      // Empleado desde la respuesta del login (campos que Empleado.fromApi reconoce).
      final empleado = Empleado.fromApi(loginData);

      // Caso zona Cerrada / user no-cajero del Stanby → AllFact con sólo cajero.
      if (idCierre == null) {
        final cierreVacio = CierreActivo.fromJson(<String, dynamic>{});
        cierreVacio.cajero = empleado;
        return Response(
            isSuccess: true,
            result: AllFact(
              lasTr: 0,
              cierreActivo: cierreVacio,
              transacciones: const [],
              productos: const [],
              clientesFacturacion: const [],
              clientesCredito: const [],
              clientesPromo: const [],
            ));
      }

      // Hay cierre activo → shape completo.
      final cierreResp = await _dio.get('/api/v1/caja/cierre-activo/$zona');
      final cierreActivo = cierreResp.data is Map<String, dynamic>
          ? CierreActivo.fromJson(cierreResp.data)
          : (CierreActivo.fromJson(<String, dynamic>{})..cajero = empleado);

      return Response(
          isSuccess: true,
          result: AllFact(
            lasTr: 0,
            cierreActivo: cierreActivo,
            transacciones: const [],
            productos: const [],
            clientesFacturacion: const [],
            clientesCredito: const [],
            clientesPromo: const [],
          ));
    } catch (e) {
      return Response(
          isSuccess: false, message: 'Exception: ${e.toString()}');
    }
  }

  static Future<Response> getInventarioInicial(int? zona) async {
    try {
      final response =
          await _dio.get('/api/v1/empleados/invent-inicial/$zona');

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }
      List<InventoryItem> inventario = [];
      if (response.data != null) {
        for (var item in response.data) {
          inventario.add(InventoryItem.fromJson(item));
        }
      }
      return Response(isSuccess: true, result: inventario);
    } catch (e) {
      return Response(
          isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }

  /// GET factura por número. Migrado a /api/v1/facturacion/por-numero/{id}.
  static Future<Response> getFactura(String id) async {
    try {
      final response =
          await _dio.get('/api/v1/facturacion/por-numero/$id');

      if (response.statusCode == 200) {
        return Response(
            isSuccess: true,
            message: 'Ok',
            result: Factura.fromJson(response.data));
      } else if (response.statusCode == 404) {
        return Response(isSuccess: true, message: '', result: []);
      } else {
        return Response(
            isSuccess: false,
            message: "Error: ${response.statusCode}");
      }
    } catch (e) {
      return Response(
          isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }

  static Future<Response> getClientesCredito() async {
    final response =
        await _dio.get('/api/v1/clientes/credito');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Cliente> clientes = [];
    if (response.data != null) {
      for (var item in response.data) {
        try {
          clientes.add(Cliente.fromJson(item));
        } catch (e) {
          debugPrint('Error parsing single credit client (plural): $e');
        }
      }
    }
    return Response(isSuccess: true, result: clientes);
  }

  static Future<Response> getCierresByDia(DateTime dia) async {
    try {
      final response = await _dio.get(
          '/api/v1/caja/cierres-by-dia/${VariosHelpers.formatYYYYmmDD(dia)}');

      if (response.statusCode == 200) {
        List<CierreActivo> cierres = [];
        if (response.data != null) {
          for (var item in response.data) {
            cierres.add(CierreActivo.fromJson(item));
          }
        }
        return Response(isSuccess: true, result: cierres);
      } else if (response.statusCode == 204) {
        return Response(isSuccess: true, message: '', result: []);
      } else {
        return Response(
            isSuccess: false, message: "Error: ${response.data}");
      }
    } catch (e) {
      return Response(
          isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }

  static Future<Response> getTransacciones(int? zona) async {
    final response = await _dio.get(
        '/api/v1/transacciones/por-zona/$zona');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Transaccion> transacciones = [];
    if (response.data != null) {
      for (var item in response.data) {
        transacciones.add(Transaccion.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transacciones);
  }

  static Future<Response> getMapHoseDispenser() async {
    try {
      debugPrint(
          '🔍 [ApiHelper] GET ${Constans.getAPIUrl()}/api/v1/shifts/GetHoseKeyMap');
      final response = await _dio.get(
        '/api/v1/shifts/GetHoseKeyMap',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode! >= 400) {
        debugPrint(
            '❌ [ApiHelper] Error ${response.statusCode}: ${response.data}');
        return Response(
            isSuccess: false,
            message: 'Status ${response.statusCode}: ${response.data}');
      }

      List<NozzleMapping> nozzleMappings = [];
      if (response.data != null && response.data is List) {
        for (var i = 0; i < response.data.length; i++) {
          var item = response.data[i];
          try {
            nozzleMappings.add(NozzleMapping.fromJson(item));
          } catch (e, stack) {
            debugPrint(
                '❌ [ApiHelper] Error parseando mapping index $i: $e \n Item content: $item \n Stack: $stack');
          }
        }
      }
      return Response(isSuccess: true, result: nozzleMappings);
    } catch (e) {
      debugPrint('❌ [ApiHelper] Exception fetching map: $e');
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getFuelPrices() async {
    try {
      debugPrint(
          '🔍 [ApiHelper] GET ${Constans.getAPIUrl()}/api/v1/shifts/GetFuelPrices');
      final response = await _dio.get(
        '/api/v1/shifts/GetFuelPrices',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false,
            message: 'Status ${response.statusCode}: ${response.data}');
      }

      Map<String, double> prices = {};
      (response.data as Map).forEach((key, value) {
        prices[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
      });

      return Response(isSuccess: true, result: prices);
    } catch (e) {
      debugPrint('❌ [ApiHelper] Exception fetching fuel prices: $e');
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getFacturasByCierre(int? cierre) async {
    final response = await _dio.get(
        '/api/v1/facturacion/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Factura> facturas = [];
    if (response.data != null) {
      for (var item in response.data) {
        facturas.add(Factura.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: facturas);
  }

  /// Migrado 2026-04-18 al API nueva.
  /// Viejo: GET /api/Users/GetEmailsByCodigo/{codigo} → List<String>
  /// Nuevo: GET /api/v1/clientes/detalle/{codigo} → extraemos email principal + emails adicionales.
  static Future<Response> getEmailsBy(String codigo) async {
    final response =
        await _dio.get('/api/v1/clientes/detalle/$codigo');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }

    final data = response.data as Map<String, dynamic>?;
    final emails = <String>[];
    if (data != null) {
      final principal = data['email']?.toString();
      if (principal != null && principal.isNotEmpty) emails.add(principal);

      final extra = data['emails'];
      if (extra is List) {
        for (final e in extra) {
          final s = e?.toString();
          if (s != null && s.isNotEmpty && !emails.contains(s)) emails.add(s);
        }
      }
    }
    return Response(isSuccess: true, result: emails);
  }

  static Future<Response> getFacturasByCliente(String id) async {
    final response = await _dio.get(
        '/api/v1/facturacion/por-cliente/$id');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Factura> facturas = [];
    if (response.data != null) {
      for (var item in response.data) {
        facturas.add(Factura.fromJson(item));
      }
    }

    for (var fact in facturas) {
      for (var element in fact.detalles) {
        element.images.add(element.imageUrl);
      }
    }

    return Response(isSuccess: true, result: facturas);
  }

  static Future<Response> getFacturasCredito(int? cierre) async {
    final response = await _dio.get(
        '/api/v1/facturacion/credito/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Factura> facturas = [];
    if (response.data != null) {
      for (var item in response.data) {
        facturas.add(Factura.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: facturas);
  }

  static Future<Response> getTransaccionesByCierre(int? cierre) async {
    final response = await _dio.get(
        '/api/v1/transacciones/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Transaccion> transacciones = [];
    if (response.data != null) {
      for (var item in response.data) {
        transacciones.add(Transaccion.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transacciones);
  }

  static Future<Response> getPeddlersByCierre(int? cierre) async {
    final response = await _dio.get('/api/v1/peddlers/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Peddler> peddlers = [];
    if (response.data != null) {
      for (var item in response.data) {
        peddlers.add(Peddler.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: peddlers);
  }

  static Future<Response> getCierresDatafonos(int cierre) async {
    final response =
        await _dio.get('/api/v1/cierre-datafonos/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<CierreDatafono> cierres = [];
    if (response.data != null) {
      for (var item in response.data) {
        cierres.add(CierreDatafono.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: cierres);
  }

  static Future<Response> getViaticosByCierre(int cierre) async {
    final response = await _dio.get(
        '/api/v1/viaticos/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Viatico> viaticos = [];
    if (response.data != null) {
      for (var item in response.data) {
        viaticos.add(Viatico.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: viaticos);
  }

  static Future<Response> getCashBacks(int cierre) async {
    final response = await _dio.get('/api/v1/cashbacks/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Cashback> cashbacks = [];
    if (response.data != null) {
      for (var item in response.data) {
        cashbacks.add(Cashback.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: cashbacks);
  }

  static Future<Response> getSinpes(int cierre) async {
    final response = await _dio.get('/api/v1/sinpes/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Sinpe> sinpes = [];
    if (response.data != null) {
      for (var item in response.data) {
        sinpes.add(Sinpe.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: sinpes);
  }

  /// POST /api/v1/sinpes/ — crea un SINPE.
  /// Reemplaza `api/Sinpes/` del API vieja.
  static Future<Response> createSinpe(Sinpe sinpe) async {
    try {
      final resp = await _dio.post('/api/v1/sinpes/', data: sinpe.toJson());
      if (resp.statusCode! >= 400) {
        return Response(isSuccess: false, message: resp.data?.toString() ?? 'Error');
      }
      return Response(isSuccess: true, result: Sinpe.fromJson(resp.data));
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  /// DELETE /api/v1/sinpes/{id} — elimina un SINPE.
  /// Reemplaza `api/Sinpes/{id}` del API vieja.
  static Future<Response> deleteSinpe(int id) async {
    try {
      final resp = await _dio.delete('/api/v1/sinpes/$id');
      if (resp.statusCode! >= 400) {
        return Response(isSuccess: false, message: resp.data?.toString() ?? 'Error');
      }
      return Response(isSuccess: true);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getDepositos(int cierre) async {
    final response = await _dio.get('/api/v1/depositos/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Deposito> depositos = [];
    if (response.data != null) {
      for (var item in response.data) {
        depositos.add(Deposito.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: depositos);
  }

  static Future<Response> getBanks() async {
    final response =
        await _dio.get('/api/v1/cashbacks/bancos');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Bank> banks = [];
    if (response.data != null) {
      for (var item in response.data) {
        banks.add(Bank.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: banks);
  }

  static Future<Response> getDatafonos() async {
    final response =
        await _dio.get('/api/v1/cierre-datafonos/datafonos');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Datafono> datafonos = [];
    if (response.data != null) {
      for (var item in response.data) {
        datafonos.add(Datafono.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: datafonos);
  }

  // ══════════════════════════════════════════════════════════════
  // PAX Transactions
  // ══════════════════════════════════════════════════════════════

  static Future<Response> postTransaccionPax(
      Map<String, dynamic> request) async {
    try {
      final response =
          await _dio.post('/api/v1/transacciones-pax/', data: request);

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }
      return Response(isSuccess: true, result: response.data);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getTransaccionesPaxByFactura(int idFactura) async {
    try {
      final response =
          await _dio.get('/api/v1/transacciones-pax/factura/$idFactura');

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }

      List<TransaccionPax> transacciones = [];
      if (response.data != null) {
        for (var item in response.data) {
          transacciones.add(TransaccionPax.fromJson(item));
        }
      }
      return Response(isSuccess: true, result: transacciones);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getTransaccionesPaxByCierre(int idCierre) async {
    try {
      final response =
          await _dio.get('/api/v1/transacciones-pax/cierre/$idCierre');

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }

      List<TransaccionPax> transacciones = [];
      if (response.data != null) {
        for (var item in response.data) {
          transacciones.add(TransaccionPax.fromJson(item));
        }
      }
      return Response(isSuccess: true, result: transacciones);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getMoneys() async {
    final response =
        await _dio.get('/api/v1/depositos/monedas');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Money> moneys = [];
    if (response.data != null) {
      for (var item in response.data) {
        moneys.add(Money.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: moneys);
  }

  static Future<Response> getTransfes() async {
    final response =
        await _dio.get('/api/v1/transferencias/');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Transferview> transfers = [];
    if (response.data != null) {
      for (var item in response.data) {
        transfers.add(Transferview.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transfers);
  }

  static Future<Response> getTransfesByCierre(int cierre) async {
    final response = await _dio.get(
        '/api/v1/transferencias/por-cierre/$cierre');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<TransParcial> transfers = [];
    if (response.data != null) {
      for (var item in response.data) {
        transfers.add(TransParcial.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transfers);
  }

  static Future<Response> getTransaccionesAsProduct(int? zona) async {
    final response = await _dio.get(
        '/api/v1/transacciones/as-products/$zona');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Product> transacciones = [];
    if (response.data != null) {
      for (var item in response.data) {
        transacciones.add(Product.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: transacciones);
  }

  /// Deprecado — no lo consume ninguna pantalla. El API nuevo tiene
  /// /api/v1/transacciones/{id} pero devuelve Transaccion normal, no Product.
  /// Si se necesita, agregar endpoint `/{id}/as-product` en el server.
  static Future<Response> getTransaccionAsProductById(int? id) async {
    return Response(isSuccess: false, message: 'Endpoint deprecado');
  }

  static Future<Response> getUltimaTransaccion(
      int dispensador, DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('.').first;
    final url = '/api/v1/transacciones/ultima/$dispensador';
    debugPrint('🔍 [ApiHelper] GET $url?fecha=$fechaStr');
    debugPrint('   baseUrl: ${_dio.options.baseUrl}');

    try {
      final response = await _dio.get(url,
          queryParameters: {'fecha': fechaStr});

      debugPrint('   statusCode: ${response.statusCode}');
      debugPrint('   responseType: ${response.data.runtimeType}');
      debugPrint('   responseData: ${response.data}');

      if (response.statusCode! >= 400) {
        debugPrint('   ❌ HTTP error ${response.statusCode}');
        return Response(
            isSuccess: false, message: 'HTTP ${response.statusCode}: ${response.data}');
      }

      if (response.data != null) {
        Product product = Product.fromJson(response.data);
        debugPrint('   ✅ Product parsed: detalle=${product.detalle}, vol=${product.cantidad}, total=${product.total}');
        return Response(isSuccess: true, result: product);
      } else {
        debugPrint('   ⚠️ response.data is null');
        return Response(isSuccess: false, message: 'response.data is null');
      }
    } catch (e, st) {
      debugPrint('   ❌ EXCEPTION: $e');
      debugPrint('   stackTrace: $st');
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> getProducts(int? zona) async {
    final response = await _dio.get(
        '/api/v1/transacciones/products/$zona');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Product> products = [];
    if (response.data != null) {
      for (var item in response.data) {
        products.add(Product.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: products);
  }

  static Future<Response> getClienteContado() async {
    final response =
        await _dio.get('/api/v1/clientes/contado');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Cliente> clientes = [];
    if (response.data != null) {
      for (var item in response.data) {
        clientes.add(Cliente.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: clientes);
  }

  static Future<Response> getClienteContadoPaged({
    int page = 1,
    int pageSize = 50,
    int? minId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (minId != null && minId > 0) {
        queryParams['minId'] = minId;
      }

      debugPrint(
          '🌐 API Call: /api/v1/clientes/contado/paged $queryParams');

      final response = await _dio.get(
        '/api/v1/clientes/contado/paged',
        queryParameters: queryParams,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');

      if (response.statusCode! >= 400) {
        debugPrint('❌ Error Response: ${response.data}');
        return Response(
            isSuccess: false, message: response.data?.toString() ?? '');
      }

      final decodedJson = response.data;
      if (decodedJson == null) {
        debugPrint('❌ Response body is null');
        return Response(
            isSuccess: false, message: 'Respuesta vacía del servidor');
      }

      debugPrint(
          '📦 Response structure: ${(decodedJson as Map).keys.toList()}');

      List<Cliente> clientes = [];
      var dataList = decodedJson['data'];

      if (dataList != null && dataList is List) {
        debugPrint('✅ Found ${dataList.length} items in data array');
        for (var item in dataList) {
          clientes.add(Cliente.fromJson(item));
        }
      } else {
        debugPrint('⚠️ Data field is null or not a list');
      }

      var result = {
        'clientes': clientes,
        'page': decodedJson['page'] ?? page,
        'pageSize': decodedJson['pageSize'] ?? pageSize,
        'totalRecords': decodedJson['totalRecords'] ?? 0,
        'totalPages': decodedJson['totalPages'] ?? 0,
      };

      debugPrint(
          '✅ Returning ${clientes.length} clientes, page ${result['page']}/${result['totalPages']}');

      return Response(isSuccess: true, result: result);
    } catch (e, stackTrace) {
      debugPrint('💥 Exception in getClienteContadoPaged: $e');
      debugPrint('Stack trace: $stackTrace');
      return Response(
          isSuccess: false, message: 'Exception: ${e.toString()}');
    }
  }

  static Future<Response> getClientesTransfer() async {
    final response =
        await _dio.get('/api/v1/clientes/san-gerardo');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<Cliente> clientes = [];
    if (response.data != null) {
      for (var item in response.data) {
        clientes.add(Cliente.fromJson(item));
      }
    }
    return Response(isSuccess: true, result: clientes);
  }

  static Future<Response> getClientFrec(String codigo) async {
    final trimmed = codigo.trim();
    if (trimmed.isEmpty) {
      return Response(isSuccess: false, message: 'El código está vacío.');
    }

    try {
      final resp = await _dio.get(
        '/api/v1/clientes/frecuente/$trimmed',
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          headers: {'accept': 'application/json'},
        ),
      );

      if (resp.statusCode == 204) {
        return Response(isSuccess: false, message: 'Sin contenido (204).');
      }
      if (resp.statusCode! < 200 || resp.statusCode! >= 300) {
        final msg = _bestEffortMessage(resp.data);
        return Response(
            isSuccess: false,
            message: 'HTTP ${resp.statusCode}: $msg');
      }

      if (resp.data == null ||
          (resp.data is String && (resp.data as String).isEmpty)) {
        return Response(
            isSuccess: false, message: 'Respuesta vacía del servidor.');
      }

      final dynamic obj =
          (resp.data is List && (resp.data as List).isNotEmpty)
              ? resp.data.first
              : resp.data;

      if (obj == null || obj is! Map<String, dynamic>) {
        return Response(
            isSuccess: false,
            message: 'Formato inesperado de respuesta.');
      }

      final cliente = Cliente.fromJson(obj);
      return Response(isSuccess: true, result: cliente);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Response(
            isSuccess: false, message: 'Tiempo de espera agotado.');
      }
      if (e.error is SocketException) {
        return Response(
            isSuccess: false,
            message: 'Sin conexión a Internet o host no alcanzable.');
      }
      return Response(
          isSuccess: false, message: 'Error inesperado: $e');
    } on FormatException catch (e) {
      return Response(
          isSuccess: false, message: 'JSON inválido: ${e.message}');
    } catch (e) {
      return Response(
          isSuccess: false, message: 'Error inesperado: $e');
    }
  }

  static String _bestEffortMessage(dynamic data) {
    try {
      if (data is Map) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      }
      if (data is String) {
        final plain = data.replaceAll(RegExp(r'\s+'), ' ');
        return plain.length > 300 ? '${plain.substring(0, 300)}…' : plain;
      }
    } catch (_) {}
    return data.toString();
  }

  static Future<Response> getClienteFromHacienda(String document) async {
    final doc = document.trim();
    if (doc.isEmpty) {
      return Response(
          isSuccess: false, message: 'Debe indicar un documento.');
    }

    try {
      final resp = await _dio.get(
        '/api/v1/clientes/hacienda/$doc',
        options: Options(
          receiveTimeout: const Duration(seconds: 20),
          headers: {'accept': 'application/json'},
        ),
      );

      final status = resp.statusCode!;

      if (status >= 400) {
        String message;
        try {
          final j = resp.data;
          message = (j is Map && j['message'] is String)
              ? j['message'] as String
              : (resp.data == null ? 'Error $status' : resp.data.toString());
        } catch (_) {
          message = resp.data?.toString() ?? 'Error $status';
        }
        return Response(isSuccess: false, message: message);
      }

      if (resp.data == null) {
        return Response(
            isSuccess: false, message: 'Respuesta vacía del servidor.');
      }

      final decoded = resp.data;
      if (decoded is! Map<String, dynamic>) {
        return Response(
            isSuccess: false, message: 'Formato JSON inválido.');
      }

      late Cliente cliente;
      if (decoded.containsKey('tipoIdentificacion')) {
        cliente = Cliente.fromHaciendaJson(decoded);
      } else {
        cliente = Cliente.fromJson(decoded);
      }

      cliente.documento = doc;
      cliente.email = cliente.email;
      cliente.telefono = cliente.telefono;

      return Response(isSuccess: true, result: cliente);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Response(
            isSuccess: false,
            message:
                'Tiempo de espera agotado al consultar el servicio.');
      }
      return Response(
          isSuccess: false, message: 'Error inesperado: $e');
    } catch (e) {
      return Response(
          isSuccess: false, message: 'Error inesperado: $e');
    }
  }

  /// Migrado 2026-04-18 al API nueva.
  /// Viejo: PUT /api/Users/{id}  body: { email, emailAntiguo, codigo }
  /// Nuevo: DELETE viejo + POST nuevo en /api/v1/clientes/{codigo}/emails
  /// (en el viejo `id` era el código del cliente, no un id real de Users).
  static Future<Response> editEmail(
      String codigo, Map<String, dynamic> request) async {
    final emailNuevo = (request['email'] ?? request['Email'])?.toString();
    final emailAntiguo = (request['emailAntiguo'] ?? request['EmailAntiguo'])?.toString();

    if (emailNuevo == null || emailNuevo.isEmpty) {
      return Response(isSuccess: false, message: 'Email nuevo vacío');
    }

    try {
      // 1) Borrar el antiguo si viene (DELETE recibe el email como query param).
      if (emailAntiguo != null && emailAntiguo.isNotEmpty) {
        await _dio.delete(
          '/api/v1/clientes/$codigo/emails',
          queryParameters: {'email': emailAntiguo},
        );
      }
      // 2) Agregar el nuevo
      final resp = await _dio.post(
        '/api/v1/clientes/$codigo/emails',
        data: {'email': emailNuevo},
      );
      if (resp.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: resp.data?.toString() ?? '');
      }
      return Response(isSuccess: true);
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  static Future<Response> put(
      String controller, String id, Map<String, dynamic> request) async {
    final response =
        await _dio.put('/api/$controller/$id', data: request);

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    return Response(isSuccess: true);
  }

  static Future<Response> post(
      String controller, Map<String, dynamic> request) async {
    final response =
        await _dio.post('/$controller', data: request);

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    return Response(
      isSuccess: true,
      result: response.data,
    );
  }

  static Future<Response> postNoRequest(String controller) async {
    final response = await _dio.post('/$controller');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    return Response(isSuccess: true, result: response.data);
  }

  static Future<Response> delete(String controller, String id) async {
    final response =
        await _dio.delete('$controller$id');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }

    return Response(isSuccess: true);
  }

  /// Deprecado — el módulo Promo murió junto con Magic.
  /// Se deja el método por compat hasta limpiar los call-sites.
  /// Retorna lista vacía en vez de pegarle a una ruta que ya no existe.
  static Future<Response> getClientesPromo() async {
    return Response(isSuccess: true, result: <ClientePromo>[]);
  }

  /// Crear cliente contado — migrado 2026-04-18 al API nueva.
  /// Viejo: POST /api/clientes/crear con Cliente.toJson()
  /// Nuevo: POST /api/v1/clientes/contado con CrearClienteContadoRequest
  static Future<Response> crearClienteContado(Cliente cliente) async {
    final body = <String, dynamic>{
      'nombre': cliente.nombre,
      'cedula': cliente.documento,
      'codigoTipoId': cliente.codigoTipoID,  // API nueva usa 'd' minúscula
      'correo': cliente.email,
      'telefono': cliente.telefono,
      'codigoFrecuente': (cliente.codigoFrecuente ?? '').isEmpty ? null : cliente.codigoFrecuente,
      'codigoActividad': cliente.actividadSeleccionada?.codigo,
      'descripActividad': cliente.actividadSeleccionada?.descripcion,
    };

    try {
      final resp = await _dio.post('/api/v1/clientes/contado', data: body);
      if (resp.statusCode! >= 400) {
        return Response(isSuccess: false, message: resp.data?.toString() ?? '');
      }
      // La API devuelve ClienteDetalleResponse; mapeamos a Cliente para compat.
      if (resp.data is Map<String, dynamic>) {
        return Response(isSuccess: true, result: Cliente.fromJson(resp.data));
      }
      return Response(isSuccess: true, result: resp.data);
    } catch (e) {
      return Response(isSuccess: false, message: 'Exception: ${e.toString()}');
    }
  }

  /// Abrir un cierre nuevo desde la pantalla InventScreen — migrado 2026-04-18.
  /// Viejo: POST /Api/Users/CrearCierre → retornaba AllFact.
  /// Nuevo: POST /api/v1/caja/abrir-cierre → retorna CierreActivoResponse.
  /// Armamos el AllFact localmente (arrays vacíos igual que el viejo).
  static Future<Response> crearCierre({
    required int idzona,
    required int cedUsuario,
    required List<InventoryItem> inventario,
  }) async {
    try {
      final body = {
        'idzona': idzona,
        'cedUsuario': cedUsuario,
        'inventario': inventario.map((e) => e.toJson()).toList(),
      };
      final resp = await _dio.post('/api/v1/caja/abrir-cierre', data: body);
      if (resp.statusCode! >= 400) {
        return Response(isSuccess: false, message: resp.data?.toString() ?? '');
      }

      final cierreActivo = resp.data is Map<String, dynamic>
          ? CierreActivo.fromJson(resp.data)
          : CierreActivo.fromJson(<String, dynamic>{});

      final allFact = AllFact(
        lasTr: 0,
        cierreActivo: cierreActivo,
        transacciones: const [],
        productos: const [],
        clientesFacturacion: const [],
        clientesCredito: const [],
        clientesPromo: const [],
      );
      return Response(isSuccess: true, result: allFact);
    } catch (e) {
      return Response(isSuccess: false, message: 'Exception: ${e.toString()}');
    }
  }

  /// Agregar email a un cliente (contado o crédito).
  /// Reutiliza el endpoint POST /clientes/{codigo}/emails.
  static Future<Response> addEmail(String codigo, String email) async {
    try {
      final resp = await _dio.post(
        '/api/v1/clientes/$codigo/emails',
        data: {'email': email},
      );
      if (resp.statusCode! >= 400) {
        return Response(isSuccess: false, message: resp.data?.toString() ?? '');
      }
      return Response(isSuccess: true);
    } catch (e) {
      return Response(isSuccess: false, message: 'Exception: ${e.toString()}');
    }
  }

  /// Migrado 2026-04-18 al API nueva.
  /// Viejo: POST /api/Clientes/actividades/sincronizar  body { numeroDocumento, tipoCliente }
  /// Nuevo: POST /api/v1/clientes/{contado|credito}/{doc}/sincronizar-actividades
  /// Facturar contado/credito/ticket — POST sp_Facturar_Venta vía API nueva.
  /// Viejo: POST /Api/Facturacion/FacturaSp
  /// Nuevo: POST /api/v1/facturacion/crear
  ///
  /// Normaliza los keys históricos del request:
  ///   - cedualaUsuario (typo viejo) → cedulaUsuario
  ///   - Transferencia (capital)     → transferencia
  ///   - isticket (lowercase)        → isTicket
  ///
  /// Garantiza que `response.result` SIEMPRE sea `Map<String, dynamic>`.
  /// Los screens hacen `response.result as Map<String, dynamic>` sin jsonDecode.
  static Future<Response> facturar(Map<String, dynamic> request) async {
    final body = _normalizarFacturaRequest(request);
    try {
      final resp = await _dio.post('/api/v1/facturacion/crear', data: body);
      if (resp.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: resp.data?.toString() ?? 'Error');
      }
      return Response(isSuccess: true, result: _asMap(resp.data));
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  /// Crear devolución — POST sp_Devolucion_FromFacturaCompleta vía API nueva.
  static Future<Response> facturarDevolucion(Map<String, dynamic> request) async {
    try {
      final resp =
          await _dio.post('/api/v1/facturacion/devolucion', data: request);
      if (resp.statusCode! >= 400) {
        return Response(
            isSuccess: false, message: resp.data?.toString() ?? 'Error');
      }
      return Response(isSuccess: true, result: _asMap(resp.data));
    } catch (e) {
      return Response(isSuccess: false, message: e.toString());
    }
  }

  /// Garantiza `Map<String, dynamic>`: si ya es Map lo devuelve, si es String hace decode,
  /// si es null/otro devuelve mapa vacío.
  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _normalizarFacturaRequest(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    for (final e in src.entries) {
      final key = switch (e.key) {
        'cedualaUsuario' => 'cedulaUsuario', // corrige typo histórico
        'Transferencia' => 'transferencia',
        'isticket' => 'isTicket',
        _ => e.key,
      };
      out[key] = e.value;
    }
    return out;
  }

  static Future<Response> syncActividades(String documento,
      {String tipoCliente = "Contado"}) async {
    final doc = Uri.encodeComponent(documento.trim());
    final tipo = tipoCliente.toLowerCase() == "credito" ? "credito" : "contado";

    try {
      final response = await _dio.post(
        '/api/v1/clientes/$tipo/$doc/sincronizar-actividades',
      );

      if (response.statusCode! >= 400) {
        return Response(
            isSuccess: false,
            message: response.data?.toString() ?? '');
      }

      Cliente cliente = Cliente.fromJson(response.data);
      return Response(isSuccess: true, result: cliente);
    } catch (e) {
      return Response(
          isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }

  static Future<Response> syncActividadesCredito(String documento) async {
    final doc = Uri.encodeComponent(documento.trim());

    try {
      final resp = await _dio.post(
        '/api/v1/clientes/credito/$doc/sincronizar-actividades',
      );

      if (resp.statusCode! >= 400) {
        String msg;
        try {
          final body = resp.data;
          msg = body is Map && body['message'] is String
              ? body['message']
              : resp.data.toString();
        } catch (_) {
          msg = resp.data.toString();
        }
        return Response(isSuccess: false, message: msg);
      }

      final cliente = Cliente.fromJson(resp.data);
      return Response(isSuccess: true, result: cliente);
    } catch (e) {
      return Response(
          isSuccess: false, message: "Exception: ${e.toString()}");
    }
  }

  /// Deprecado — no tiene equivalente en el API nueva y tampoco se usa desde
  /// ninguna pantalla (código muerto histórico del viejo ApiHelper).
  /// Si algún día se necesita, vivir en console_api_helper (estado del terminal).
  static Future<Response> getFuelingPoints() async {
    return Response(isSuccess: false, message: 'Endpoint deprecado');
  }
}
