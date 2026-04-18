import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Providers/clientes_repository.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/cache_helper.dart';

enum ClienteTipo { contado, credito, promo, peddler }

/// Provider de clientes — backing store:
///   - Contado (16k+): SQLite local vía [ClientesRepository]
///   - Crédito/Peddler/Promo: JSON en disco (CacheHelper) — volúmenes chicos
///
/// Mantiene la API pública igual que antes (clientesContado getter, loadClientesBy,
/// upsertClienteBy, etc.) para que las pantallas no cambien; agrega
/// `searchContado` para búsquedas indexadas rápidas.
class ClienteProvider with ChangeNotifier {
  ClienteProvider({ClientesRepository? repository})
      : _repo = repository ?? ClientesRepository();

  final ClientesRepository _repo;

  // Estado en memoria (lista viva que las pantallas iteran).
  List<Cliente> _clientesContado = [];
  List<Cliente> _clientesCredito = [];
  List<ClientePromo> _clientesPromo = [];
  int _loadingCount = 0;
  String? _errorMessage;
  bool _isLoadingContadoSmart = false;

  // Getters públicos
  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;

  /// Peddler derivado SIEMPRE de la lista de crédito (evita des-sincronización)
  List<Cliente> get clientesPeddler =>
      _clientesCredito.where(_isPeddler).toList();

  bool get isLoading => _loadingCount > 0;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMoreContado => _isLoadingContadoSmart;

  /// Acceso unificado para listas de Cliente (no aplica a 'promo')
  List<Cliente> clientesBy(ClienteTipo tipo) {
    switch (tipo) {
      case ClienteTipo.contado:
        return _clientesContado;
      case ClienteTipo.credito:
        return _clientesCredito;
      case ClienteTipo.peddler:
        return _clientesCredito.where(_isPeddler).toList();
      case ClienteTipo.promo:
        return const [];
    }
  }

  // ──────────────────────── INIT ─────────────────────────────────────

  /// Carga los clientes del store local al arrancar la app.
  /// Contado: desde SQLite (rápido).
  /// Crédito/Promo: desde JSON files (estrategia legacy, volúmenes chicos).
  Future<void> initialize() async {
    _loadingCount++;
    notifyListeners();

    try {
      _clientesContado = await _repo.getAllContado();
      debugPrint(
          'Cache SQLite loaded: ${_clientesContado.length} clientes contado');

      final creditoJson = await CacheHelper.loadCache('clientes_credito');
      if (creditoJson != null) {
        final list = <Cliente>[];
        final decoded = jsonDecode(creditoJson);
        if (decoded is List) {
          for (final item in decoded) {
            try {
              list.add(Cliente.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing credit client: $e');
            }
          }
        }
        _clientesCredito = list;
        debugPrint('Cache loaded: ${_clientesCredito.length} clientes crédito');
      }

      final promoJson = await CacheHelper.loadCache('clientes_promo');
      if (promoJson != null) {
        final decoded = jsonDecode(promoJson);
        if (decoded is List) {
          _clientesPromo =
              decoded.map((e) => ClientePromo.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  // ──────────────────────── SYNC CONTADO ─────────────────────────────

  /// Sync inteligente contado — delega al repository (SQLite + incremental).
  Future<void> loadClientesContadoSmart() async {
    if (_isLoadingContadoSmart) {
      debugPrint('⚠️ loadClientesContadoSmart ya en ejecución');
      return;
    }

    _isLoadingContadoSmart = true;
    _loadingCount++;
    notifyListeners();

    try {
      final result = await _repo.syncContadoSmart();
      if (!result.ok) {
        _errorMessage = 'Sync contado falló: ${result.message}';
      } else {
        _clientesContado = await _repo.getAllContado();
        debugPrint('✅ Sync contado: ${_clientesContado.length} en cache');
      }
    } catch (e) {
      _errorMessage = 'Error en sincronización: $e';
      debugPrint('Error loadClientesContadoSmart: $e');
    } finally {
      _isLoadingContadoSmart = false;
      _loadingCount--;
      notifyListeners();
    }
  }

  // ──────────────────────── LOAD POR TIPO ────────────────────────────

  Future<void> loadClientesBy(ClienteTipo tipo) async {
    _loadingCount++;
    notifyListeners();

    try {
      _errorMessage = '';
      switch (tipo) {
        case ClienteTipo.contado:
          // Para contado preferimos syncContadoSmart (SQLite + incremental).
          await loadClientesContadoSmart();
          return;

        case ClienteTipo.credito:
          final resp = await ApiHelper.getClientesCredito();
          if (resp.isSuccess) {
            final raw = (resp.result as List);
            final parsed = <Cliente>[];
            for (final item in raw) {
              if (item is Cliente) parsed.add(item);
            }
            _clientesCredito = parsed;
            await _saveCacheBy(ClienteTipo.credito);
            debugPrint('Crédito: ${parsed.length} items cacheados');
          } else {
            _errorMessage = 'Error al cargar crédito: ${resp.message}';
          }
          break;

        case ClienteTipo.peddler:
          if (_clientesCredito.isEmpty) {
            await loadClientesBy(ClienteTipo.credito);
          }
          break;

        case ClienteTipo.promo:
          final resp = await ApiHelper.getClientesPromo();
          if (resp.isSuccess) {
            _clientesPromo = (resp.result as List).cast<ClientePromo>();
            await _saveCacheBy(ClienteTipo.promo);
          } else {
            _errorMessage = 'Error al cargar promo: ${resp.message}';
          }
          break;
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: $e';
      debugPrint('Error loadClientesBy: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  // ──────────────────────── SEARCH (SQLite indexado) ─────────────────

  /// Busca contado con SQL indexado (por nombre/documento/codigo frec).
  /// Las pantallas que lo usen evitan iterar 16k items en memoria.
  Future<List<Cliente>> searchContado(String q, {int limit = 50}) =>
      _repo.searchContado(q, limit: limit);

  // ──────────────────────── UPSERT / SET ─────────────────────────────

  void setClientesContado(List<Cliente> list) {
    _clientesContado = list;
    notifyListeners();
    // Persistir a SQLite async (no bloquea UI).
    // Si hay que persistir exactamente esta lista (distinta del backend),
    // usamos syncContadoFull que limpia y re-inserta. Para invent-screen
    // esta lista viene ya del backend, así que el sync siguiente será trivial.
    _repo.syncContadoFull().catchError((e) {
      debugPrint('Error al persistir clientes contado: $e');
      return SyncResult(ok: false, message: e.toString());
    });
  }

  void setClientesCredito(List<Cliente> list) {
    _clientesCredito = list;
    _saveCacheBy(ClienteTipo.credito);
    notifyListeners();
  }

  void upsertClienteBy(Cliente c,
      {required ClienteTipo tipo, bool asFirst = true}) {
    final target = (tipo == ClienteTipo.peddler) ? ClienteTipo.credito : tipo;

    late List<dynamic> list;
    if (target == ClienteTipo.contado) {
      list = _clientesContado;
    } else if (target == ClienteTipo.credito) {
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

    // Contado también se persiste en SQLite (single upsert).
    if (target == ClienteTipo.contado) {
      _repo.upsertContadoSingle(c).catchError((e) {
        debugPrint('Error upsert contado en SQLite: $e');
      });
    } else {
      _saveCacheBy(target);
    }

    notifyListeners();
  }

  // ──────────────────────── SYNC ACTIVIDADES ─────────────────────────

  Future<void> syncActividadesCreditoBy(String documento) async {
    _loadingCount++;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiHelper.syncActividadesCredito(documento);
      if (res.isSuccess) {
        upsertClienteBy(res.result as Cliente, tipo: ClienteTipo.credito);
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

  Future<void> syncActividadesContadoBy(String documento) async {
    _loadingCount++;
    _errorMessage = null;
    notifyListeners();
    try {
      final res =
          await ApiHelper.syncActividades(documento, tipoCliente: 'Contado');
      if (res.isSuccess) {
        upsertClienteBy(res.result as Cliente, tipo: ClienteTipo.contado);
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

  // ──────────────────────── HELPERS ──────────────────────────────────

  Future<void> _saveCacheBy(ClienteTipo tipo) async {
    try {
      switch (tipo) {
        case ClienteTipo.contado:
          // contado vive en SQLite — no se escribe a JSON.
          break;
        case ClienteTipo.credito:
        case ClienteTipo.peddler:
          await CacheHelper.saveCache(
              'clientes_credito',
              jsonEncode(_clientesCredito.map((e) => e.toJson()).toList()));
          break;
        case ClienteTipo.promo:
          await CacheHelper.saveCache(
              'clientes_promo',
              jsonEncode(_clientesPromo.map((e) => e.toJson()).toList()));
          break;
      }
    } catch (e) {
      debugPrint('Error _saveCacheBy: $e');
    }
  }

  bool _isPeddler(Cliente c) => (c.tipo ?? '').toLowerCase() == 'peddler';

  String _idOf(dynamic c) {
    if (c is Cliente) {
      final codigo = c.codigo.trim();
      if (codigo.isNotEmpty) return codigo;
      return c.documento.trim();
    }
    if (c is ClientePromo) return c.id.toString();
    return '';
  }

  void reset() {
    _clientesContado = [];
    _clientesCredito = [];
    _clientesPromo = [];
    _errorMessage = null;
    notifyListeners();
  }
}
