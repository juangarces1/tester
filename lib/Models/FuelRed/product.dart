import 'package:flutter/material.dart';

class Product {
  // ==== Campos equivalentes a C# ====
  String codigoArticulo;         // codigo_articulo
  String numero;                 // numero
  double cantidad;               // cantidad
  String tipoArticulo;           // tipo_articulo
  String unidad;                 // unidad
  String detalle;                // detalle
  double precioUnit;             // precio_unit
  double montoTotal;             // monto_total
  int descuento;                 // descuento
  double nDescuento;             // N_descuento
  double subtotal;               // subtotal
  double tasaImp;                // tasa_imp
  double impMonto;               // imp_monto
  double total;                  // total
  int rateid;                    // rateid
  int taxid;                     // taxid
  double precioCompra;           // precio_compra
  String codigoCabys;            // CodigoCabys/codigoCabys
  int transaccion;               // transaccion
  double factor;                 // factor
  int dispensador;               // dispensador
  String imageUrl;               // ImageUrl/imageUrl
  int inventario;                // Inventario/inventario
  String? codigoTipoTrans;       // CodigoTipoTrans/codigoTipoTrans
  String? tipoCodigoPS;          // TipoCodigoPS/tipoCodigoPS
  String servicio;               // SERVICIO/servicio

  // Derivado (como en C#): "1" si servicio == "0"; "2" si no.
  String get productType => servicio == "0" ? "1" : "2";

  // ==== Campos propios de la app (mantengo lo que ya tenías) ====
  List<String> images;
  List<Color> colors;
  bool isFavourite;
  bool isPopular;

  Product({
    // C# fields
    required this.codigoArticulo,
    this.numero = "",
    this.cantidad = 0,
    this.tipoArticulo = "",
    this.unidad = "",
    required this.detalle,
    this.precioUnit = 0,
    this.montoTotal = 0,
    this.descuento = 0,
    this.nDescuento = 0,
    this.subtotal = 0,
    this.tasaImp = 0,
    this.impMonto = 0,
    this.total = 0,
    this.rateid = 0,
    this.taxid = 0,
    this.precioCompra = 0,
    this.codigoCabys = "",
    this.transaccion = 0,
    this.factor = 0,
    this.dispensador = 0,
    this.imageUrl = "NoImage.jpg",
    this.inventario = 0,
    this.codigoTipoTrans,
    this.tipoCodigoPS,
    this.servicio = "0",

    // App-only
    required this.images,
    required this.colors,
    this.isFavourite = false,
    this.isPopular = false,
  });

  // Helpers para parse robusto (acepta num/String/null)
  static double _toDouble(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  static int _toInt(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static String _toStr(dynamic v, [String def = ""]) {
    if (v == null) return def;
    return v.toString();
  }

  /// Crea desde JSON. Tolera claves en snake_case, camelCase y PascalCase.
  Product.fromJson(Map<String, dynamic> json)
      : codigoArticulo  = _toStr(json['codigo_articulo'] ?? json['codigoArticulo'] ?? json['CodigoArticulo']),
        numero           = _toStr(json['numero'] ?? json['Numero']),
        cantidad         = _toDouble(json['cantidad']),
        tipoArticulo     = _toStr(json['tipo_articulo'] ?? json['tipoArticulo'] ?? json['TipoArticulo']),
        unidad           = _toStr(json['unidad'] ?? json['Unidad']),
        detalle          = _toStr(json['detalle'] ?? json['Detalle']),
        precioUnit       = _toDouble(json['precio_unit'] ?? json['precioUnit'] ?? json['PrecioUnit']),
        montoTotal       = _toDouble(json['monto_total'] ?? json['montoTotal'] ?? json['MontoTotal']),
        descuento        = _toInt(json['descuento'] ?? json['Descuento']),
        nDescuento       = _toDouble(json['N_descuento'] ?? json['nDescuento'] ?? json['NDescuento']),
        subtotal         = _toDouble(json['subtotal'] ?? json['Subtotal']),
        tasaImp          = _toDouble(json['tasa_imp'] ?? json['tasaImp'] ?? json['TasaImp']),
        impMonto         = _toDouble(json['imp_monto'] ?? json['impMonto'] ?? json['ImpMonto']),
        total            = _toDouble(json['total'] ?? json['Total']),
        rateid           = _toInt(json['rateid'] ?? json['RateId'] ?? json['rateId']),
        taxid            = _toInt(json['taxid'] ?? json['TaxId'] ?? json['taxId']),
        precioCompra     = _toDouble(json['precio_compra'] ?? json['precioCompra'] ?? json['PrecioCompra']),
        codigoCabys      = _toStr(json['CodigoCabys'] ?? json['codigoCabys'] ?? json['codigo_cabys']),
        transaccion      = _toInt(json['transaccion'] ?? json['Transaccion']),
        factor           = _toDouble(json['factor'] ?? json['Factor']),
        dispensador      = _toInt(json['dispensador'] ?? json['Dispensador']),
        imageUrl         = _toStr(json['imageUrl'] ?? json['ImageUrl'] ?? json['imagen'] ?? 'NoImage.jpg'),
        inventario       = _toInt(json['inventario'] ?? json['Inventario']),
        codigoTipoTrans  = json.containsKey('CodigoTipoTrans')
                              ? _toStr(json['CodigoTipoTrans'])
                              : (json.containsKey('codigoTipoTrans') ? _toStr(json['codigoTipoTrans']) : null),
        tipoCodigoPS     = json.containsKey('TipoCodigoPS')
                              ? _toStr(json['TipoCodigoPS'])
                              : (json.containsKey('tipoCodigoPS') ? _toStr(json['tipoCodigoPS']) : null),
        servicio         = _toStr(json['SERVICIO'] ?? json['servicio'] ?? "0"),
        // app-only con valores por defecto
        images           = <String>[],
        colors           = <Color>[],
        isFavourite      = false,
        isPopular        = false;

  /// Serialización estándar (respeta snake_case como en tu API).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'codigo_articulo': codigoArticulo,
      'numero': numero,
      'cantidad': cantidad,
      'tipo_articulo': tipoArticulo,
      'unidad': unidad,
      'detalle': detalle,
      'precio_unit': precioUnit,
      'monto_total': montoTotal,
      'descuento': descuento,
      'N_descuento': nDescuento,
      'subtotal': subtotal,
      'tasa_imp': tasaImp,
      'imp_monto': impMonto,
      'total': total,
      'rateid': rateid,
      'taxid': taxid,
      'precio_compra': precioCompra,
      'CodigoCabys': codigoCabys,
      'transaccion': transaccion,
      'factor': factor,
      'dispensador': dispensador,
      'imageUrl': imageUrl,
      'inventario': inventario,
      'CodigoTipoTrans': codigoTipoTrans,
      'TipoCodigoPS': tipoCodigoPS,
      'SERVICIO': servicio,
      // opcionalmente puedes enviar también el derivado:
      'ProductType': productType,
    };
  }

  /// Payload para llamadas específicas a tu API (si necesitas un subset).
  Map<String, dynamic> toApiProducJson() {
    // Mismo que toJson() para no perder campos; si quieres limitar, edita aquí.
    return toJson();
  }

  /// Total por línea (si `total` ya viene “por unidad”, ajusta según tu regla).
  double get totalProducto => total * cantidad;
}
