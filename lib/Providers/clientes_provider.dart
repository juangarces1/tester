import 'package:flutter/material.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/helpers/api_helper.dart';

class ClienteProvider with ChangeNotifier {
  List<Cliente> _clientesContado = [];
  List<Cliente> _clientesCredito = [];
  List<ClientePromo> _clientesPromo = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // -------- Acceso unificado --------
  List<Cliente> clientesBy(ClienteTipo tipo) {
    switch (tipo) {
      case ClienteTipo.contado: return _clientesContado;
      case ClienteTipo.credito: return _clientesCredito;
      case ClienteTipo.promo:   return _clientesContado; // o mapea como necesites
    }
  }

  Future<void> loadClientesBy(ClienteTipo tipo) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      late Response response;
      switch (tipo) {
        case ClienteTipo.contado:
          response = await ApiHelper.getClienteContado();
          if (response.isSuccess) _clientesContado = response.result;
          else _errorMessage = 'Error al cargar los clientes al contado';
          break;
        case ClienteTipo.credito:
          response = await ApiHelper.getClientesCredito();
          if (response.isSuccess) _clientesCredito = response.result;
          else _errorMessage = 'Error al cargar los clientes a crédito';
          break;
        case ClienteTipo.promo:
          response = await ApiHelper.getClientesPromo();
          if (response.isSuccess) _clientesPromo = response.result;
          else _errorMessage = 'Error al cargar clientes promo';
          break;
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> syncActividadesCreditoBy(String documento) async {
  _isLoading = true; _errorMessage = null; notifyListeners();
  try {
    final res = await ApiHelper.syncActividadesCredito(documento);
    if (res.isSuccess) {
      final actualizado = res.result as Cliente;
      final id = _idOf(actualizado);
      final ix = _clientesCredito.indexWhere((x) => _idOf(x) == id);
      if (ix >= 0) _clientesCredito[ix] = actualizado; else _clientesCredito.insert(0, actualizado);
    } else {
      _errorMessage = res.message ?? "Error al sincronizar actividades (crédito)";
    }
  } catch (e) {
    _errorMessage = "Ocurrió un error: ${e.toString()}";
  } finally {
    _isLoading = false; notifyListeners();
  }
}

Future<void> syncActividadesContadoBy(String documento) async {
  _isLoading = true; _errorMessage = null; notifyListeners();
  try {
    final res = await ApiHelper.syncActividades(documento);
    if (res.isSuccess) {
      final actualizado = res.result as Cliente;
      final id = _idOf(actualizado);
      final ix = _clientesContado.indexWhere((x) => _idOf(x) == id);
      if (ix >= 0) _clientesContado[ix] = actualizado; else _clientesContado.insert(0, actualizado);
    } else {
      _errorMessage = res.message ?? "Error al sincronizar actividades (contado)";
    }
  } catch (e) {
    _errorMessage = "Ocurrió un error: ${e.toString()}";
  } finally {
    _isLoading = false; notifyListeners();
  }
}


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

  // setters (por si los usas en otros sitios)
  void setClientesContado(List<Cliente> clientes) { _clientesContado = clientes; notifyListeners(); }
  void setClientesCredito(List<Cliente> clientes) { _clientesCredito = clientes; notifyListeners(); }
  void setClientesPromo(List<ClientePromo> clientes) { _clientesPromo = clientes; notifyListeners(); }

  String _idOf(Cliente c) {
    final codigo = (c.codigo).trim(); // String no-nullable en tu modelo
    return codigo.isNotEmpty ? codigo : c.documento.trim();
  }
}
enum ClienteTipo { contado, credito, promo }