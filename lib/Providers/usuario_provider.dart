// lib/Providers/usuario_provider.dart
import 'package:flutter/foundation.dart';
import 'package:tester/ConsoleModels/console_user.dart';
import 'package:tester/Models/FuelRed/empleado.dart';


class UsuarioProvider extends ChangeNotifier {
  // Usuario de consola (tu actual)
  ConsoleUser? _current;
  ConsoleUser? get current => _current;
  bool get isLoggedIn => _current != null;

  // Usuario FuelRed (derivado de Empleado)
  Empleado? _fuelUser;
  Empleado? get fuelUser => _fuelUser;
  bool get hasFuelUser => _fuelUser != null;

  // --- ConsoleUser ---
  Future<void> signIn(ConsoleUser user) async {
    _current = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    _current = null;
    notifyListeners();
  }

  Future<void> updateRole(UserRole role) async {
    if (_current == null) return;
    _current = _current!.copyWith(rol: role);
    notifyListeners();
  }

  Future<void> setVerified(bool value) async {
    if (_current == null) return;
    _current = _current!.copyWith(verificado: value);
    notifyListeners();
  }

  // --- FuelRedUser ---
  Future<void> signInFuel(Empleado user) async {
    _fuelUser = user;
    notifyListeners();
  }

  Future<void> signInFuelFromApiJson(Map<String, dynamic> empleadoJson) async {
    _fuelUser = Empleado.fromApi(empleadoJson);
    notifyListeners();
  }

  Future<void> signOutFuel() async {
    _fuelUser = null;
    notifyListeners();
  }

  // Dentro de UsuarioProvider
    void reset() {
      _current = null;    // cierra sesión del usuario de consola
      _fuelUser = null;   // elimina el usuario FuelRed (empleado)
      notifyListeners();  // actualiza toda la UI dependiente
    }

  
}
