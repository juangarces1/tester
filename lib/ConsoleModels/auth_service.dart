import 'package:tester/ConsoleModels/console_user.dart';
import 'package:tester/helpers/console_api_helper.dart';

class AuthService {
  final ConsoleApiHelper api;

  AuthService(this.api);

  /// "Login" temporal: solo resuelve el userId por email y arma el Usuario.
  /// Puedes decidir el rol por defecto (ej. operador) y verificado=true/false.
  Future<ConsoleUser> loginWithEmailOnly(String email,
      {UserRole defaultRole = UserRole.operador,
       bool defaultVerified = true}) async {
    final id = await api.getUserIdByEmail(email);
    return ConsoleUser(
      email: email.trim(),
      rol: defaultRole,
      identifier: id,     // p.ej. "B32809EE018B2813"
      verificado: defaultVerified,
    );
  }
}
