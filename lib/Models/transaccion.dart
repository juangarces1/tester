import 'package:flutter/material.dart';
import 'package:tester/Models/product.dart';

class Transaccion {
  int idtransaccion = 0;
  int numero =0;
  String fechatransaccion = "";
  int dispensador = 0;
  int idproducto = 0;
  String nombreproducto="";
  int total = 0 ;
  double volumen = 0;
  int preciounitario = 0 ;
  int idcierre = 0 ;
  String estado ="";
  String entregatarjeta ="";
  String canjetarjeta ="";
  String pan="";
  String nombrecliente ="";
  String facturada ="";
  String? creacion;
  String? subir;

  Transaccion(
      {required this.idtransaccion,
      required this.numero,
      required this.fechatransaccion,
      required this.dispensador,
      required this.idproducto,
      required this.nombreproducto,
      required this.total,
      required this.volumen,
      required this.preciounitario,
      required this.idcierre,
      required this.estado,
      required this.entregatarjeta,
      required this.canjetarjeta,
      required this.pan,
      required this.nombrecliente,
      required this.facturada,
      this.creacion,
      this.subir});

  Transaccion.fromJson(Map<String, dynamic> json) {
    idtransaccion = json['idtransaccion'];
    numero = json['numero'];
    fechatransaccion =  json['fechatransaccion'];
    dispensador = json['dispensador'];
    idproducto = json['idproducto'];
    nombreproducto = json['nombreproducto'];
    total = json['total'];
    var x = json['volumen'];
    if (x.runtimeType==int)
    {
       volumen = (x).toDouble();
    }
    else{
        volumen = json['volumen'];
    }    
    preciounitario = json['preciounitario'];
    idcierre = json['idcierre'];
    estado = json['estado'];
    entregatarjeta = json['entregatarjeta'];
    canjetarjeta = json['canjetarjeta'];
    pan = json['pan'];
    nombrecliente = json['nombrecliente'];
    facturada = json['facturada'];
    creacion = json['creacion'];
    subir = json['subir'];
  }

  static String? _toAspNetIsoUtc(String? s) {
    if (s == null) return null;
    final raw = s.trim();
    if (raw.isEmpty) return null;

    // Intenta parsear con DateTime (acepta muchos formatos ISO y comunes)
    DateTime? dt = DateTime.tryParse(raw);

    // Si tu app genera otros formatos (dd/MM/yyyy HH:mm, etc), parsea manual:
    // if (dt == null) {
    //   dt = DateFormat('dd/MM/yyyy HH:mm').parse(raw, true); // 'true' => UTC
    // }

    if (dt == null) return raw; // último recurso: manda como venía (evitar null)

    // si no tiene zona, asume que es hora local del dispositivo
    if (!dt.isUtc) dt = dt.toUtc();

    // ASP.NET Core acepta milisegundos, pero a veces prefieres quitarlos
    final iso = dt.toIso8601String(); // ej: 2025-10-06T20:15:00.123Z
    final zIndex = iso.indexOf('Z');
    final dot = iso.indexOf('.');
    return (dot > 0 && zIndex > dot)
        ? '${iso.substring(0, dot)}Z'     // 2025-10-06T20:15:00Z
        : (iso.endsWith('Z') ? iso : '${iso}Z');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['idtransaccion'] = idtransaccion;
    data['numero'] = numero;
    data['fechatransaccion'] = _toAspNetIsoUtc(fechatransaccion);
    data['dispensador'] = dispensador;
    data['idproducto'] = idproducto;
    data['nombreproducto'] = nombreproducto;
    data['total'] = total;
    data['volumen'] = volumen;
    data['preciounitario'] = preciounitario;
    data['idcierre'] = idcierre;
    data['estado'] = estado;
    data['entregatarjeta'] = entregatarjeta;
    data['canjetarjeta'] = canjetarjeta;
    data['pan'] = pan;
    data['nombrecliente'] = nombrecliente;
    data['facturada'] = facturada;
    data['creacion'] = "";
    data['subir'] = subir;
    return data;
  }
  bool get isUnpaid =>
      estado.toLowerCase() == 'copiado';
  bool get isFacturada =>
      facturada.trim().toUpperCase() == 'SI';
}

extension TransaccionToProduct on Transaccion {
  /// Convierte esta Transaccion en un Product listo para facturar / carrito.
  ///
  /// - `codigoArticulo`: si no lo pasas, usa el `idproducto` como SKU ("<id>").
  /// - `unidad`: por defecto "L" (combustible). Cambia a "UN", etc. si aplica.
  /// - `detalle`: si no se pasa, arma: "<nombre> · M-<dispensador> · <precio>/unidad · <volumen> <unidad>"
  /// - Impuestos: por defecto 0; puedes inyectar `tasaImp` e `impMonto`.
  /// - Campos opcionales del dominio (Cabys, RateId/TaxId, TipoCodigoPS, etc.) quedan para que tú los llenes.
  Product toProduct({
    String? codigoArticulo,
    String unidad = 'L',
    String? detalle,

    // Impuestos / precios
    double tasaImp = 0,
    double impMonto = 0,
    double? precioCompra,

    // Catalogación / impuestos externos
    String codigoCabys = '',
    int rateId = 0,
    int taxId = 0,
    String? codigoTipoTrans,
    String? tipoCodigoPS,
    String servicio = '0', // "0" servicio no-tributario según tu regla -> productType "1"

    // Inventario / UI
    String imageUrl = 'NoImage.jpg',
    int inventario = 0,
    List<String> images = const [],
    List<Color> colors = const [],

    // Descuentos si aplican
    int descuento = 0,
    double nDescuento = 0,
  }) {
    final sku = codigoArticulo ?? idproducto.toString();

    final precioUnitD = preciounitario.toDouble();
    final totalD      = total.toDouble();
    final cant        = volumen; // litros

    final desc = detalle ??
        '${nombreproducto.isNotEmpty ? nombreproducto : 'Combustible $idproducto'} · '
        'M-$dispensador · ${precioUnitD.toStringAsFixed(2)}/$unidad · '
        '${cant.toStringAsFixed(3)} $unidad';

    // Subtotal “neto” si ya tienes `impMonto`; si no manejas impuestos en this, queda = total
    final subtotalCalc = (totalD - impMonto);

    return Product(
      // === Campos “C#” ===
      codigoArticulo: sku,
      numero: numero > 0 ? '#$numero' : '',

      cantidad: cant,
      tipoArticulo: 'Combustible',
      unidad: unidad,
      detalle: desc,

      precioUnit: precioUnitD,
      montoTotal: totalD,          // si tu API lo usa distinto al `total`, ajústalo
      descuento: descuento,
      nDescuento: nDescuento,
      subtotal: subtotalCalc < 0 ? 0 : subtotalCalc,
      tasaImp: tasaImp,
      impMonto: impMonto,
      total: totalD,

      rateid: rateId,
      taxid: taxId,
      precioCompra: precioCompra ?? 0,
      codigoCabys: codigoCabys,

      transaccion: idtransaccion,  // vínculo duro a la transacción
      factor: 0,                   // por si calculas equivalencias (galón→litro)
      dispensador: dispensador,

      imageUrl: imageUrl,
      inventario: 0,

      codigoTipoTrans: codigoTipoTrans,
      tipoCodigoPS: tipoCodigoPS,
      servicio: "1",          // mantiene la lógica de Product.productType

      // === App-only ===
      images: images,
      colors: colors,
      isFavourite: false,
      isPopular: false,
    );
  }
}