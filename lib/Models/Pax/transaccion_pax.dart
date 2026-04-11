import 'package:tester/Models/Pax/pax_response.dart';

/// Mirrors the TransaccionPax table in SQLSan.
/// Used to persist PAX responses to the backend.
class TransaccionPax {
  int? id;
  int? idFactura;
  int? idCierre;
  int? idDatafono;
  String? respCode;
  String? autorizacion;
  String? stan;
  String? panMasked;
  String? rrn;
  String? recibo;
  String? terminalId;
  String? merchantId;
  String? cardHolder;
  String? issuerName;
  String? posEntryMode;
  String? cardHash;
  double? totalAmount;
  double? baseAmount;
  double? tipAmount;
  double? taxAmount;
  String? ticket;
  String? txnId;
  String? fechaPax;
  String? aid;
  String? appLabel;
  String? arqc;
  String? tvr;
  DateTime? fechaRegistro;

  TransaccionPax({
    this.id,
    this.idFactura,
    this.idCierre,
    this.idDatafono,
    this.respCode,
    this.autorizacion,
    this.stan,
    this.panMasked,
    this.rrn,
    this.recibo,
    this.terminalId,
    this.merchantId,
    this.cardHolder,
    this.issuerName,
    this.posEntryMode,
    this.cardHash,
    this.totalAmount,
    this.baseAmount,
    this.tipAmount,
    this.taxAmount,
    this.ticket,
    this.txnId,
    this.fechaPax,
    this.aid,
    this.appLabel,
    this.arqc,
    this.tvr,
    this.fechaRegistro,
  });

  /// Create from a PaxResponse after a successful PAX call.
  factory TransaccionPax.fromPaxResponse(
    PaxResponse response, {
    int? idFactura,
    int? idCierre,
    int? idDatafono,
  }) {
    return TransaccionPax(
      idFactura: idFactura,
      idCierre: idCierre,
      idDatafono: idDatafono,
      respCode: response.respCode,
      autorizacion: response.autorizacion,
      stan: response.stan,
      panMasked: response.panMasked,
      rrn: response.rrn,
      recibo: response.recibo,
      terminalId: response.terminalId,
      merchantId: response.merchantId,
      cardHolder: response.cardHolder,
      issuerName: response.issuerName,
      posEntryMode: response.posEntryMode,
      cardHash: response.cardHash,
      totalAmount: _parseAmount(response.totalAmount),
      baseAmount: _parseAmount(response.baseAmount),
      tipAmount: _parseAmount(response.tipAmount),
      taxAmount: _parseAmount(response.taxAmount),
      ticket: response.ticket,
      txnId: response.txnId,
      fechaPax: response.date,
      aid: response.aid,
      appLabel: response.appLabel,
      arqc: response.arqc,
      tvr: response.tvr,
    );
  }

  factory TransaccionPax.fromJson(Map<String, dynamic> json) {
    return TransaccionPax(
      id: json['id'],
      idFactura: json['idFactura'],
      idCierre: json['idCierre'],
      idDatafono: json['idDatafono'],
      respCode: json['respCode'],
      autorizacion: json['autorizacion'],
      stan: json['stan'],
      panMasked: json['panMasked'],
      rrn: json['rrn'],
      recibo: json['recibo'],
      terminalId: json['terminalId'],
      merchantId: json['merchantId'],
      cardHolder: json['cardHolder'],
      issuerName: json['issuerName'],
      posEntryMode: json['posEntryMode'],
      cardHash: json['cardHash'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      baseAmount: (json['baseAmount'] as num?)?.toDouble(),
      tipAmount: (json['tipAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      ticket: json['ticket'],
      txnId: json['txnId'],
      fechaPax: json['fechaPax'],
      aid: json['aid'],
      appLabel: json['appLabel'],
      arqc: json['arqc'],
      tvr: json['tvr'],
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.parse(json['fechaRegistro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFactura': idFactura,
      'idCierre': idCierre,
      'idDatafono': idDatafono,
      'respCode': respCode,
      'autorizacion': autorizacion,
      'stan': stan,
      'panMasked': panMasked,
      'rrn': rrn,
      'recibo': recibo,
      'terminalId': terminalId,
      'merchantId': merchantId,
      'cardHolder': cardHolder,
      'issuerName': issuerName,
      'posEntryMode': posEntryMode,
      'cardHash': cardHash,
      'totalAmount': totalAmount,
      'baseAmount': baseAmount,
      'tipAmount': tipAmount,
      'taxAmount': taxAmount,
      'ticket': ticket,
      'txnId': txnId,
      'fechaPax': fechaPax,
      'aid': aid,
      'appLabel': appLabel,
      'arqc': arqc,
      'tvr': tvr,
    };
  }

  /// Parse PAX amount strings like "CRC11.00" or "-CRC10.00" to double.
  static double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
}
