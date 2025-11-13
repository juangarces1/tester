// ignore: file_names
class Empleado {
  int cedulaEmpleado = 0;
  String nombre = '';
  String apellido1 = '';
  String apellido2 = '';
  String turno = '';
  String tipoempleado = '';
  String? attendantId;

  Empleado({
    required this.cedulaEmpleado,
    required this.nombre,
    required this.apellido1,
    required this.apellido2,
    required this.turno,
    required this.tipoempleado,
    this.attendantId,
  });

  // Mantengo tu fromJson "clásico" (claves exactas en minúscula)
  Empleado.fromJson(Map<String, dynamic> json) {
    cedulaEmpleado = _asInt(json['cedulaempleado']) ?? 0;
    nombre         = _asString(json['nombre']);
    apellido1      = _asString(json['apellido1']);
    apellido2      = _asString(json['apellido2']);
    turno          = _asString(json['turno']);
    tipoempleado   = _asString(json['tipoempleado']);
    attendantId    = _asString(json['attendantId']);
  }

  /// NUEVO: parsing tolerante al backend de CardAuth.
  /// Acepta variantes de claves: {cedula | cedulaEmpleado | cedulaempleado},
  /// {tipoEmpleado | tipoempleado}. El resto igual.
  factory Empleado.fromApi(Map<String, dynamic> json) {
    return Empleado(
      cedulaEmpleado: _asInt(json['cedula'])
          ?? _asInt(json['cedulaEmpleado'])
          ?? _asInt(json['cedulaempleado'])
          ?? 0,
      nombre:       _asString(json['nombre']),
      apellido1:    _asString(json['apellido1']),
      apellido2:    _asString(json['apellido2']),
      turno:        _asString(json['turno']),
      tipoempleado: _asString(json['tipoEmpleado'] ?? json['tipoempleado']),
    );
  }

  /// Alias por si prefieres este nombre
  factory Empleado.fromJsonCardAuth(Map<String, dynamic> json) =>
      Empleado.fromApi(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cedulaEmpleado'] = cedulaEmpleado;
    data['nombre']         = nombre;
    data['apellido1']      = apellido1;
    data['apellido2']      = apellido2;
    data['turno']          = turno;
    data['tipoempleado']   = tipoempleado;
    return data;
  }

  String get nombreCompleto => '$nombre $apellido1';

  // --------- helpers internos ---------
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
    }

  static String _asString(dynamic v) => (v ?? '').toString();
}
