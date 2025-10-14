import 'package:flutter/material.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/helpers/api_helper.dart';

enum ClienteTipo { contado, credito, promo, peddler }

class ClienteProvider with ChangeNotifier {
  // Estado interno
  List<Cliente> _clientesContado = [];
  List<Cliente> _clientesCredito = [];
  List<ClientePromo> _clientesPromo = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters públicos
  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;

  /// Peddler derivado SIEMPRE de la lista de crédito (evita des-sincronización)
  List<Cliente> get clientesPeddler =>
      _clientesCredito.where(_isPeddler).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Acceso unificado para listas de Cliente (no aplica a 'promo')
  List<Cliente> clientesBy(ClienteTipo tipo) {
    switch (tipo) {
      case ClienteTipo.contado:
        return _clientesContado;
      case ClienteTipo.credito:
        return _clientesCredito;
      case ClienteTipo.peddler:
        return clientesPeddler; // derivado de crédito
      case ClienteTipo.promo:
        // 'promo' es List<ClientePromo>; devolvemos vacío para mantener la firma.
        return const [];
    }
  }

  /// Carga según tipo. Para 'peddler' garantiza primero la carga de crédito.
  Future<void> loadClientesBy(ClienteTipo tipo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      late Response response;

      switch (tipo) {
        case ClienteTipo.contado:
          response = await ApiHelper.getClienteContado();
          if (response.isSuccess) {
            _clientesContado = (response.result as List).cast<Cliente>();
          } else {
            _errorMessage = 'Error al cargar los clientes al contado';
          }
          break;

        case ClienteTipo.credito:
          response = await ApiHelper.getClientesCredito();
          if (response.isSuccess) {
            _clientesCredito = (response.result as List).cast<Cliente>();
          } else {
            _errorMessage = 'Error al cargar los clientes a crédito';
          }
          break;

        case ClienteTipo.peddler:
          // Fuente es crédito; si no está cargado, se carga.
          if (_clientesCredito.isEmpty) {
            final r = await ApiHelper.getClientesCredito();
            if (r.isSuccess) {
              _clientesCredito = (r.result as List).cast<Cliente>();
            } else {
              _errorMessage = 'Error al cargar los clientes a crédito';
            }
          }
          // No asignamos nada más; clientesPeddler se calcula con el getter.
          break;

        case ClienteTipo.promo:
          response = await ApiHelper.getClientesPromo();
          if (response.isSuccess) {
            _clientesPromo = (response.result as List).cast<ClientePromo>();
          } else {
            _errorMessage = 'Error al cargar clientes promo';
          }
          break;
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sincroniza actividades para un cliente de CRÉDITO por documento
  Future<void> syncActividadesCreditoBy(String documento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiHelper.syncActividadesCredito(documento);
      if (res.isSuccess) {
        final actualizado = res.result as Cliente;
        final id = _idOf(actualizado);
        final ix = _clientesCredito.indexWhere((x) => _idOf(x) == id);
        if (ix >= 0) {
          _clientesCredito[ix] = actualizado;
        } else {
          _clientesCredito.insert(0, actualizado);
        }
      } else {
        _errorMessage = res.message;
      }
    } catch (e) {
      _errorMessage = "Ocurrió un error: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sincroniza actividades para un cliente de CONTADO por documento
  Future<void> syncActividadesContadoBy(String documento) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiHelper.syncActividades(documento);
      if (res.isSuccess) {
        final actualizado = res.result as Cliente;
        final id = _idOf(actualizado);
        final ix = _clientesContado.indexWhere((x) => _idOf(x) == id);
        if (ix >= 0) {
          _clientesContado[ix] = actualizado;
        } else {
          _clientesContado.insert(0, actualizado);
        }
      } else {
        _errorMessage = res.message;
      }
    } catch (e) {
      _errorMessage = "Ocurrió un error: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inserta o actualiza un Cliente en la lista indicada por tipo (no aplica a promo)
  void upsertClienteBy(Cliente c, {required ClienteTipo tipo, bool asFirst = true}) {
    final list = clientesBy(tipo);
    final id = _idOf(c);
    final idx = list.indexWhere((x) => _idOf(x) == id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      asFirst ? list.insert(0, c) : list.add(c);
    }
    notifyListeners();
  }

  // Setters explícitos (si los usas en otras capas)
  void setClientesContado(List<Cliente> clientes) {
    _clientesContado = clientes;
    notifyListeners();
  }

  void setClientesCredito(List<Cliente> clientes) {
    _clientesCredito = clientes;
    notifyListeners();
  }

  void setClientesPromo(List<ClientePromo> clientes) {
    _clientesPromo = clientes;
    notifyListeners();
  }

  // Helpers
  bool _isPeddler(Cliente c) =>
      (c.tipo ?? '').trim().toLowerCase() == 'peddler';

  String _idOf(Cliente c) {
    // Ajusta según tu modelo real: prioriza 'codigo' y si no, 'documento'
    final codigo = (c.codigo).trim(); // String no-nullable en tu modelo
    return codigo.isNotEmpty ? codigo : c.documento.trim();
  }
}
