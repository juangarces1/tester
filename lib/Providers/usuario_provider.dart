// lib/Providers/usuario_provider.dart
import 'package:flutter/foundation.dart';
import 'package:tester/ConsoleModels/console_user.dart';


class UsuarioProvider extends ChangeNotifier {
  ConsoleUser? _current;
  ConsoleUser? get current => _current;
  bool get isLoggedIn => _current != null;

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
}
