class Datafono {
  int? iddatafono;
  int? idbanco;
  String? nombre;

  Datafono({this.iddatafono, this.idbanco, this.nombre});

  Datafono.fromJson(Map<String, dynamic> json) {
    iddatafono = json['iddatafono'];
    idbanco = json['idbanco'];
    nombre = json['nombre'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iddatafono'] = iddatafono;
    data['idbanco'] = idbanco;
    data['nombre'] = nombre;
    return data;
  }
}