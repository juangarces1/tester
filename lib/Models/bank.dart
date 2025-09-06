class Bank {
  int? idbanco;
  String? nombre;
  String? sigla;
  double? comision;

  Bank({this.idbanco, this.nombre, this.sigla, this.comision});

  Bank.fromJson(Map<String, dynamic> json) {
    idbanco = json['idbanco'];
    nombre = json['nombre'];
    sigla = json['sigla'];
    comision = json['comision'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idbanco'] = idbanco;
    data['nombre'] = nombre;
    data['sigla'] = sigla;
    data['comision'] = comision;
    return data;
  }
}