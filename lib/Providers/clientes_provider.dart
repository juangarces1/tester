import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/cache_helper.dart';

enum ClienteTipo { contado, credito, promo, peddler }

class ClienteProvider with ChangeNotifier {
  // Estado interno
  List<Cliente> _clientesContado = [];
  List<Cliente> _clientesCredito = [];
  List<ClientePromo> _clientesPromo = [];
  final bool _isLoading = false;
  int _loadingCount = 0;
  String? _errorMessage;

  // Getters públicos
  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;

  /// Peddler derivado SIEMPRE de la lista de crédito (evita des-sincronización)
  List<Cliente> get clientesPeddler =>
      _clientesCredito.where(_isPeddler).toList();

  bool get isLoading => _loadingCount > 0 || _isLoading;
  String? get errorMessage => _errorMessage;

  /// Acceso unificado para listas de Cliente (no aplica a 'promo')
  List<Cliente> clientesBy(ClienteTipo tipo) {
    switch (tipo) {
      case ClienteTipo.contado:
        return _clientesContado;
      case ClienteTipo.credito:
        return _clientesCredito;
      case ClienteTipo.peddler:
        return clientesBy(ClienteTipo.credito).where(_isPeddler).toList();
      case ClienteTipo.promo:
        return const [];
    }
  }

  /// Inicializa cargando datos desde el cache local
  Future<void> initialize() async {
    _loadingCount++;
    notifyListeners();

    try {
      final contadoJson = await CacheHelper.loadCache('clientes_contado');
      if (contadoJson != null) {
        _clientesContado = (jsonDecode(contadoJson) as List)
            .map((e) => Cliente.fromJson(e))
            .toList();
        debugPrint('Cache loaded: ${_clientesContado.length} clientes contado');
      }

      final creditoJson = await CacheHelper.loadCache('clientes_credito');
      if (creditoJson != null) {
        final List<Cliente> clientes = [];
        var decodedJson = jsonDecode(creditoJson);
        if (decodedJson != null) {
          for (var item in decodedJson) {
            try {
              clientes.add(Cliente.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing single credit client (plural): $e');
            }
          }
        }
        _clientesCredito = clientes;
        debugPrint('Cache loaded: ${_clientesCredito.length} clientes crédito');
      }

      final promoJson = await CacheHelper.loadCache('clientes_promo');
      if (promoJson != null) {
        _clientesPromo = (jsonDecode(promoJson) as List)
            .map((e) => ClientePromo.fromJson(e))
            .toList();
        debugPrint('Cache loaded: ${_clientesPromo.length} clientes promo');
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  /// Carga según tipo. Para 'peddler' garantiza primero la carga de crédito.
  Future<void> loadClientesBy(ClienteTipo tipo) async {
    _loadingCount++;
    notifyListeners();

    try {
      Response response;
      _errorMessage = '';

      switch (tipo) {
        case ClienteTipo.contado:
          response = await ApiHelper.getClienteContado();
          if (response.isSuccess) {
            _clientesContado = (response.result as List).cast<Cliente>();
            await _saveCacheBy(ClienteTipo.contado);
            debugPrint('API load: ${_clientesContado.length} clientes contado');
          } else {
            _errorMessage =
                'Error al cargar los clientes al contado: ${response.message}';
          }
          break;

        case ClienteTipo.credito:
          response = await ApiHelper.getClientesCredito();
          debugPrint('API Response Success (Credito): ${response.isSuccess}');
          if (response.isSuccess) {
            final list = (response.result as List);
            debugPrint('API Received: ${list.length} raw items for credit');

            final List<Cliente> parsed = [];
            for (var item in list) {
              if (item is Cliente) {
                parsed.add(item);
              } else {
                debugPrint(
                    'Unexpected item type in credit result: ${item.runtimeType}');
              }
            }

            _clientesCredito = parsed;
            await _saveCacheBy(ClienteTipo.credito);
            debugPrint(
                'Credit List updated with ${parsed.length} items. Notify listeners.');
          } else {
            debugPrint('API Error Credit: ${response.message}');
            _errorMessage =
                'Error al cargar los clientes a crédito: ${response.message}';
          }
          break;

        case ClienteTipo.peddler:
          // Fuente es crédito; si no está cargado, se carga.
          if (_clientesCredito.isEmpty) {
            final r = await ApiHelper.getClientesCredito();
            if (r.isSuccess) {
              _clientesCredito = (r.result as List).cast<Cliente>();
              await _saveCacheBy(ClienteTipo.credito);
              debugPrint(
                  'Peddler refresh: ${_clientesCredito.length} clientes cached');
            } else {
              _errorMessage = 'Error al cargar los clientes a crédito';
            }
          }
          break;

        case ClienteTipo.promo:
          response = await ApiHelper.getClientesPromo();
          if (response.isSuccess) {
            _clientesPromo = (response.result as List).cast<ClientePromo>();
            await _saveCacheBy(ClienteTipo.promo);
            debugPrint('API load: ${_clientesPromo.length} clientes promo');
          } else {
            _errorMessage =
                'Error al cargar clientes promo: ${response.message}';
          }
          break;
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
      debugPrint('Error in loadClientesBy: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  void upsertClienteBy(Cliente c,
      {required ClienteTipo tipo, bool asFirst = true}) {
    // Si es peddler, operamos sobre la lista de crédito
    final targetTipo =
        (tipo == ClienteTipo.peddler) ? ClienteTipo.credito : tipo;

    // Seleccionamos la lista correcta según el tipo real
    List<dynamic> list;
    if (targetTipo == ClienteTipo.contado) {
      list = _clientesContado;
    } else if (targetTipo == ClienteTipo.credito) {
      list = _clientesCredito;
    } else {
      list = _clientesPromo;
    }

    final id = _idOf(c);
    final idx = list.indexWhere((x) => _idOf(x) == id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      asFirst ? list.insert(0, c) : list.add(c);
    }
    notifyListeners();
    _saveCacheBy(targetTipo);
  }

  Future<void> _saveCacheBy(ClienteTipo tipo) async {
    try {
      switch (tipo) {
        case ClienteTipo.contado:
          await CacheHelper.saveCache('clientes_contado',
              jsonEncode(_clientesContado.map((e) => e.toJson()).toList()));
          break;
        case ClienteTipo.credito:
        case ClienteTipo.peddler:
          await CacheHelper.saveCache('clientes_credito',
              jsonEncode(_clientesCredito.map((e) => e.toJson()).toList()));
          break;
        case ClienteTipo.promo:
          await CacheHelper.saveCache('clientes_promo',
              jsonEncode(_clientesPromo.map((e) => e.toJson()).toList()));
          break;
      }
    } catch (e) {
      debugPrint('Error in _saveCacheBy: $e');
    }
  }

  /// Sincroniza actividades para un cliente de CRÉDITO
  Future<void> syncActividadesCreditoBy(String documento) async {
    _loadingCount++;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiHelper.syncActividadesCredito(documento);
      if (res.isSuccess) {
        final updated = res.result as Cliente;
        upsertClienteBy(updated, tipo: ClienteTipo.credito);
      } else {
        _errorMessage = res.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  /// Sincroniza actividades para un cliente de CONTADO
  Future<void> syncActividadesContadoBy(String documento) async {
    _loadingCount++;
    _errorMessage = null;
    notifyListeners();

    try {
      final res =
          await ApiHelper.syncActividades(documento, tipoCliente: "Contado");
      if (res.isSuccess) {
        final updated = res.result as Cliente;
        upsertClienteBy(updated, tipo: ClienteTipo.contado);
      } else {
        _errorMessage = res.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  bool _isPeddler(Cliente c) => (c.tipo ?? '').toLowerCase() == 'peddler';

  String _idOf(dynamic c) {
    if (c is Cliente) {
      final codigo = (c.codigo).trim();
      if (codigo.isNotEmpty) return codigo;
      return c.documento.trim();
    }
    if (c is ClientePromo) {
      return c.id.toString(); // Usamos ID para promos
    }
    return '';
  }

  void setClientesContado(List<Cliente> list) {
    _clientesContado = list;
    _saveCacheBy(ClienteTipo.contado);
    notifyListeners();
  }

  void setClientesCredito(List<Cliente> list) {
    _clientesCredito = list;
    _saveCacheBy(ClienteTipo.credito);
    notifyListeners();
  }

  void reset() {
    _clientesContado = [];
    _clientesCredito = [];
    _clientesPromo = [];
    _errorMessage = null;
    notifyListeners();
  }
}
