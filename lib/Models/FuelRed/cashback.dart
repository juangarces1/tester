class Cashback {
  int? idcashback;
  int? monto;
  String? fechacashback; 
  int? cedulaempleado;
  int? idbanco;
  int? idcierre;
  String? nombreEmpleado;

  Cashback(
      {this.idcashback,
      this.monto,
      this.fechacashback,
      this.cedulaempleado,
      this.idbanco,
      this.idcierre,
      this.nombreEmpleado});

  Cashback.fromJson(Map<String, dynamic> json) {
    idcashback = json['idcashback'];
    monto = json['monto'];
    fechacashback =json['fechacashback'];
    cedulaempleado = json['cedulaempleado'];
    idbanco = json['idbanco'];
    idcierre = json['idcierre'];
    nombreEmpleado = json['nombreEmpleado'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idcashback'] = idcashback;
    data['monto'] = monto;
    data['fechacashback'] = fechacashback;
    data['cedulaempleado'] = cedulaempleado;
    data['idbanco'] = idbanco;
    data['idcierre'] = idcierre;
    data['nombreEmpleado'] = nombreEmpleado;
    return data;
  }
}