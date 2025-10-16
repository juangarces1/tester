class Dollar {
  int? id;
  int? cantidad;
  int? preciocambio;
  int? monto;
  int? idcierre;

  Dollar(
      {this.id, this.cantidad, this.preciocambio, this.monto, this.idcierre});

  Dollar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cantidad = json['cantidad'];
    preciocambio = json['preciocambio'];
    monto = json['monto'];
    idcierre = json['idcierre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['cantidad'] = cantidad;
    data['preciocambio'] = preciocambio;
    data['monto'] = monto;
    data['idcierre'] = idcierre;
    return data;
  }
}