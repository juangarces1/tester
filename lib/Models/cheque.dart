class Cheque {
  int? idcheque;
  int? monto;
  int? idbanco;
  int? cedulaempleado;
  String? detalle;
  int? idcierre;

  Cheque(
      {this.idcheque,
      this.monto,
      this.idbanco,
      this.cedulaempleado,
      this.detalle,
      this.idcierre});

  Cheque.fromJson(Map<String, dynamic> json) {
    idcheque = json['idcheque'];
    monto = json['monto'];
    idbanco = json['idbanco'];
    cedulaempleado = json['cedulaempleado'];
    detalle = json['detalle'];
    idcierre = json['idcierre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idcheque'] = idcheque;
    data['monto'] = monto;
    data['idbanco'] = idbanco;
    data['cedulaempleado'] = cedulaempleado;
    data['detalle'] = detalle;
    data['idcierre'] = idcierre;
    return data;
  }
}