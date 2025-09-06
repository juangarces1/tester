class Deposito {
  int? iddeposito;
  int? monto;
  String? fechadepostio; 
  int? cedulaempleado;
  String? moneda;
  int? idcierre;
  bool? selected = false;

  Deposito(
      {this.iddeposito,
      this.monto,
      this.fechadepostio,
      this.cedulaempleado,
      this.moneda,
      this.idcierre,
      this.selected,
      });

  Deposito.fromJson(Map<String, dynamic> json) {
    iddeposito = json['iddeposito'];
    monto = json['monto'];
    fechadepostio =json['fechadepostio'];
    cedulaempleado = json['cedulaempleado'];
    moneda = json['moneda'];
    idcierre = json['idcierre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iddeposito'] = iddeposito;
    data['monto'] = monto;
    data['fechadepostio'] = fechadepostio;
    data['cedulaempleado'] = cedulaempleado;
    data['moneda'] = moneda;
    data['idcierre'] = idcierre;
    return data;
  }
}