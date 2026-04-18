class Deposito {
  int? iddeposito;
  int? monto;
  String? fechadeposito;
  int? cedulaempleado;
  String? moneda;
  int? idcierre;
  bool? selected = false;
  DateTime? createdAt;

  Deposito({
    this.iddeposito,
    this.monto,
    this.fechadeposito,
    this.cedulaempleado,
    this.moneda,
    this.idcierre,
    this.selected,
    this.createdAt,
  });

  Deposito.fromJson(Map<String, dynamic> json) {
    iddeposito = json['iddeposito'];
    monto = json['monto'];
    fechadeposito = json['fechadeposito']?.toString();
    cedulaempleado = json['cedulaempleado'];
    moneda = json['moneda'];
    idcierre = json['idcierre'];
    createdAt = fechadeposito != null ? DateTime.tryParse(fechadeposito!) : null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'iddeposito': iddeposito,
      'monto': monto,
      'fechadeposito': fechadeposito,
      'cedulaempleado': cedulaempleado,
      'moneda': moneda,
      'idcierre': idcierre,
    };
  }
}
