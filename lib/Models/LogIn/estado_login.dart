import 'package:tester/Models/LogIn/estado_cierre_zona.dart';
import 'package:tester/Models/empleado.dart';

class LogInEstado {
  EstadoCierreZona? estado;
  Empleado? empleado;

  LogInEstado({this.estado,  this.empleado});

  factory LogInEstado.fromJson(Map<String, dynamic> json) => LogInEstado(
        estado: EstadoCierreZona.fromJson(json['estado']),
        empleado: Empleado.fromJson(json['empleado']),
      );

  Map<String, dynamic> toJson() => {
        'estado': estado!.toJson(),
        'empleado': empleado!.toJson(),
      };
}