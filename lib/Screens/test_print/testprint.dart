import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Models/FuelRed/cashback.dart';
import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/deposito.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/transferencia.dart';

import 'package:tester/Models/FuelRed/viatico.dart';
import 'package:tester/clases/q3_printer.dart';

class TestPrint {
  /// Ancho lógico (caracteres) por línea. 32 suele ir bien en Q3.
  final int totalChars;
  TestPrint({this.totalChars = 32});

  // ==================== Formateo ====================
  static final NumberFormat _crc =
      NumberFormat.currency(locale: 'es_CR', symbol: '₡', decimalDigits: 0);
  static String money(num v) => _crc.format(v);

  static String qty(num v) {
    // cantidades: 0 o 1 decimal “bonito”
    return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  // ==================== Infra boilerplate ====================
  // Future<void> _ensureBound() async {
  //   final ok = await Q3Printer.bind();
  //   if (!ok) throw Exception('No se pudo conectar con el servicio de impresión');
  // }

  Future<void> _beginDoc() async {
    await Q3Printer.init();
    await Q3Printer.setAlignment(0);
    await Q3Printer.setFontType('DEFAULT');
    await Q3Printer.setFontSize(22);
  }

  Future<void> _endDoc() async {
    await Q3Printer.printBlankLines(2, 25);
    await Q3Printer.performPrint(60);
  }

  // ==================== Helpers visuales ====================
  Future<void> separator([String char = '-']) async {
    final n = max(1, totalChars);
    await Q3Printer.printText('${List.filled(n, char).join()}\n');
  }

 Future<void> title(String text) async {
  await Q3Printer.setAlignment(1);
  await Q3Printer.setFontSize(48); // OK en tu equipo
  await Q3Printer.printText('$text\n');
  await Q3Printer.setFontSize(44); // baja a 24 como “base” segura
}

Future<void> subtitle(String text) async {
  await Q3Printer.setAlignment(1);
  await Q3Printer.setFontSize(32); // 26 a veces falla; usa 24
  await Q3Printer.printText('$text\n');
  await Q3Printer.setFontSize(24); // vuelve a cuerpo
}

Future<void> body() async {
  await Q3Printer.setAlignment(0);
  await Q3Printer.setFontSize(28);
}


  int get wide => totalChars;

// Recorta o rellena a la derecha
String _clipRight(String s, int w) {
  if (s.length <= w) return s.padRight(w, ' ');
  return s.substring(0, w);
}

// Alinea a la derecha
String _clipLeft(String s, int w) {
  if (s.length <= w) return s.padLeft(w, ' ');
  return s.substring(s.length - w);
}

/// Línea izquierda + derecha, sin usar printColumnsText.
Future<void> lr(String left, String right, {int minRight = 8}) async {
  await Q3Printer.setAlignment(0);      // izquierda
  await Q3Printer.setFontType('DEFAULT'); // o 'MONOSPACE' si la tiene y te gusta más

  left  = left.replaceAll('\n', ' ').trim();
  right = right.replaceAll('\n', ' ').trim();

  final rw = right.isEmpty ? minRight : (right.length + 1).clamp(minRight, wide - 1);
  final lw = (wide - rw);

  final l = _clipRight(left, lw);
  final r = _clipLeft(right, rw);

  await Q3Printer.printText('$l$r');
}

// Future<void> lrMoney(String left, num value, {int minRight = 10, bool emphasize = true}) async {
//   await Q3Printer.setAlignment(0);
//   await Q3Printer.setFontType('DEFAULT');

//   if (emphasize) {
//     await Q3Printer.setFontSize(32); // 🔥 más grande para montos
//   }

//   await lr(left, money(value), minRight: minRight);

//   if (emphasize) {
//     await Q3Printer.setFontSize(24); // 👈 vuelve al tamaño “base” de cuerpo
//   }
// }

/// Imprime una línea con texto a la izquierda y un monto a la derecha
/// utilizando el método nativo 'printColumnsText'.
///
/// CORRECCIÓN: Se asegura de que la suma de los anchos de columna sea
/// menor que el ancho total del papel para evitar el error "table with error!".
Future<void> lrMoney(
  String left,
  num value, {
  bool emphasize = true,
}) async {
  if (emphasize) {
    await Q3Printer.setFontSize(28);
  }

  final List<String> colsText = [left, money(value)];
  final List<int> colsAlign = [0, 2]; // [Izquierda, Derecha]

  // --- CÁLCULO DE ANCHO CORREGIDO ---
  // El ancho total de las columnas debe ser <= totalChars - (margen).
  // Basado en el ejemplo funcional (16+10=26 para un papel de 32),
  // dejaremos un margen de seguridad.

  const int rightColumnWidth = 12; // Ancho generoso para el monto.
  
  // Dejamos un margen de seguridad (ej. 1 o 2 caracteres).
  const int safetyMargin = 1;
  
  // El ancho izquierdo es el resto, menos el margen.
  final int leftColumnWidth = totalChars - rightColumnWidth - safetyMargin;

  // Verificación para evitar anchos negativos si la configuración es incorrecta.
  if (leftColumnWidth <= 0) {
    // Esto solo ocurriría si totalChars es muy pequeño.
    // En este caso, es mejor no imprimir que causar un error nativo.
    debugPrint('Error: El cálculo del ancho de columna resultó en un valor no positivo.');
    return;
  }

  final List<int> colsWidth = [10, 16]; // Ej: [19, 12] -> suma 31

  // ------------------------------------

  await Q3Printer.printColumnsText(colsText, colsWidth, colsAlign);

  if (emphasize) {
    await Q3Printer.setFontSize(24);
  }
}

  /// Envuelve el texto de la izquierda en múltiples líneas, manteniendo
  /// la cifra (derecha) sólo en la primera línea.
 Future<void> lrWrapLeft(String left, String right, {int minRight = 8}) async {
  await Q3Printer.setAlignment(0);

  left  = left.replaceAll('\n', ' ').trim();
  right = right.replaceAll('\n', ' ').trim();

  final rw = right.isEmpty ? minRight : (right.length + 1).clamp(minRight, wide - 1);
  final lw = (wide - rw);

  // Primera línea: left + right
  final firstLeft = _clipRight(left, lw);
  final firstRight = _clipLeft(right, rw);
  await Q3Printer.printText('$firstLeft$firstRight\n');

  // Líneas siguientes: sólo left envuelto
  var rest = left.length > lw ? left.substring(lw) : '';
  while (rest.isNotEmpty) {
    final chunk = _clipRight(rest, wide);
    await Q3Printer.printText('$chunk\n');
    rest = rest.length > wide ? rest.substring(wide) : '';
  }
}


  /// Bloque “Firma” sin guiones bajos (espacio en blanco suficiente).
  Future<void> signatureBox({String label = 'Firma Cliente:'}) async {
    await Q3Printer.setAlignment(0);
    await Q3Printer.printText('$label\n');
    await Q3Printer.printBlankLines(4, 15); // espacio para firmar
  }

  // ==================== DEMO SIMPLE ====================
  Future<void> sample() async {
    try {
    //  await _ensureBound();
      await _beginDoc();

      await title('ESTACION SAN GERARDO');
      await subtitle('GRUPO POJI S.A.');
      await separator();

      await body();
      await Q3Printer.printText('Demo de impresión nativa (Q3)\n');
      await Q3Printer.printText('Línea normal\n');
      await separator();

      await lrMoney('Subtotal', 12345);
      await lrMoney('Impuestos', 1235);
      await Q3Printer.setFontSize(26);
      await lrMoney('TOTAL', 13580);
      await Q3Printer.setFontSize(22);

      await _endDoc();
    } catch (e, st) {
      debugPrint('sample() error: $e\n$st');
      Fluttertoast.showToast(msg: 'Error imprimiendo: $e');
      rethrow;
    }
  }

  // ==================== FACTURA ====================
  Future<void> printFactura(
    Factura fac,
    String tipoDoc,
    String tipoCliente,
  ) async {
    final dfi = DateFormat('yyyy-MM-dd HH:mm');
    try {
   //   await _ensureBound();
      await _beginDoc();

      await title('ESTACION SAN GERARDO');
      await subtitle('GRUPO POJI S.A.');
      await separator();

      await body();
      await lr('Ced Jur:', '3-101-110670');
      await Q3Printer.setAlignment(1);
      await Q3Printer.printText('Chomes, Puntarenas\n');
      await Q3Printer.printText('100 mts sur de la CCSS\n');
      await Q3Printer.printText('info@estacionsangerardo.com\n');
      await Q3Printer.printBlankLines(1, 20);

      await subtitle(tipoDoc);
      final claveStr = (fac.clave ?? '').toString();
      if (claveStr.length >= 40) {
        await Q3Printer.printText('${claveStr.substring(21, 40)}\n');
      }
      await Q3Printer.printBlankLines(1, 15);

      await Q3Printer.setAlignment(0);
      await Q3Printer.printText('CLAVE\n$claveStr\n');
      await lr('Factura', fac.nFactura);
      await Q3Printer.printBlankLines(1, 12);

      await lr('Forma Pago', tipoCliente == 'CONTADO' ? 'Contado' : 'Crédito');
      await lr('Fecha', dfi.format(fac.fechaHoraTrans));
      await lr('Pistero', '${fac.usuario}');
      await Q3Printer.printBlankLines(1, 15);

      if (tipoDoc != 'TICKET') {
        await Q3Printer.printText('Cliente: ${fac.cliente}\n');
        await Q3Printer.printText('# Identificación: ${fac.identificacion}\n');
        await Q3Printer.printText('Tel: ${fac.telefono}\n');
        await Q3Printer.printText('Email: ${fac.email}\n');
        await Q3Printer.printBlankLines(1, 12);
      }

      if ((fac.nPlaca ?? '').toString().isNotEmpty) {
        await Q3Printer.printText('Placa: ${fac.nPlaca}\n');
      }
      if ((fac.kilometraje ?? 0) > 0) {
        await Q3Printer.printText('Kilometraje: ${fac.kilometraje}\n');
      }
      if ((fac.observaciones ?? '').toString().isNotEmpty) {
        await Q3Printer.printText('Obs: ${fac.observaciones}\n');
      }

      await Q3Printer.printBlankLines(1, 12);
      await subtitle('Detalle');
      await body();

      // Detalle (ajusta a tu modelo real)
      for (final d in fac.detalles) {
        // descripción envuelta con subtotal a la derecha
        await lrWrapLeft(d.detalle, money(d.subtotal));
        // línea info: cantidad y precio unitario
        await lr('Cant: ${qty(d.cantidad)}  x  ${money(d.precioUnit)}', '');
      }

      await separator();
      await lrMoney('Subtotal', fac.montoFactura!);
      await lrMoney('Gravado', fac.totalGravado!);
      await lrMoney('Exento', fac.totalExento!);
      await lrMoney('Impuestos', fac.totalImpuesto!);
      await lrMoney('Descuentos', fac.totalDescuento!);

      await Q3Printer.printBlankLines(1, 12);
      await Q3Printer.setFontSize(28);
      await lrMoney('TOTAL', fac.totalFactura!);
      await Q3Printer.setFontSize(22);

      await Q3Printer.printBlankLines(1, 10);
      await Q3Printer.printText('Autorizado mediante resolución DGT-R-48-2016\n');

      await _endDoc();
    } catch (e, st) {
      debugPrint('printFactura() error: $e\n$st');
      Fluttertoast.showToast(msg: 'Error imprimiendo: $e');
      rethrow;
    }
  }

  // ==================== PUNTOS: Canje ====================
  Future<void> printPuntosCanje(
    String cliente,
    String pistero,
    int acumulados,
    String doc,
    double canje,
  ) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final pts = NumberFormat('###,###', 'en_US').format(canje.round());
    final saldo = NumberFormat('###,###', 'en_US').format(acumulados - canje.round());

   // await _ensureBound();
    await _beginDoc();

    await subtitle('CANJE PUNTOS');
    await body();
    await lr('Fecha', fmt);
    await lr('Pistero', pistero);
    await Q3Printer.printBlankLines(1, 12);

    await lr('Cliente', cliente);
    await lr('Ptos Canjeados', pts);
    await lr('Doc #', doc);
    await lr('Saldo', saldo);
    await Q3Printer.printBlankLines(1, 12);

    await signatureBox();

    await _endDoc();
  }

  // ==================== PUNTOS: Acumulación ====================
  Future<void> printPuntosAcumulados(
    String cliente,
    String pistero,
    String doc,
    List<dynamic> productos,
  ) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final totalLitros = productos.fold<double>(0, (sum, p) => sum + p.cantidad);
    final puntos = (totalLitros.round() * 10).toString();

  //  await _ensureBound();
    await _beginDoc();

    await subtitle('ACUMULACIÓN DE PUNTOS');
    await body();
    await lr('Fecha', fmt);
    await lr('Pistero', pistero);
    await Q3Printer.printBlankLines(1, 12);

    await lr('Cliente', cliente);
    await Q3Printer.printText('Tr#   Comb.   Lts\n');
    await separator();

    for (final p in productos) {
      await Q3Printer.printText(
          '${p.transaccion}   ${p.detalle}   ${qty(p.cantidad)}\n');
    }

    await Q3Printer.printBlankLines(1, 10);
    await lr('Puntos Totales', puntos);
    await lr('Doc #', doc);
    await Q3Printer.printBlankLines(1, 12);

    await signatureBox();

    await _endDoc();
  }

  // ==================== Transferencia ====================
  Future<void> printTransferencia(Transferencia tr, String pistero) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //  await _ensureBound();
    await _beginDoc();

    await subtitle('TRANSFERENCIA');
    await body();
    await lr('Fecha', fmt);
    await Q3Printer.printBlankLines(1, 12);
    await Q3Printer.printText('Cliente: ${tr.transfers.first.cliente}\n');
    await Q3Printer.printBlankLines(1, 10);

    for (final t in tr.transfers) {
      await lr('# Depósito', t.numeroDeposito);
      await lr('Cuenta', t.cuenta);
      await lr('Aplicado', '${t.aplicado}');
      await lr('Saldo', '${t.saldo}');
      await separator();
    }

    await signatureBox();

    await _endDoc();
  }

  // ==================== Sinpe ====================
  Future<void> printSinpe(Sinpe sp, String pistero) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

 //   await _ensureBound();
    await _beginDoc();

    await subtitle('SINPE');
    await body();
    await lr('Fecha', fmt);
    await lr('Num', sp.numComprobante.toString());
    await lrMoney('Monto', sp.monto);
    await Q3Printer.printBlankLines(1, 10);

    final nota = (sp.nota ?? '').toString();
    if (nota.isNotEmpty) {
      await Q3Printer.printText('Nota: $nota\n');
    }

    await signatureBox();

    await _endDoc();
  }

  // ==================== CashBack ====================
  Future<void> printCashBack(Cashback cb, String pistero) async {
 //   await _ensureBound();
    await _beginDoc();

    await subtitle('CASHBACK');
    await separator();
    await body();
    await lr('Fecha', cb.fechacashback.toString());
    await lrMoney('Monto', cb.monto!);
     await separator();
    await signatureBox(label: 'Firma Recibido:');

    await _endDoc();
  }

  // ==================== Peddler ====================
  Future<void> printPeddler(Peddler pd) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final totalLts = pd.products!.fold<double>(0, (sum, p) => sum + p.cantidad);

   // await _ensureBound();
    await _beginDoc();

    await subtitle('ORDEN DESPACHO');
    await separator();
    await body();
    await lr('Fecha', fmt);
    await lr('Pistero', pd.pistero.toString());
    await Q3Printer.printText('Cliente: ${pd.cliente?.nombre ?? ""}\n');
    await Q3Printer.printText('#ID: ${pd.cliente?.documento}\n');
    await Q3Printer.printText('Email: ${pd.cliente?.email}\n');
    await Q3Printer.printBlankLines(1, 10);
    await subtitle('Detalle');
    await body();

    for (final p in pd.products!) {
      await Q3Printer.printText('Tr#: ${p.transaccion}\n');
      await Q3Printer.printText('${p.detalle}  Lts: ${qty(p.cantidad)}\n');
      await separator();
    }

    await lr('Total Lts', qty(totalLts));

    await signatureBox();

    await _endDoc();
  }

  // ==================== Cierre Datafono ====================
  Future<void> printCierreDatafono(CierreDatafono cd, String pistero) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

   // await _ensureBound();
    await _beginDoc();

    await subtitle('CIERRE DATAFONO');
    await separator();
    await body();
    await lr('Fecha', fmt);
    await lr('Lote #', cd.idcierredatafono.toString());
    await lrMoney('Monto', cd.monto!);

    // await signatureBox();

    await _endDoc();
  }

  // ==================== Viático ====================
  Future<void> printViatico(Viatico v, String pistero) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //  await _ensureBound();
    await _beginDoc();

    await subtitle('VIATICO');
    await separator();
    await body();
    await lr('Fecha', fmt);
    await lr('Placa', v.placa ?? '');
    await lrMoney('Monto', v.monto!);

    await signatureBox();

    await _endDoc();
  }


Future<void> testLikeDevice() async {
  await Q3Printer.bind();
  await Q3Printer.init();

  // Encabezado grande centrado
  await Q3Printer.setAlignment(1);
  await Q3Printer.setFontSize(48);
  await Q3Printer.printText('Intelligent POS\n');
  await Q3Printer.setFontSize(22);
  await Q3Printer.printText('Welcome to use intelligent POS\n');

  // Separador
  await Q3Printer.printText('${List.filled(32, '*').join()}\n');

  // Bloques de distintos tamaños/alineaciones
  await Q3Printer.setAlignment(0);
  await Q3Printer.setFontSize(24);
  await Q3Printer.printText('This is a line of 24 size\n');

  await Q3Printer.setAlignment(1);
  await Q3Printer.setFontSize(24);
  await Q3Printer.printText('This is a line of 24 size\n');

  await Q3Printer.setAlignment(0);
  await Q3Printer.setFontSize(32);
  await Q3Printer.printText('This is a line of 32 size\n');

  await Q3Printer.setAlignment(1);
  await Q3Printer.setFontSize(32);
  await Q3Printer.printText('This is a line of 32 size\n');

  await Q3Printer.setAlignment(0);
  await Q3Printer.setFontSize(48);
  await Q3Printer.printText('This is a line of 48 size\n');

  // Alfabeto / dígitos
  await Q3Printer.setFontSize(22);
  await Q3Printer.printText('ABCDEFGHIJKLMNOPQRSTUVWXYZ01234\n');
  await Q3Printer.printText('abcdefghijklmnopqrstuvwxyz56789\n');
  await Q3Printer.printText('κρχμνκλρκκνψρηφ\n'); // muestra UTF-8

  // QR (mismo tamaño visual que el ejemplo aprox)
  await Q3Printer.setAlignment(1);
  // modulesize ~6–8 da un QR grande; ecLevel: 1=L, 2=M, 3=Q, 4=H
  await Q3Printer.printQR('https://example.com/demo');

  await Q3Printer.setFontSize(22);
  await Q3Printer.printText('Print test completed\n');
  await Q3Printer.printText('${List.filled(32, '*').join()}\n');

  // Alimentar y ejecutar
  await Q3Printer.printBlankLines(2, 25);
  await Q3Printer.performPrint(120);
}


  // ==================== Depósito ====================
 Future<void> printDeposito(Deposito dp, String pistero) async {
  final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

   // await _ensureBound();
    await _beginDoc();

     await subtitle('Cierre #: ${dp.idcierre}');          // si ves raro el acento, prueba "DEPOSITO"
     await separator();
     await body();
     await subtitle('Cajero: $pistero');
     await body();
     await lr('Fecha', fmt);
     await lr('Moneda', dp.moneda ?? '');   
     await lrMoney('Monto: ', dp.monto!);
     await _endDoc();
  }


  Future<void> printTransaccionTx(Transaccion tx) async {
    final DateTime? parsed = tx.fechatransaccion.isNotEmpty
        ? DateTime.tryParse(tx.fechatransaccion)
        : null;
    final String fechaFmt = parsed != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal())
        : tx.fechatransaccion;
    final String venta = tx.numero > 0
        ? '#${tx.numero}'
        : (tx.idtransaccion > 0 ? 'ID ${tx.idtransaccion}' : '-');
    final String producto =
        tx.nombreproducto.isNotEmpty ? tx.nombreproducto : 'Combustible';

    await _beginDoc();
    await subtitle('TRANSACCION');
    await body();
    await lr('Venta', venta);
    await lr('Fecha', fechaFmt);
    await lr('Producto', producto);
    await lr('Estado', tx.estado);
    await lr('Volumen', '${tx.volumen.toStringAsFixed(2)} L');
    await lr('Precio/L', money(tx.preciounitario));
    await lrMoney('Total', tx.total);
    if (tx.nombrecliente.isNotEmpty) {
      await lr('Cliente', tx.nombrecliente);
    }
    await _endDoc();
  }
  // ==================== Transacción (producto simple) ====================
  Future<void> printTransaccion(Product pr) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

   // await _ensureBound();
    await _beginDoc();

    await subtitle('TRANSACCIÓN');
    await body();
    await lr('Fecha', fmt);
    await Q3Printer.printText('Trans #: ${pr.transaccion}\n');
    await Q3Printer.printText('Combustible: ${pr.detalle}\n');
    await Q3Printer.printText('Cantidad: ${qty(pr.cantidad)} lts\n');
    await Q3Printer.printText('Precio/U: ${money(pr.precioUnit)}\n');
    await lrMoney('Total', pr.total);

    await signatureBox();

    await _endDoc();
  }
}
