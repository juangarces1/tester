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

  // Paginación para clientes contado
  int _currentPageContado = 1;
  final int _pageSizeContado = 50;
  int _totalPagesContado = 0;
  int _totalRecordsContado = 0;
  bool _hasMoreContado = true;
  bool _isLoadingMoreContado = false;
  int _maxIdContado = 0;
  bool _isLoadingContadoSmart = false;
  bool _cargaContadoCompletada = false;

  // Getters públicos
  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;

  /// Peddler derivado SIEMPRE de la lista de crédito (evita des-sincronización)
  List<Cliente> get clientesPeddler =>
      _clientesCredito.where(_isPeddler).toList();

  bool get isLoading => _loadingCount > 0 || _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreContado => _hasMoreContado;
  bool get isLoadingMoreContado => _isLoadingMoreContado;
  int get currentPageContado => _currentPageContado;
  int get totalPagesContado => _totalPagesContado;
  int get totalRecordsContado => _totalRecordsContado;
  int get maxIdContado => _maxIdContado;
  bool get cargaContadoCompletada => _cargaContadoCompletada;

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

      // Cargar maxId guardado
      final maxIdStr = await CacheHelper.loadCache('clientes_contado_max_id');
      _maxIdContado = int.tryParse(maxIdStr ?? '0') ?? 0;
      debugPrint('MaxID cargado del cache: $_maxIdContado');

      // Cargar bandera de carga completada
      final completadaStr = await CacheHelper.loadCache('clientes_contado_carga_completada');
      _cargaContadoCompletada = completadaStr == 'true';
      debugPrint('Carga completada: $_cargaContadoCompletada');

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

  /// Carga TODO si cache vacío, o solo NUEVOS si cache existe
  Future<void> loadClientesContadoSmart() async {
    // Protección contra llamadas simultáneas
    if (_isLoadingContadoSmart) {
      debugPrint('⚠️ loadClientesContadoSmart ya está en ejecución, ignorando llamada');
      return;
    }

    _isLoadingContadoSmart = true;
    _loadingCount++;
    notifyListeners();

    try {
      debugPrint('🔍 Verificando estado de clientes contado...');
      debugPrint('  - En cache: ${_clientesContado.length}');
      debugPrint('  - Carga completada: $_cargaContadoCompletada');
      debugPrint('  - MaxID local: $_maxIdContado');

      // Si el cache está vacío, cargar todo
      if (_clientesContado.isEmpty) {
        debugPrint('Cache vacío, cargando todos los clientes...');
        await loadAllClientesContadoPaged();
        _updateMaxIdContado();
        return;
      }

      // Si la carga anterior no completó, continuar desde donde quedó
      if (!_cargaContadoCompletada) {
        debugPrint('⚠️ Carga anterior no completó, continuando...');
        // Continuar usando minId
        _updateMaxIdContado();
        await _continuarCargaDesdeMinId();
        return;
      }

      // Si ya tiene datos y completó, verificar si hay NUEVOS en el servidor
      debugPrint('✅ Cache completo, verificando si hay nuevos clientes...');
      await _cargarNuevosClientes();

    } catch (e) {
      _errorMessage = 'Error en sincronización: $e';
      debugPrint('Error in loadClientesContadoSmart: $e');
    } finally {
      _isLoadingContadoSmart = false;
      _loadingCount--;
      notifyListeners();
    }
  }

  /// Continúa la carga desde donde quedó usando minId
  Future<void> _continuarCargaDesdeMinId() async {
    debugPrint('♻️ Continuando carga desde id > $_maxIdContado...');

    int currentPage = 1;
    bool hasMore = true;
    List<Cliente> nuevosClientes = [];

    while (hasMore) {
      Response response = await ApiHelper.getClienteContadoPaged(
        page: currentPage,
        pageSize: _pageSizeContado,
        minId: _maxIdContado,
      );

      if (response.isSuccess) {
        final result = response.result as Map<String, dynamic>;
        List<Cliente> pagina = (result['clientes'] as List).cast<Cliente>();
        _totalRecordsContado = result['totalRecords'] ?? 0;

        nuevosClientes.addAll(pagina);

        int totalPages = result['totalPages'] ?? 0;
        hasMore = currentPage < totalPages;
        currentPage++;

        if (pagina.isNotEmpty) {
          debugPrint('Página $currentPage: +${pagina.length} clientes');
        }
      } else {
        _errorMessage = response.message;
        hasMore = false;
      }
    }

    if (nuevosClientes.isNotEmpty) {
      _clientesContado.addAll(nuevosClientes);
      _updateMaxIdContado();
      await _saveCacheBy(ClienteTipo.contado);
      _cargaContadoCompletada = true;
      await CacheHelper.saveCache('clientes_contado_carga_completada', 'true');
      debugPrint('✅ Carga completada: +${nuevosClientes.length} (total: ${_clientesContado.length})');
    } else {
      _cargaContadoCompletada = true;
      await CacheHelper.saveCache('clientes_contado_carga_completada', 'true');
      debugPrint('✅ No había clientes pendientes');
    }
  }

  /// Carga solo clientes nuevos (id > maxId actual)
  Future<void> _cargarNuevosClientes() async {
    int currentPage = 1;
    bool hasMore = true;
    List<Cliente> nuevosClientes = [];

    while (hasMore) {
      Response response = await ApiHelper.getClienteContadoPaged(
        page: currentPage,
        pageSize: _pageSizeContado,
        minId: _maxIdContado,
      );

      if (response.isSuccess) {
        final result = response.result as Map<String, dynamic>;
        List<Cliente> pagina = (result['clientes'] as List).cast<Cliente>();

        nuevosClientes.addAll(pagina);

        int totalPages = result['totalPages'] ?? 0;
        hasMore = currentPage < totalPages;
        currentPage++;
      } else {
        _errorMessage = response.message;
        hasMore = false;
      }
    }

    if (nuevosClientes.isNotEmpty) {
      _clientesContado.addAll(nuevosClientes);
      _updateMaxIdContado();
      await _saveCacheBy(ClienteTipo.contado);
      debugPrint('✅ Sincronizados ${nuevosClientes.length} clientes nuevos (total: ${_clientesContado.length})');
    } else {
      debugPrint('✅ No hay clientes nuevos');
    }
  }

  void _updateMaxIdContado() {
    if (_clientesContado.isEmpty) {
      _maxIdContado = 0;
      return;
    }

    // Encuentra el ID más alto (codigo es el id convertido a string)
    _maxIdContado = _clientesContado
        .map((c) => int.tryParse(c.codigo) ?? 0)
        .reduce((a, b) => a > b ? a : b);

    debugPrint('MaxID actualizado: $_maxIdContado');

    // Guardar en cache para persistencia
    CacheHelper.saveCache('clientes_contado_max_id', _maxIdContado.toString());
  }

  /// Carga TODAS las páginas de clientes contado recursivamente hasta agotarlas (desde cero)
  Future<void> loadAllClientesContadoPaged() async {
    _loadingCount++;
    _errorMessage = '';
    _currentPageContado = 1;
    _hasMoreContado = true;
    _clientesContado.clear();
    _cargaContadoCompletada = false;
    notifyListeners();

    int totalCargados = 0;
    debugPrint('🔄 Iniciando carga completa desde página 1');

    try {
      // Cargar páginas recursivamente hasta agotarlas
      while (_hasMoreContado) {
        Response response = await ApiHelper.getClienteContadoPaged(
          page: _currentPageContado,
          pageSize: _pageSizeContado,
        );

        if (response.isSuccess) {
          final result = response.result as Map<String, dynamic>;
          List<Cliente> nuevosClientes =
              (result['clientes'] as List).cast<Cliente>();
          _totalPagesContado = result['totalPages'] ?? 0;
          _totalRecordsContado = result['totalRecords'] ?? 0;

          _clientesContado.addAll(nuevosClientes);
          totalCargados += nuevosClientes.length;

          // Verificar si hay más páginas usando totalPages
          _hasMoreContado = _currentPageContado < _totalPagesContado;

          if (_hasMoreContado) {
            _currentPageContado++;
            debugPrint(
                'API load page $_currentPageContado/$_totalPagesContado: ${nuevosClientes.length} clientes (total: $totalCargados/$_totalRecordsContado)');
          } else {
            debugPrint(
                'API load completed: $totalCargados clientes contado cargados en total');
          }
        } else {
          _errorMessage =
              'Error al cargar los clientes al contado: ${response.message}';
          _hasMoreContado = false;
        }
      }

      // Guardar todo en cache al final
      await _saveCacheBy(ClienteTipo.contado);

      // Marcar carga como completada
      _cargaContadoCompletada = true;
      await CacheHelper.saveCache('clientes_contado_carga_completada', 'true');
      debugPrint('Cache actualizado con $totalCargados clientes contado');
      debugPrint('✅ Carga completada exitosamente');

    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
      _cargaContadoCompletada = false;
      await CacheHelper.saveCache('clientes_contado_carga_completada', 'false');
      debugPrint('Error in loadAllClientesContadoPaged: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  /// Carga la primera página de clientes contado con paginación
  Future<void> loadClientesContadoPaged() async {
    _loadingCount++;
    _currentPageContado = 1;
    _hasMoreContado = true;
    _errorMessage = '';
    notifyListeners();

    try {
      Response response = await ApiHelper.getClienteContadoPaged(
        page: _currentPageContado,
        pageSize: _pageSizeContado,
      );

      if (response.isSuccess) {
        final result = response.result as Map<String, dynamic>;
        _clientesContado = (result['clientes'] as List).cast<Cliente>();
        _totalPagesContado = result['totalPages'] ?? 0;
        _totalRecordsContado = result['totalRecords'] ?? 0;
        _hasMoreContado = _currentPageContado < _totalPagesContado;
        await _saveCacheBy(ClienteTipo.contado);
        debugPrint(
            'API load paged: ${_clientesContado.length} clientes contado (page $_currentPageContado/$_totalPagesContado)');
      } else {
        _errorMessage =
            'Error al cargar los clientes al contado: ${response.message}';
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
      debugPrint('Error in loadClientesContadoPaged: $e');
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  /// Carga más páginas de clientes contado
  Future<void> loadMoreClientesContado() async {
    if (_isLoadingMoreContado || !_hasMoreContado) return;

    _isLoadingMoreContado = true;
    _currentPageContado++;
    _errorMessage = '';
    notifyListeners();

    try {
      Response response = await ApiHelper.getClienteContadoPaged(
        page: _currentPageContado,
        pageSize: _pageSizeContado,
      );

      if (response.isSuccess) {
        final result = response.result as Map<String, dynamic>;
        List<Cliente> newClientes =
            (result['clientes'] as List).cast<Cliente>();
        _totalPagesContado = result['totalPages'] ?? 0;
        _totalRecordsContado = result['totalRecords'] ?? 0;
        _clientesContado.addAll(newClientes);
        _hasMoreContado = _currentPageContado < _totalPagesContado;
        await _saveCacheBy(ClienteTipo.contado);
        debugPrint(
            'API load more: ${newClientes.length} clientes contado (page $_currentPageContado/$_totalPagesContado)');
      } else {
        _errorMessage = 'Error al cargar más clientes: ${response.message}';
        _currentPageContado--; // Revertir incremento de página
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
      _currentPageContado--; // Revertir incremento de página
      debugPrint('Error in loadMoreClientesContado: $e');
    } finally {
      _isLoadingMoreContado = false;
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
