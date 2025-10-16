class LineaInventario {
  final int id;
  final int? idBodega;
  final String? articulo;
  final String? codigo;
  final DateTime? fecha;
  final int? usuario;
  final int? cantidad;
  final int? idCierre;

  LineaInventario({
    required this.id,
    this.idBodega,
    this.articulo,
    this.codigo,
    this.fecha,
    this.usuario,
    this.cantidad,
    this.idCierre,
  });

  factory LineaInventario.fromJson(Map<String, dynamic> json) => LineaInventario(
        id: json['id'],
        idBodega: json['idbodega'],
        articulo: json['articulo'],
        codigo: json['codigo'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
        usuario: json['usuario'],
        cantidad: json['cantidad'],
        idCierre: json['idcierre'],
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Idbodega': idBodega,
        'Articulo': articulo,
        'Codigo': codigo,
        'Fecha': fecha?.toIso8601String(),
        'Usuario': usuario,
        'Cantidad': cantidad,
        'Idcierre': idCierre,
      };
}
