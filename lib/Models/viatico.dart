class Viatico {
  int? idviatico;
  int? monto;
  int? idcierre;
  int? cedulaempleado;
  int? idcliente;
  String? fecha;
  String? placa;
  String? estado;
  int? idpagoviatico;
  String? clienteNombre;
  

  Viatico(
      {this.idviatico,
      this.monto,
      this.idcierre,
      this.cedulaempleado,
      this.idcliente,
      this.fecha,
      this.placa,
      this.estado,
      this.idpagoviatico,
      this.clienteNombre});

  Viatico.fromJson(Map<String, dynamic> json) {
    idviatico = json['idviatico'];
    monto = json['monto'];
    idcierre = json['idcierre'];
    cedulaempleado = json['cedulaempleado'];
    idcliente = json['idcliente'];
    fecha = json['fecha'];
    placa = json['placa'];
    estado = json['estado'];
    idpagoviatico = json['idpagoviatico'];
     clienteNombre = json['clienteNombre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idviatico'] = idviatico;
    data['monto'] = monto;
    data['idcierre'] = idcierre;
    data['cedulaempleado'] = cedulaempleado;
    data['idcliente'] = idcliente;
    data['fecha'] = fecha;
    data['placa'] = placa;
    data['estado'] = estado;
    data['idpagoviatico'] = idpagoviatico;
     data['clienteNombre'] = clienteNombre;
    return data;
  }
}