import 'package:tester/Models/actividad_info.dart';

class Cliente {
  String nombre = '';
  String documento = '';
  String codigoTipoID = '';
  String email = '';
  int puntos = 0;
  String codigo = '';
  String? tipo;
  String telefono = '';
  List<String>? placas = [];
  List<String>? emails = [];

  
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
    required this.telefono,
    this.placas,
    this.emails,
    this.actividadesEconomicas,
    this.actividadPrincipal,
    this.actividadSeleccionada,
  });

  String obtenerPrimerNombre() {
    List<String> partesNombre = nombre.split(' ');
    return partesNombre.isNotEmpty ? partesNombre.first : '';
  }

  Cliente.fromJson(Map<String, dynamic> json) {
    nombre = json['nombre'];
    documento = json['documento'];
    codigoTipoID = json['codigoTipoID'];
    email = json['email'];
    puntos = json['puntos'];
    emails = [email];
    if (json['codigo'] != null) {
      codigo = json['codigo'];
    }
    telefono = json['telefono'] ?? '';
    tipo = json['tipo'];

    // 🔹 Mapear actividades si vienen en JSON
    if (json['actividadesEconomicas'] != null) {
      actividadesEconomicas = (json['actividadesEconomicas'] as List)
          .map((e) => ActividadInfo.fromJson(e))
          .toList();
    }
    if (json['actividadPrincipal'] != null) {
      actividadPrincipal = ActividadInfo.fromJson(json['actividadPrincipal']);
    }
    if (json['actividadSeleccionada'] != null) {
      actividadSeleccionada =
          ActividadInfo.fromJson(json['actividadSeleccionada']);
    }
  }

  Cliente.fromHaciendaJson(Map<String, dynamic> json) {
    nombre = json['nombre'];
    codigoTipoID = json['tipoIdentificacion'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['nombre'] = nombre;
    data['documento'] = documento;
    data['codigoTipoID'] = codigoTipoID;
    data['email'] = email;
    data['puntos'] = puntos;
    data['codigo'] = codigo;
    data['tipo'] = tipo;
    data['telefono'] = telefono;

    // 🔹 Serializar actividades
    if (actividadesEconomicas != null) {
      data['actividadesEconomicas'] =
          actividadesEconomicas!.map((e) => e.toJson()).toList();
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
  /// Nota: realiza copia **superficial** de las listas (placas, emails y actividadesEconomicas).
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
      placas: placas ?? (this.placas != null ? List<String>.from(this.placas!) : null),
      emails: emails ?? (this.emails != null ? List<String>.from(this.emails!) : null),
      actividadesEconomicas: actividadesEconomicas ??
          (this.actividadesEconomicas != null
              ? List<ActividadInfo>.from(this.actividadesEconomicas!)
              : null),
      actividadPrincipal: actividadPrincipal ?? this.actividadPrincipal,
      actividadSeleccionada: actividadSeleccionada ?? this.actividadSeleccionada,
    );
  }

}
