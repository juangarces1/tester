class Cashback {
  int? idcashback;
  int? monto;
  String? fechacashback; 
  int? cedulaempleado;
  int? idbanco;
  int? idcierre;

  Cashback(
      {this.idcashback,
      this.monto,
      this.fechacashback,
      this.cedulaempleado,
      this.idbanco,
      this.idcierre});

  Cashback.fromJson(Map<String, dynamic> json) {
    idcashback = json['idcashback'];
    monto = json['monto'];
    fechacashback =json['fechacashback'];
    cedulaempleado = json['cedulaempleado'];
    idbanco = json['idbanco'];
    idcierre = json['idcierre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idcashback'] = idcashback;
    data['monto'] = monto;
    data['fechacashback'] = fechacashback;
    data['cedulaempleado'] = cedulaempleado;
    data['idbanco'] = idbanco;
    data['idcierre'] = idcierre;
    return data;
  }
}