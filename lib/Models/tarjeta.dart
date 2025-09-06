class Tarjeta {
  final int idCanjeo;
  final int? cedulaEmpleado;
  final String idTarjeta;
  final DateTime? fechaCanjeo;
  final int? idCliente;
  final String puntoCanje;
  final int? idCierre;
  final double? monto;
  final int? idTransaccion;
  final String nFact;

  Tarjeta({
    required this.idCanjeo,
    this.cedulaEmpleado,
    required this.idTarjeta,
    this.fechaCanjeo,
    this.idCliente,
    required this.puntoCanje,
    this.idCierre,
    this.monto,
    this.idTransaccion,
    required this.nFact,
  });

factory Tarjeta.fromJson(Map<String, dynamic> json) {
  return Tarjeta(
    idCanjeo: json['idcanjeo'] as int? ?? 0, // Assuming 0 as a default value
    cedulaEmpleado: json['cedulaempleado'] as int? ?? 0,
    idTarjeta: json['idtarjeta'] as String? ?? '', // Default value if null
    fechaCanjeo: json['fechacanjeo'] != null ? DateTime.parse(json['fechacanjeo']) : null,
    idCliente: json['idcliente'] as int? ?? 0,
    puntoCanje: json['puntocanje'] as String? ?? '', // Default value if null
    idCierre: json['idcierre'] as int?,
    monto: (json['monto'] as num?)?.toDouble() ?? 0,
    idTransaccion: json['idtransaccion'] as int? ?? 0,
    nFact: json['nfact'] as String? ?? '', // Default value if null
  );
}


 Map<String, dynamic> toJson() {
  return {
    'idCanjeo': idCanjeo,
    'cedulaEmpleado': cedulaEmpleado,
    'idTarjeta': idTarjeta,
    'fechaCanjeo': fechaCanjeo?.toIso8601String(),
    'idCliente': idCliente,
    'puntoCanje': puntoCanje,
    'idCierre': idCierre,
    'monto': monto,
    'idTransaccion': idTransaccion,
    'nFact': nFact,
  };
}

}
