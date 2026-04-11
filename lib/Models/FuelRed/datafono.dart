class Datafono {
  int? iddatafono;
  int? idbanco;
  String? nombre;
  String? ip;
  int? puerto;

  Datafono({this.iddatafono, this.idbanco, this.nombre, this.ip, this.puerto});

  Datafono.fromJson(Map<String, dynamic> json) {
    iddatafono = json['iddatafono'];
    idbanco = json['idbanco'];
    nombre = json['nombre'];
    ip = json['ip'];
    puerto = json['puerto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iddatafono'] = iddatafono;
    data['idbanco'] = idbanco;
    data['nombre'] = nombre;
    data['ip'] = ip;
    data['puerto'] = puerto;
    return data;
  }

  /// Whether this datafono has PAX terminal connectivity configured.
  bool get hasPax => ip != null && ip!.isNotEmpty;
}
