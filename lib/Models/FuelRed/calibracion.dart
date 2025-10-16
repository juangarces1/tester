class Calibracion {
  final int idCalibraciones;
  final int? idDispensador;
  final String? manguera;
  final int? cedulaEmpleado;
  final DateTime? fechaCalibracion;
  final int? monto;
  final int? idCierre;
  final int? idTransaccion;

  Calibracion({
    required this.idCalibraciones,
    this.idDispensador,
    this.manguera,
    this.cedulaEmpleado,
    this.fechaCalibracion,
    this.monto,
    this.idCierre,
    this.idTransaccion,
  });

  @override
  String toString() {
    return 'Calibracion{idCalibraciones: $idCalibraciones, idDispensador: $idDispensador, manguera: $manguera, cedulaEmpleado: $cedulaEmpleado, fechaCalibracion: ${fechaCalibracion?.toIso8601String()}, monto: $monto, idCierre: $idCierre, idTransaccion: $idTransaccion}';
  }

  factory Calibracion.fromJson(Map<String, dynamic> json) => Calibracion(
      idCalibraciones: json['idcalibraciones'] as int? ?? 0, // Proporcionar un valor por defecto si es nulo
      idDispensador: json['iddispensador']  as int? ?? 0,
      manguera: json['manguera'] as String? ?? '',
      cedulaEmpleado: json['cedulaempleado'] as int? ?? 0,
      fechaCalibracion: json['fechacalibracion'] != null
          ? DateTime.parse(json['fechacalibracion'])
          : null,
      monto: json['monto'] as int? ?? 0,
      idCierre: json['idcierre'] as int? ?? 0,
      idTransaccion: json['idtransaccion'] as int? ?? 0,
      );



  Map<String, dynamic> toJson() => {
        'Idcalibraciones': idCalibraciones,
        'Iddispensador': idDispensador,
        'Manguera': manguera,
        'Cedulaempleado': cedulaEmpleado,
        'Fechacalibracion': fechaCalibracion?.toIso8601String(),
        'Monto': monto,
        'Idcierre': idCierre,
        'Idtransaccion': idTransaccion,
      };
}
