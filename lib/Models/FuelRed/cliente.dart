import 'package:tester/Models/FuelRed/actividad_info.dart';
import 'dart:core';

class Cliente {
  String nombre = '';
  String documento = '';
  String codigoTipoID = '';
  String email = '';
  int puntos = 0;
  String codigo = '';
  String? tipo;
  String? codigoFrecuente;
  String telefono = '';

  // Hazlas no-nulas para evitar NPEs en la UI
  List<String> placas = <String>[];
  List<String> emails = <String>[];

  List<ActividadInfo>? actividadesEconomicas = [];
  ActividadInfo? actividadPrincipal;
  ActividadInfo? actividadSeleccionada;

  Cliente({
    required this.nombre,
    required this.documento,
    required this.codigoTipoID,
    required this.email,
    required this.puntos,
    required this.codigo,
    this.tipo,
    this.codigoFrecuente,
    required this.telefono,
    List<String>? placas,
    List<String>? emails,
    this.actividadesEconomicas,
    this.actividadPrincipal,
    this.actividadSeleccionada,
  }) {
    this.placas = _dedupePlacas(placas ?? const []);
    this.emails = _dedupeEmails(emails ?? (email.isNotEmpty ? [email] : const []));
  }

  String obtenerPrimerNombre() {
    final partes = nombre.split(' ');
    return partes.isNotEmpty ? partes.first : '';
  }

  Cliente.fromJson(Map<String, dynamic> json) {
    nombre        = (json['nombre'] ?? '').toString();
    documento     = (json['documento'] ?? '').toString();
    codigoTipoID  = (json['codigoTipoID'] ?? '').toString();
    email         = (json['email'] ?? '').toString();
    puntos        = _toInt(json['puntos']);
    codigo        = (json['codigo'] ?? '').toString();
    telefono      = (json['telefono'] ?? '').toString();
    tipo          = json['tipo']?.toString();
    codigoFrecuente = (json['codigoFrecuente'] ?? '').toString();

    // ---- emails: mezcla 'email' + 'emails' sin duplicar
    final listEmails = <String>[];
    if (json['emails'] is List) {
      for (final e in (json['emails'] as List)) {
        if (e != null) listEmails.add(e.toString());
      }
    }
    if (email.isNotEmpty) listEmails.add(email);
    emails = _dedupeEmails(listEmails);

    // // ---- placas: acepta List / String "a,b,c" / números
     placas = _parsePlacas(json['placas']); 
     // 👇 placas: map directo y limpio (sin normalizar si no quieres)
  // placas = <String>[];
  // if (json['placas'] is List) {
  //   for (final p in (json['placas'] as List)) {
  //     if (p == null) continue;
  //     final s = p.toString().trim();
  //     if (s.isEmpty) continue;
  //     placas.add(s);
  //   }
  //}

    // ---- actividades
    if (json['actividadesEconomicas'] is List) {
      actividadesEconomicas = (json['actividadesEconomicas'] as List)
          .where((e) => e != null)
          .map((e) => ActividadInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (json['actividadPrincipal'] is Map) {
      actividadPrincipal = ActividadInfo.fromJson(json['actividadPrincipal'] as Map<String, dynamic>);
    }
    if (json['actividadSeleccionada'] is Map) {
      actividadSeleccionada = ActividadInfo.fromJson(json['actividadSeleccionada'] as Map<String, dynamic>);
    }
  }

  Cliente.fromHaciendaJson(Map<String, dynamic> json) {
    nombre       = (json['nombre'] ?? '').toString();
    codigoTipoID = (json['tipoIdentificacion'] ?? '').toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['nombre'] = nombre;
    data['documento'] = documento;
    data['codigoTipoID'] = codigoTipoID;
    data['email'] = email;
    data['puntos'] = puntos;
    data['codigo'] = codigo;
    data['tipo'] = tipo;
    data['telefono'] = telefono;
    data['codigoFrecuente'] = codigoFrecuente;

    // exporta listas ya depuradas
    data['emails'] = emails;
    data['placas'] = placas;

    if (actividadesEconomicas != null) {
      data['actividadesEconomicas'] = actividadesEconomicas!.map((e) => e.toJson()).toList();
    }
    if (actividadPrincipal != null) {
      data['actividadPrincipal'] = actividadPrincipal!.toJson();
    }
    if (actividadSeleccionada != null) {
      data['actividadSeleccionada'] = actividadSeleccionada!.toJson();
    }
    return data;
  }

  /// Crea una copia del cliente modificando solo los campos provistos.
  /// Nota: copia superficial de listas.
  Cliente copyWith({
    String? nombre,
    String? documento,
    String? codigoTipoID,
    String? email,
    int? puntos,
    String? codigo,
    String? tipo,
    String? telefono,
    List<String>? placas,
    List<String>? emails,
    List<ActividadInfo>? actividadesEconomicas,
    ActividadInfo? actividadPrincipal,
    ActividadInfo? actividadSeleccionada,
  }) {
    return Cliente(
      nombre: nombre ?? this.nombre,
      documento: documento ?? this.documento,
      codigoTipoID: codigoTipoID ?? this.codigoTipoID,
      email: email ?? this.email,
      puntos: puntos ?? this.puntos,
      codigo: codigo ?? this.codigo,
      tipo: tipo ?? this.tipo,
      telefono: telefono ?? this.telefono,
      placas: placas ?? List<String>.from(this.placas),
      emails: emails ?? List<String>.from(this.emails),
      actividadesEconomicas: actividadesEconomicas ??
          (this.actividadesEconomicas != null
              ? List<ActividadInfo>.from(this.actividadesEconomicas!)
              : null),
      actividadPrincipal: actividadPrincipal ?? this.actividadPrincipal,
      actividadSeleccionada: actividadSeleccionada ?? this.actividadSeleccionada,
    );
  }

  // =======================
  // Helpers privados
  // =======================

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    final s = v.toString();
    final n = int.tryParse(s);
    return n ?? 0;
  }

  List<String> _parsePlacas(dynamic raw) {
    final list = <String>[];

    if (raw == null) return list;

    if (raw is List) {
      for (final x in raw) {
        if (x == null) continue;
        final s = x.toString();
        if (s.trim().isEmpty) continue;
        list.add(s);
      }
    } else if (raw is String) {
      // Permite "ABC123, DEF-456 ; C140380"
      final parts = raw.split(RegExp(r'[,\;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      list.addAll(parts);
    } else {
      // números u otros tipos
      list.add(raw.toString());
    }

    return _dedupePlacas(list);
  }

  /// Normaliza y deduplica placas (BHR-992 == bhr992; C140380 == 140380).
  List<String> _dedupePlacas(List<String> input) {
    final seen = <String, String>{}; // key normalizada -> representación (preferimos la primera “bonita”)

    for (final raw in input) {
      final norm = _normalizePlate(raw);
      if (norm.isEmpty) continue;
      // si ya existe key, mantenemos la primera para estabilidad
      seen.putIfAbsent(norm, () => raw.trim());
    }
    return seen.values.toList();
  }

  String _normalizePlate(String? raw) {
    if (raw == null) return '';
    var up = raw.toUpperCase().trim();
    // quita no-alfanumérico (espacios, guiones, puntos, etc.)
    up = up.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (up.isEmpty) return '';

    // C + solo dígitos => quita la C (C140380 -> 140380)
    final m = RegExp(r'^C(\d+)$').firstMatch(up);
    if (m != null) return m.group(1)!;

    return up;
  }

  List<String> _dedupeEmails(List<String> input) {
    final set = <String>{};
    for (final e in input) {
      final s = e.trim();
      if (s.isEmpty) continue;
      set.add(s.toLowerCase()); // emails case-insensitive
    }
    return set.toList();
  }
}
