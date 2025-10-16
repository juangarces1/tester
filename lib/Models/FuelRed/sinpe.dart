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
      id: json['id'],
      numComprobante: json['numComprobante'],
      nota: json['nota'],
      idCierre: json['idCierre'],
      nombreEmpleado: json['nombreEmpleado'],
      fecha: DateTime.parse(json['fecha']),
      numFact: json['numFact'],
      activo: json['activo'],
      monto: double.parse(json['monto'].toString()),
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