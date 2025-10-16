import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/cierreactivo.dart';
import 'package:tester/Models/FuelRed/cierrefinal.dart';
import 'package:tester/Models/FuelRed/empleado.dart';

class CierreActivoProvider extends ChangeNotifier {
  CierreActivo? _cierre; // null cuando no hay turno/cierre activo

  // ---- Getters convenientes ----
  bool get hasCierre => _cierre != null;
  CierreActivo? get value => _cierre;

  CierreFinal? get cierreFinal => _cierre?.cierreFinal;
  Empleado? get cajero => _cierre?.cajero;
  Empleado? get usuario => _cierre?.usuario;

  // ---- Inicialización/replace ----
  void setFrom(CierreActivo c) {
    _cierre = c;
    notifyListeners();
  }

  void setFromJson(Map<String, dynamic> json) {
    _cierre = CierreActivo(
      cierreFinal: _emptyCierreFinal(),
      cajero: _emptyEmpleado(),
      usuario: _emptyEmpleado(),
    );
    _cierre = CierreActivo.fromJson(json);
    notifyListeners();
  }

  /// Limpia el estado (p. ej., al cerrar turno)
  void clear() {
    _cierre = null;
    notifyListeners();
  }

  // ---- Updates atómicos ----
  void updateCierreFinal(CierreFinal nuevo) {
    _ensure();
    _cierre!.cierreFinal = nuevo;
    notifyListeners();
  }

  void updateCajero(Empleado e) {
    _ensure();
    _cierre!.cajero = e;
    notifyListeners();
  }

  void updateUsuario(Empleado e) {
    _ensure();
    _cierre!.usuario = e;
    notifyListeners();
  }

  /// Patch por campos (útil para cambios puntuales sin recrear objetos)
  void patchCierreFinal({
    int? idcierre,
    DateTime? fechainiciocierre,
    DateTime? fechafinalcierre,
    String? horainicio,
    String? horafinal,
    int? cedulaempleado,
    String? inventario,
    int? idzona,
    String? estado,
    String? turno,
  }) {
    _ensure();
    final cf = _cierre!.cierreFinal;
    _cierre!.cierreFinal = CierreFinal(
      idcierre: idcierre ?? cf.idcierre,
      fechainiciocierre: fechainiciocierre ?? cf.fechainiciocierre,
      fechafinalcierre: fechafinalcierre ?? cf.fechafinalcierre,
      horainicio: horainicio ?? cf.horainicio,
      horafinal: horafinal ?? cf.horafinal,
      cedulaempleado: cedulaempleado ?? cf.cedulaempleado,
      inventario: inventario ?? cf.inventario,
      idzona: idzona ?? cf.idzona,
      estado: estado ?? cf.estado,
      turno: turno ?? cf.turno,
    );
    notifyListeners();
  }

  void patchCajero({
    int? cedulaEmpleado,
    String? nombre,
    String? apellido1,
    String? apellido2,
    String? turno,
    String? tipoempleado,
  }) {
    _ensure();
    final e = _cierre!.cajero;
    _cierre!.cajero = Empleado(
      cedulaEmpleado: cedulaEmpleado ?? e.cedulaEmpleado,
      nombre: nombre ?? e.nombre,
      apellido1: apellido1 ?? e.apellido1,
      apellido2: apellido2 ?? e.apellido2,
      turno: turno ?? e.turno,
      tipoempleado: tipoempleado ?? e.tipoempleado,
    );
    notifyListeners();
  }

  void patchUsuario({
    int? cedulaEmpleado,
    String? nombre,
    String? apellido1,
    String? apellido2,
    String? turno,
    String? tipoempleado,
  }) {
    _ensure();
    final e = _cierre!.usuario;
    _cierre!.usuario = Empleado(
      cedulaEmpleado: cedulaEmpleado ?? e.cedulaEmpleado,
      nombre: nombre ?? e.nombre,
      apellido1: apellido1 ?? e.apellido1,
      apellido2: apellido2 ?? e.apellido2,
      turno: turno ?? e.turno,
      tipoempleado: tipoempleado ?? e.tipoempleado,
    );
    notifyListeners();
  }

  /// Mutación controlada (cambios complejos en bloque, con un solo notify)
  void mutate(void Function(CierreActivo c) updater) {
    _ensure();
    updater(_cierre!);
    notifyListeners();
  }

  /// Serializar (p. ej., para cache/local storage)
  Map<String, dynamic>? toJson() => _cierre?.toJson();

  // ---- Privados ----
  void _ensure() {
    _cierre ??= CierreActivo(
      cierreFinal: _emptyCierreFinal(),
      cajero: _emptyEmpleado(),
      usuario: _emptyEmpleado(),
    );
  }

  static CierreFinal _emptyCierreFinal() => CierreFinal(
        idcierre: 0,
        fechainiciocierre: DateTime.now(),
        fechafinalcierre: DateTime.now(),
        horainicio: '',
        horafinal: '',
        cedulaempleado: 0,
        inventario: '',
        idzona: 0,
        estado: '',
        turno: '',
      );

  static Empleado _emptyEmpleado() => Empleado(
        cedulaEmpleado: 0,
        nombre: '',
        apellido1: '',
        apellido2: '',
        turno: '',
        tipoempleado: '',
      );
}
