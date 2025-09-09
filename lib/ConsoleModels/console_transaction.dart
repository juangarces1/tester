import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/transaccion.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';

class ConsoleTransaction {
  final int id;
  final int fuelingIndex;
  final int nozzleNumber;
  final int fuelCode;
  final int fuelTankNumber;

  final double totalValue;
  final double totalVolume;
  final double unitPrice;

  final int duration;
  final DateTime dateTime;

  final int initialTotalizer;
  final int finalTotalizer;

  /// Puede exceder 64 bits; se guarda como String para no perder precisión.
  final String? attendantId;
  final String? attendantIdRaw;

  final int? customerId;
  final double? currentVolume;

  final int saleStatus;
  final int saleNumber;
  final String? saleId;

  final String? reference;
  final String? paymentType;
  final String? mode;
  final String? invoiceType;

  final int epIdEmpresa;
  final bool paymentConfirmed;

  final DateTime createdAt;
  final String? userEmail;

  const ConsoleTransaction({
    required this.id,
    required this.fuelingIndex,
    required this.nozzleNumber,
    required this.fuelCode,
    required this.fuelTankNumber,
    required this.totalValue,
    required this.totalVolume,
    required this.unitPrice,
    required this.duration,
    required this.dateTime,
    required this.initialTotalizer,
    required this.finalTotalizer,
    this.attendantId,
    this.attendantIdRaw,
    this.customerId,
    this.currentVolume,
    required this.saleStatus,
    required this.saleNumber,
    this.saleId,
    this.reference,
    this.paymentType,
    this.mode,
    this.invoiceType,
    required this.epIdEmpresa,
    required this.paymentConfirmed,
    required this.createdAt,
    this.userEmail,
  });

  // ----------------- FACTORY -----------------

  factory ConsoleTransaction.fromJson(Map<String, dynamic> json) {
    // 0) Desenvuelve { data: {...} } o { result: {...} }
    final Map<String, dynamic> j = _unwrap(json);

    // 1) Helpers de lectura
    int int0(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? intN(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double double0(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    double? doubleN(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    bool bool0(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes' || s == 'y';
      }
      return false;
    }

    String? strN(dynamic v) => v?.toString();

    // 2) Helper de búsqueda con alias y case-insensitive
    dynamic pick(List<String> names) {
      for (final n in names) {
        if (j.containsKey(n)) return j[n];
      }
      // fallback case-insensitive
      final lower = {for (final e in j.entries) e.key.toLowerCase(): e.value};
      for (final n in names) {
        final k = n.toLowerCase();
        if (lower.containsKey(k)) return lower[k];
      }
      return null;
    }

    return ConsoleTransaction(
      id: int0(pick(const ['id'])),
      fuelingIndex: int0(pick(const ['fuelingIndex'])),
      nozzleNumber: int0(pick(const ['nozzleNumber'])),
      fuelCode: int0(pick(const ['fuelCode'])),
      fuelTankNumber: int0(pick(const ['fuelTankNumber'])),
      totalValue: double0(pick(const ['totalValue'])),
      totalVolume: double0(pick(const ['totalVolume'])),
      unitPrice: double0(pick(const ['unitPrice'])),
      duration: int0(pick(const ['duration'])),
      dateTime: _parseApiDate(pick(const ['dateTime'])),
      initialTotalizer: int0(pick(const ['initialTotalizer'])),
      finalTotalizer: int0(pick(const ['finalTotalizer'])),
      attendantId: strN(pick(const ['attendantId'])),
      attendantIdRaw: strN(pick(const ['attendantIdRaw'])),
      customerId: intN(pick(const ['customerId'])),
      currentVolume: doubleN(pick(const ['currentVolume'])),
      saleStatus: int0(pick(const ['saleStatus'])),
      saleNumber: int0(pick(const ['saleNumber'])),
      saleId: strN(pick(const ['saleId'])),
      reference: strN(pick(const ['reference'])),
      // Puede venir como número → lo convertimos a String
      paymentType: strN(pick(const ['paymentType'])),
      mode: strN(pick(const ['mode'])),
      invoiceType: strN(pick(const ['invoiceType'])),
      // Acepta distintas variantes
      epIdEmpresa: int0(pick(const ['eP_Id_Empresa', 'epIdEmpresa', 'EP_Id_Empresa'])),
      paymentConfirmed: bool0(pick(const ['paymentConfirmed'])),
      createdAt: _parseApiDate(pick(const ['createdAt'])),
      userEmail: strN(pick(const ['userEmail'])),
    );
  }

  // ----------------- SERIALIZACIÓN -----------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'fuelingIndex': fuelingIndex,
        'nozzleNumber': nozzleNumber,
        'fuelCode': fuelCode,
        'fuelTankNumber': fuelTankNumber,
        'totalValue': totalValue,
        'totalVolume': totalVolume,
        'unitPrice': unitPrice,
        'duration': duration,
        'dateTime': _toApiDate(dateTime),
        'initialTotalizer': initialTotalizer,
        'finalTotalizer': finalTotalizer,
        // Se exporta como String para no perder precisión.
        'attendantId': attendantId,
        'attendantIdRaw': attendantIdRaw,
        'customerId': customerId,
        'currentVolume': currentVolume,
        'saleStatus': saleStatus,
        'saleNumber': saleNumber,
        'saleId': saleId,
        'reference': reference,
        'paymentType': paymentType,
        'mode': mode,
        'invoiceType': invoiceType,
        'eP_Id_Empresa': epIdEmpresa,
        'paymentConfirmed': paymentConfirmed,
        'createdAt': _toApiDate(createdAt),
        'userEmail': userEmail,
      };

  // ----------------- COPYWITH (con sentinel) -----------------

  static const _unset = Object();

  ConsoleTransaction copyWith({
    // No anulables (tipados normales)
    int? id,
    int? fuelingIndex,
    int? nozzleNumber,
    int? fuelCode,
    int? fuelTankNumber,
    double? totalValue,
    double? totalVolume,
    double? unitPrice,
    int? duration,
    DateTime? dateTime,
    int? initialTotalizer,
    int? finalTotalizer,
    int? saleStatus,
    int? saleNumber,
    int? epIdEmpresa,
    bool? paymentConfirmed,
    DateTime? createdAt,

    // Anulables (usar sentinel para poder asignar null explícito)
    Object? attendantId = _unset,
    Object? attendantIdRaw = _unset,
    Object? customerId = _unset,
    Object? currentVolume = _unset,
    Object? saleId = _unset,
    Object? reference = _unset,
    Object? paymentType = _unset,
    Object? mode = _unset,
    Object? invoiceType = _unset,
    Object? userEmail = _unset,
  }) {
    String? castStr(Object? v, String? cur) =>
        identical(v, _unset) ? cur : v as String?;
    int? castInt(Object? v, int? cur) =>
        identical(v, _unset) ? cur : v as int?;
    double? castDouble(Object? v, double? cur) =>
        identical(v, _unset) ? cur : v as double?;

    return ConsoleTransaction(
      id: id ?? this.id,
      fuelingIndex: fuelingIndex ?? this.fuelingIndex,
      nozzleNumber: nozzleNumber ?? this.nozzleNumber,
      fuelCode: fuelCode ?? this.fuelCode,
      fuelTankNumber: fuelTankNumber ?? this.fuelTankNumber,
      totalValue: totalValue ?? this.totalValue,
      totalVolume: totalVolume ?? this.totalVolume,
      unitPrice: unitPrice ?? this.unitPrice,
      duration: duration ?? this.duration,
      dateTime: dateTime ?? this.dateTime,
      initialTotalizer: initialTotalizer ?? this.initialTotalizer,
      finalTotalizer: finalTotalizer ?? this.finalTotalizer,
      attendantId: castStr(attendantId, this.attendantId),
      attendantIdRaw: castStr(attendantIdRaw, this.attendantIdRaw),
      customerId: castInt(customerId, this.customerId),
      currentVolume: castDouble(currentVolume, this.currentVolume),
      saleStatus: saleStatus ?? this.saleStatus,
      saleNumber: saleNumber ?? this.saleNumber,
      saleId: castStr(saleId, this.saleId),
      reference: castStr(reference, this.reference),
      paymentType: castStr(paymentType, this.paymentType),
      mode: castStr(mode, this.mode),
      invoiceType: castStr(invoiceType, this.invoiceType),
      epIdEmpresa: epIdEmpresa ?? this.epIdEmpresa,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      createdAt: createdAt ?? this.createdAt,
      userEmail: castStr(userEmail, this.userEmail),
    );
  }

  // ----------------- HELPERS FECHA -----------------

  static String _toApiDate(DateTime dt) {
    // "YYYY-MM-DDTHH:mm:ss" (sin milisegundos)
    return dt.toIso8601String().split('.').first;
  }

  static DateTime _parseApiDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;

    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
      final parsed = DateTime.tryParse(s);
      return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (v is num) {
      final i = v.toInt();
      final isMillis = i > 9999999999; // >10 dígitos => milisegundos
      return DateTime.fromMillisecondsSinceEpoch(isMillis ? i : i * 1000);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ----------------- HELPERS UNWRAP -----------------

  static Map<String, dynamic> _unwrap(Map<String, dynamic> src) {
    final d = src['data'];
    if (d is Map<String, dynamic>) return d;
    final r = src['result'];
    if (r is Map<String, dynamic>) return r;
    return src;
  }
}

extension ConsoleTxToProduct on ConsoleTransaction {
  Product toInvoiceProduct({
    required String codigoArticulo,       // mapea fuelCode -> SKU de tu inventario
    String tipoArticulo = 'Combustible',
    String unidad = 'L',
    String? detalle,
    String imageUrl = 'NoImage.jpg',
    int inventario = 0,
    int rateId = 0,
    int taxId = 0,
    String codigoCabys = '',
    double tasaImp = 0,
    double impMonto = 0,
    double precioCompra = 0,
    List<String> images = const [],
    List<Color> colors = const [],
  }) {
    final desc = detalle ??
        'Fuel $fuelCode · Manguera $nozzleNumber · '
        '${unitPrice.toStringAsFixed(2)}/$unidad · ${totalVolume.toStringAsFixed(3)} $unidad';

    return Product(
      // opcional: numero
      cantidad: totalVolume,             // litros
      tipoArticulo: tipoArticulo,
      codigoArticulo: codigoArticulo,
      unidad: unidad,                    // 'L'
      detalle: desc,
      precioUnit: unitPrice,             // precio por litro
      montoTotal: totalValue,            // por si lo usas en UI
      descuento: 0,
      nDescuento: 0,
      subtotal: (totalValue - impMonto), // si no manejas impuestos, deja = totalValue
      tasaImp: tasaImp,
      impMonto: impMonto,
      total: totalValue,                 // ⚠️ tu Invoice.total usa este cuando unidad == 'L'
      rateid: rateId,
      taxid: taxId,
      precioCompra: precioCompra,
      codigoCabys: codigoCabys,
      transaccion: id,                   // vínculo para luego marcar como pagada
      factor: 1,
      dispensador: nozzleNumber,
      imageUrl: imageUrl,
      inventario: inventario,
      images: images,
      colors: colors,
    );
  }
}



extension ConsoleTxToLegacyTransaccion on ConsoleTransaction {
  Transaccion toTransaccion({
    // 👉 Nuevo: permite resolver el id desde Provider si pasas context
    BuildContext? context,
    int? idCierre,

    String? nombreProducto,
    String facturada = 'No',
    String entregoTarjeta = '',
    String canjeTarjeta = '',
    String pan = '',
    String? subir,
    String? nombreCliente,

    // Estrategias
    String Function(DateTime dt)? dateFormat,
    String Function(int saleStatus)? estadoMapper,
    int Function(double valor)? redondeoImporte,
  }) {
    // 1) Formato de fecha por defecto
    final fmt = dateFormat ?? (dt) => dt.toIso8601String().split('.').first;

    // 2) Mapeo de estado por defecto
    

    // 3) Redondeo/entero para montos/precios
    final toInt = redondeoImporte ?? ((v) => v.toInt());

    // 4) Resolver idCierre:
    //    - Si viene por parámetro, manda ese.
    //    - Si no, intenta leerlo del CierreActivoProvider con context.
    //    - Si nada de lo anterior existe, 0.
    int resolvedIdCierre = idCierre ??
        (() {
          if (context == null) return 0;
          try {
            final prov = context.read<CierreActivoProvider>();
            // Usa el getter o el objeto directo, según tu implementación:
            return prov.cierreFinal?.idcierre
                ?? prov.value?.cierreFinal.idcierre
                ?? 0;
          } catch (_) {
            // Provider no está disponible en este contexto
            return 0;
          }
        })();

    return Transaccion(
      idtransaccion: 0,
      numero: id, // o fuelingIndex si prefieres
      fechatransaccion: fmt(dateTime),
      dispensador: nozzleNumber,
      idproducto: fuelCode,
      nombreproducto: nombreProducto ?? 'Fuel $fuelCode',
      total: toInt(totalValue),
      volumen: totalVolume,
      preciounitario: toInt(unitPrice),
      idcierre: resolvedIdCierre,         // 👈 ahora viene del provider/param
      estado: 'copiado',
      entregatarjeta: entregoTarjeta,
      canjetarjeta: canjeTarjeta,
      pan: pan,
      nombrecliente: nombreCliente ?? (userEmail ?? ''),
      facturada: facturada,
      creacion: fmt(createdAt),
      subir: subir,
    );
  }
}

