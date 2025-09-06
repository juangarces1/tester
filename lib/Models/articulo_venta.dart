class ArticuloVenta {
  final String codigoArticulo;
  final String descripcion;
  final double cantFacturada;
  final double precioVenta;
  final double totalImpuesto;
  final double totalVenta;

  ArticuloVenta({
    required this.codigoArticulo,
    required this.descripcion,
    required this.cantFacturada,
    required this.precioVenta,
    required this.totalImpuesto,
    required this.totalVenta,
  });

  factory ArticuloVenta.fromJson(Map<String, dynamic> json) {
    final String codigoArticulo = json['codigoArticulo'] as String? ?? '';
    final String descripcion = json['descripcion'] as String? ?? '';
    final double cantFacturada = _toDouble(json['cantFacturada']);
    final double precioVenta = _toDouble(json['precioVenta']);
    final double totalImpuesto = _toDouble(json['totalImpuesto']);
    final double totalVenta = _toDouble(json['totalVenta']);

    return ArticuloVenta(
      codigoArticulo: codigoArticulo,
      descripcion: descripcion,
      cantFacturada: cantFacturada,
      precioVenta: precioVenta,
      totalImpuesto: totalImpuesto,
      totalVenta: totalVenta,
    );
  }

  Map<String, dynamic> toJson() => {
        'CodigoArticulo': codigoArticulo,
        'Descripcion': descripcion,
        'CantFacturada': cantFacturada,
        'PrecioVenta': precioVenta,
        'TotalImpuesto': totalImpuesto,
        'TotalVenta': totalVenta,
      };

  static double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }
}
