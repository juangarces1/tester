enum UserRole {
  administrador,
  analista,
  gerente,
  operador,
}

class ConsoleUser {
  final String email;
  final UserRole rol;
  final String identifier;
  final bool verificado;

  const ConsoleUser({
    required this.email,
    required this.rol,
    required this.identifier,
    required this.verificado,
  });

  /// Conversión desde JSON
  factory ConsoleUser.fromJson(Map<String, dynamic> json) {
    return ConsoleUser(
      email: json['email'] as String,
      rol: _roleFromString(json['rol']),
      identifier: json['identifier'] as String,
      verificado: json['verificado'] as bool,
    );
  }

  /// Conversión a JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'rol': rol.name,
      'identifier': identifier,
      'verificado': verificado,
    };
  }

  /// Helper para mapear string a enum
  static UserRole _roleFromString(String value) {
    switch (value.toLowerCase()) {
      case 'administrador':
        return UserRole.administrador;
      case 'analista':
        return UserRole.analista;
      case 'gerente':
        return UserRole.gerente;
      case 'operador':
        return UserRole.operador;
      default:
        throw ArgumentError('Rol desconocido: $value');
    }
  }

  ConsoleUser copyWith({
    String? email,
    UserRole? rol,
    String? identifier,
    bool? verificado,
  }) {
    return ConsoleUser(
      email: email ?? this.email,
      rol: rol ?? this.rol,
      identifier: identifier ?? this.identifier,
      verificado: verificado ?? this.verificado,
    );
  }
}
