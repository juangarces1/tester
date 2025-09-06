class CierreFinal {
  int? idcierre;
  DateTime? fechainiciocierre = DateTime.now();
  DateTime? fechafinalcierre = DateTime.now();
  String? horainicio;
  String? horafinal;
  int? cedulaempleado;
  int? idzona;
  String? estado;
  String? turno;
  String? inventario;

  CierreFinal(
      {this.idcierre,
      this.fechainiciocierre,
      this.fechafinalcierre,
      this.horainicio,
      this.horafinal,
      this.cedulaempleado,
      this.idzona,
      this.estado,
      this.turno,
      this.inventario});

  CierreFinal.fromJson(Map<String, dynamic> json) {
    idcierre = json['idcierre'];
    fechainiciocierre =  DateTime.parse(json['fechainiciocierre']);
    fechafinalcierre =  DateTime.parse(json['fechafinalcierre']);
    horainicio = json['horainicio'];
    horafinal = json['horafinal'];
    cedulaempleado = json['cedulaempleado'];
    idzona = json['idzona'];
    estado = json['estado'];
    turno = json['turno'];
    inventario = json['inventario'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idcierre'] = idcierre;
    data['fechainiciocierre'] = fechainiciocierre;
    data['fechafinalcierre'] = fechafinalcierre;
    data['horainicio'] = horainicio;
    data['horafinal'] = horafinal;
    data['cedulaempleado'] = cedulaempleado;
    data['idzona'] = idzona;
    data['estado'] = estado;
    data['turno'] = turno;
    data['inventario'] = inventario;
    return data;
  }
}