class EstadoCierreZona {
  int zona;
  bool abierto;
  bool cerrado;
  bool stanbyAbierto;
  bool stanby;

  EstadoCierreZona({
    required this.zona,
    required this.abierto,
    required this.cerrado,
    required this.stanbyAbierto,
    required this.stanby,
  });

  factory EstadoCierreZona.fromJson(Map<String, dynamic> json) => EstadoCierreZona(
        zona: json['zona'],
        abierto: json['abierto'],
        cerrado: json['cerrado'],
        stanbyAbierto: json['stanbyAbierto'],
        stanby: json['stanby'],
      );

  Map<String, dynamic> toJson() => {
        'Zona': zona,
        'Abierto': abierto,
        'Cerrado': cerrado,
        'StanbyAbierto': stanbyAbierto,
        'Stanby': stanby,
      };
}
