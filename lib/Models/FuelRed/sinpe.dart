class Sinpe {
  int id;
  String numComprobante;
  String nota;
  int idCierre;
  String nombreEmpleado;
  DateTime fecha;
  String numFact;
  int activo;
  double monto;

  Sinpe({
    required this.id,
    required this.numComprobante,
    required this.nota,
    required this.idCierre,
    required this.nombreEmpleado,
    required this.fecha,
    required this.numFact,
    required this.activo,
    required this.monto,
  });

  factory Sinpe.fromJson(Map<String, dynamic> json) {
    return Sinpe(
      id: (json['id'] ?? 0) as int,
      numComprobante: (json['numComprobante'] ?? '') as String,
      nota: (json['nota'] ?? '') as String,
      idCierre: (json['idCierre'] ?? 0) as int,
      nombreEmpleado: (json['nombreEmpleado'] ?? '') as String,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      numFact: (json['numFact'] ?? '') as String,
      activo: (json['activo'] ?? 0) as int,
      monto: double.parse((json['monto'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['numComprobante'] = numComprobante;
    data['nota'] = nota;
    data['idCierre'] = idCierre;
    data['nombreEmpleado'] = nombreEmpleado;
    data['fecha'] = fecha.toIso8601String();
    data['numFact'] = numFact;
    data['activo'] = activo;
    data['monto'] = monto;
    return data;
  }
}