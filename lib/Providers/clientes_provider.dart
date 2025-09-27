import 'package:flutter/material.dart';
import 'package:tester/Models/Promo/cliente_promo.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/helpers/api_helper.dart';

class ClienteProvider with ChangeNotifier {
  List<Cliente> _clientesContado = [];
  List<Cliente> _clientesCredito = [];
  List<ClientePromo> _clientesPromo=[];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientesContado => _clientesContado;
  List<Cliente> get clientesCredito => _clientesCredito;
  List<ClientePromo> get clientesPromo => _clientesPromo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getClientes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Response response = await ApiHelper.getClienteContado();
      if (response.isSuccess) {
        _clientesContado = response.result;
      } else {
        _errorMessage = 'Error al cargar los clientes al contado';
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncActividades(String documento, int index) async {
      _isLoading = true;
      notifyListeners();

      try {
        final response = await ApiHelper.syncActividades(documento);

        if (response.isSuccess) {
          final clienteActualizado = response.result as Cliente;
          _clientesContado[index] = clienteActualizado;
        } else {
          _errorMessage = response.message ?? "Error al sincronizar actividades";
        }
      } catch (e) {
        _errorMessage = "Ocurrió un error: ${e.toString()}";
      }

      _isLoading = false;
      notifyListeners();
  }

  Future<void> getClientesCredito() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Response response = await ApiHelper.getClientesCredito();
      if (response.isSuccess) {
        _clientesCredito = response.result;
      } else {
        _errorMessage = 'Error al cargar los clientes a crédito';
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

   Future<void> getClientesPromo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Response response = await ApiHelper.getClientesPromo();
      if (response.isSuccess) {
        _clientesPromo = response.result;
      } else {
        _errorMessage = 'Error al cargar los clientes a crédito';
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

    void setClientesContado(List<Cliente> clientes) {
    _clientesContado = clientes;
    notifyListeners();
  }

  void setClientesCredito(List<Cliente> clientes) {
    _clientesCredito = clientes;
    notifyListeners();
  }

   void setClientesOromo(List<ClientePromo> clientes) {
    _clientesPromo = clientes;
    notifyListeners();
  }

   void upsertCliente(Cliente c, {bool asFirst = true}) {
    final id = _idOf(c);
    final idx = clientesContado.indexWhere((x) => _idOf(x) == id);
    if (idx >= 0) {
      clientesContado[idx] = c;
    } else {
      if (asFirst) {
        clientesContado.insert(0, c);
      } else {
        clientesContado.add(c);
      }
    }
    notifyListeners();
  }

  String _idOf(Cliente c) {
    final codigo = (c.codigo).trim(); // en tu modelo es String no-nullable
    return codigo.isNotEmpty ? codigo : c.documento.trim();
  }

}
