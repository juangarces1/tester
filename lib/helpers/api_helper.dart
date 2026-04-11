import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';
import 'package:tester/Models/FuelRed/nozzle_mapping.dart';
import 'package:tester/Models/LogIn/inventory_item.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/ResumenCierre/cierre_caja_general.dart';
import 'package:tester/Models/FuelRed/all_fact.dart';
import 'package:tester/Models/FuelRed/bank.dart';
import 'package:tester/Models/FuelRed/cashback.dart';
import 'package:tester/Models/FuelRed/cierreactivo.dart';
import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/cliente.dart';

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
    final response = await _dio.get('/api/Caja/$cierre');

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

  static Future<Response> getCierreActivo(String cierre) async {
    final response =
        await _dio.get('/api/Caja/GetCierreActivo/$cierre');

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

  static Future<Response> preCierre(String cierre) async {
    final response =
        await _dio.get('/api/Facturacion/SranbyCierre/$cierre');

    if (response.statusCode == 200) {
      return Response(isSuccess: true, result: response.data);
    } else if (response.statusCode == 204) {
      return Response(isSuccess: true, message: '', result: []);
    } else {
      return Response(
          isSuccess: false, message: "Error: ${response.data}");
    }
  }

  static Future<Response> setCierre(String cierre) async {
    final response =
        await _dio.get('/api/Facturacion/CrearCierre/$cierre');

    if (response.statusCode == 200) {
      return Response(isSuccess: true, result: response.data);
    } else if (response.statusCode == 204) {
      return Response(isSuccess: true, message: '', result: []);
    } else {
      return Response(
          isSuccess: false, message: "Error: ${response.data}");
    }
  }

  static Future<Response> getLogIn(int? zona, int? cedula) async {
    try {
      final response =
          await _dio.get('/api/users/GetLogInOpen/$zona-$cedula');

      if (response.statusCode == 200) {
        return Response(
            isSuccess: true, result: AllFact.fromJson(response.data));
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

  static Future<Response> getLogInNuevo(int? zona, int? cedula) async {
    try {
      final response =
          await _dio.get('/api/users/GetLogInNuevo/$zona-$cedula');

      if (response.statusCode == 200) {
        return Response(
            isSuccess: true, result: AllFact.fromJson(response.data));
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

  static Future<Response> getInventarioInicial(int? zona) async {
    try {
      final response =
          await _dio.get('/api/users/GetInventInicial/$zona');

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

  static Future<Response> getFactura(String id) async {
    try {
      final response =
          await _dio.get('/api/Facturacion/GetFacturaByNum/$id');

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
        await _dio.get('/api/Clientes/GetClientsYam');

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
          '/api/Caja/GetCierreByDia/${VariosHelpers.formatYYYYmmDD(dia)}');

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
        '/api/TransaccionesApi/GetTransaccionesByZona/$zona');

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
          '🔍 [ApiHelper] GET ${Constans.getAPIUrl()}/api/Shifts/GetHoseKeyMap/');
      final response = await _dio.get(
        '/api/Shifts/GetHoseKeyMap/',
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
          '🔍 [ApiHelper] GET ${Constans.getAPIUrl()}/api/Shifts/GetFuelPrices');
      final response = await _dio.get(
        '/api/Shifts/GetFuelPrices',
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
        '/api/Facturacion/GetFacturasByCierre/$cierre');

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

  static Future<Response> getEmailsBy(String codigo) async {
    final response =
        await _dio.get('/api/Users/GetEmailsByCodigo/$codigo');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<String> emails = [];
    if (response.data != null) {
      for (var item in response.data) {
        emails.add(item);
      }
    }
    return Response(isSuccess: true, result: emails);
  }

  static Future<Response> getFacturasByCliente(String id) async {
    final response = await _dio.get(
        '/api/Facturacion/GetFacturasByCliente/$id');

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
        '/api/Facturacion/GetFacturasCreditByCierre/$cierre');

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
        '/api/TransaccionesApi/GetTransaccionesByCierre/$cierre');

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
    final response = await _dio.get('/api/Peddler/$cierre');

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
        await _dio.get('/api/CierreDatafonos/$cierre');

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
        '/api/Viaticos/GetViaticoByCierre/$cierre');

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
    final response = await _dio.get('/api/Cashbacks/$cierre');

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
    final response = await _dio.get('/api/Sinpes/$cierre');

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

  static Future<Response> getDepositos(int cierre) async {
    final response = await _dio.get('/api/Depositos/$cierre');

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
        await _dio.get('/api/Cashbacks/GetBanks');

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
        await _dio.get('/api/CierreDatafonos/GetDatafonos');

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
          await _dio.post('/api/TransaccionesPax', data: request);

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
          await _dio.get('/api/TransaccionesPax/factura/$idFactura');

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
          await _dio.get('/api/TransaccionesPax/cierre/$idCierre');

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
        await _dio.get('/api/Depositos/GetMoneys');

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
        await _dio.get('/api/Transferencias/GetTransfers');

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
        '/api/Transferencias/GetTransfersByCierre/$cierre');

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
        '/api/TransaccionesApi/GetTransaccionesByZonaAsProducts/$zona');

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

  static Future<Response> getTransaccionAsProductById(int? id) async {
    final response = await _dio.get(
        '/api/TransaccionesApi/GetTransaccionByIdAsProducts/$id');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }

    if (response.data != null) {
      Product product = Product.fromJson(response.data);
      return Response(isSuccess: true, result: product);
    } else {
      return Response(isSuccess: false, message: 'Error al decodificar');
    }
  }

  static Future<Response> getUltimaTransaccion(
      int dispensador, DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('.').first;
    final url = '/api/TransaccionesApi/GetUltimaTransaccion/$dispensador';
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
        '/api/TransaccionesApi/GetProducts/$zona');

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
        await _dio.get('/api/Clientes/GetClientsContado');

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
          '🌐 API Call: /api/Clientes/GetClientsContadoPaged $queryParams');

      final response = await _dio.get(
        '/api/Clientes/GetClientsContadoPaged',
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
        await _dio.get('/api/Otros/GetClientesSanGerardo');

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
        '/api/Clientes/GetClientFrecuenteByCodigoFrecuente/$trimmed',
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
        '/api/Clientes/buscar/$doc',
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

  static Future<Response> editEmail(
      String id, Map<String, dynamic> request) async {
    final response =
        await _dio.put('/api/Users/$id', data: request);

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    return Response(isSuccess: true);
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

  static Future<Response> getClientesPromo() async {
    final response = await _dio.get(
        '/api/TransaccionesApi/GetClientesPromo');

    if (response.statusCode! >= 400) {
      return Response(
          isSuccess: false, message: response.data?.toString() ?? '');
    }
    List<ClientePromo> clientes = [];
    if (response.data != null) {
      for (var item in response.data) {
        try {
          clientes.add(ClientePromo.fromJson(item));
        } catch (e) {
          debugPrint('Error parsing single promo client: $e');
        }
      }
    }
    return Response(isSuccess: true, result: clientes);
  }

  static Future<Response> syncActividades(String documento,
      {String tipoCliente = "Contado"}) async {
    final body = {
      "numeroDocumento": documento,
      "tipoCliente": tipoCliente,
    };

    try {
      final response = await _dio.post(
        '/api/Clientes/actividades/sincronizar',
        data: body,
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
        '/api/Clientes/clientes/$doc/actividades/credito',
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

  static Future<Response> getFuelingPoints() async {
    try {
      debugPrint(
          '🔍 [ApiHelper] GET ${Constans.getAPIUrl()}/api/Shifts/GetFuelingPoints');
      final response = await _dio.get(
        '/api/Shifts/GetFuelingPoints',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode! >= 400) {
        debugPrint(
            '❌ [ApiHelper] Error ${response.statusCode}: ${response.data}');
        return Response(
            isSuccess: false,
            message: 'Status ${response.statusCode}: ${response.data}');
      }

      if (response.data != null) {
        final data = DispensersStatusResponse.fromJson(response.data);
        return Response(isSuccess: true, result: data);
      }
      return Response(isSuccess: false, message: 'Respuesta vacía');
    } catch (e) {
      debugPrint(
          '❌ [ApiHelper] Exception fetching fueling points: $e');
      return Response(isSuccess: false, message: e.toString());
    }
  }
}
