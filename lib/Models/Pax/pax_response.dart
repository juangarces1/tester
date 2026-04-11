/// Represents the JSON response from the PAX A920 Web Service.
/// Used for venta, anulacion, and cierre operations.
class PaxResponse {
  final String respCode;
  final String autorizacion;
  final String stan;
  final String panMasked;
  final String rrn;
  final String recibo;
  final String terminalId;
  final String merchantId;
  final String cardHolder;
  final String issuerName;
  final String posEntryMode;
  final String cardHash;
  final String totalAmount;
  final String baseAmount;
  final String tipAmount;
  final String taxAmount;
  final String ticket;
  final String txnId;
  final String date;
  final String aid;
  final String appLabel;
  final String arqc;
  final String tvr;

  PaxResponse({
    this.respCode = '',
    this.autorizacion = '',
    this.stan = '',
    this.panMasked = '',
    this.rrn = '',
    this.recibo = '',
    this.terminalId = '',
    this.merchantId = '',
    this.cardHolder = '',
    this.issuerName = '',
    this.posEntryMode = '',
    this.cardHash = '',
    this.totalAmount = '',
    this.baseAmount = '',
    this.tipAmount = '',
    this.taxAmount = '',
    this.ticket = '',
    this.txnId = '',
    this.date = '',
    this.aid = '',
    this.appLabel = '',
    this.arqc = '',
    this.tvr = '',
  });

  bool get isApproved => respCode == '00';

  String get errorMessage =>
      _respCodeMessages[respCode] ?? 'Error desconocido ($respCode)';

  factory PaxResponse.fromJson(Map<String, dynamic> json) {
    return PaxResponse(
      respCode: json['RESPCODE']?.toString() ?? '',
      autorizacion: json['AUTORIZACION']?.toString() ?? '',
      stan: json['STAN']?.toString() ?? '',
      panMasked: json['PANMASKED']?.toString() ?? '',
      rrn: json['RRN']?.toString() ?? '',
      recibo: json['RECIBO']?.toString() ?? '',
      terminalId: json['TERMINALID']?.toString() ?? '',
      merchantId: json['MERCHANTID']?.toString() ?? '',
      cardHolder: json['CARDHOLDER']?.toString() ?? '',
      issuerName: json['ISSUERNAME']?.toString() ?? '',
      posEntryMode: json['POSENTRYMODE']?.toString() ?? '',
      cardHash: json['CARDHASH']?.toString() ?? '',
      totalAmount: json['TOTAL_AMOUNT']?.toString() ?? '',
      baseAmount: json['BASE_AMOUNT']?.toString() ?? '',
      tipAmount: json['TIP_AMOUNT']?.toString() ?? '',
      taxAmount: json['TAX_AMOUNT']?.toString() ?? '',
      ticket: json['TICKET']?.toString() ?? '',
      txnId: json['TxnId']?.toString() ?? '',
      date: json['DATE']?.toString() ?? '',
      aid: json['AID']?.toString() ?? '',
      appLabel: json['APP_LABEL']?.toString() ?? '',
      arqc: json['ARQC']?.toString() ?? '',
      tvr: json['TVR']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RESPCODE': respCode,
      'AUTORIZACION': autorizacion,
      'STAN': stan,
      'PANMASKED': panMasked,
      'RRN': rrn,
      'RECIBO': recibo,
      'TERMINALID': terminalId,
      'MERCHANTID': merchantId,
      'CARDHOLDER': cardHolder,
      'ISSUERNAME': issuerName,
      'POSENTRYMODE': posEntryMode,
      'CARDHASH': cardHash,
      'TOTAL_AMOUNT': totalAmount,
      'BASE_AMOUNT': baseAmount,
      'TIP_AMOUNT': tipAmount,
      'TAX_AMOUNT': taxAmount,
      'TICKET': ticket,
      'TxnId': txnId,
      'DATE': date,
      'AID': aid,
      'APP_LABEL': appLabel,
      'ARQC': arqc,
      'TVR': tvr,
    };
  }

  static const Map<String, String> _respCodeMessages = {
    '00': 'APROBADA',
    '01': 'CONSULTE VERBAL',
    '02': 'CONSULTE VERBAL',
    '03': 'COMERCIO INVALIDO',
    '04': 'CAPTURE TARJETA',
    '05': 'DENEGADA',
    '09': 'ACEPTADO',
    '12': 'TRANSACCION INVALIDA',
    '13': 'CANTIDAD INVALIDA',
    '14': 'TARJETA INVALIDA',
    '19': 'REINTENTE TRANSACCION',
    '21': 'SIN TRANSACCIONES',
    '25': 'REINTENTE',
    '41': 'RETENER TARJETA',
    '43': 'RETENER TARJETA',
    '51': 'DENEGADA FI',
    '54': 'TARJETA VENCIDA',
    '57': 'TRANSACCION NO PERMITIDA',
    '58': 'TRANSACCION NO PERMITIDA',
    '60': 'DENEGADA',
    '61': 'DENEGADA',
    '62': 'DENEGADA',
    '63': 'DENEGADA',
    '75': 'DENEGADA',
    '78': 'TRANSACCION NO ENCONTRADA',
    '79': 'LOTE YA ABIERTO',
    '80': 'ERROR EN NUMERO DE LOTE',
    '85': 'LOTE NO EXISTE',
    '89': 'TERMINAL INVALIDO',
    '94': 'TRANSACCION DUPLICADA',
    '95': 'ESPERE TRANSMISION',
    '96': 'ERROR EN SISTEMA',
    'NA': 'SISTEMA NO DISPONIBLE',
    'CE': 'ERROR DE COMUNICACION',
    'N7': 'CODIGO DE SEGURIDAD INVALIDO',
    'WE': 'ERROR INTERNO DEL WEB SERVICE',
    'X1': 'FONDOS INSUFICIENTES',
    'X4': 'NO ACEPTA ANULACION',
    'CONNECT TIMEOUT': 'EL POS NO TIENE CONEXION A RED',
  };
}
