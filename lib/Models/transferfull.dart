

import 'package:tester/Models/detail_transfer.dart';

class TransferFull {
  int? id;
  String? cliente;
  String? cuenta;
  String? numeroDeposito;
  String? fecha;
  int? monto;
  List<DetailTransfer>? descuentos;

  TransferFull({this.id, this.cliente, this.cuenta, this.numeroDeposito, this.fecha, this.monto, this.descuentos});

  factory TransferFull.fromJson(Map<String, dynamic> json) => TransferFull(
        id: json['id'] as int?,
        cliente: json['cliente'] as String?,
        cuenta: json['cuenta'] as String?,
        numeroDeposito: json['numeroDeposito'] as String?,
        fecha: json['fecha'] as String?,
        monto: json['monto'] as int?,
        descuentos: (json['descuentos'] as List?)
            ?.map((e) => DetailTransfer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'cuenta': cuenta,
        'numeroDeposito': numeroDeposito,
        'fecha': fecha,
        'monto': monto,
        'descuentos': descuentos?.map((e) => e.toJson()).toList(),
      };

  int get saldo => descuentos == null || descuentos!.isEmpty ? monto ?? 0 : monto! - descuentos!.fold(0, (previousValue, element) => previousValue + (element.monto ?? 0));
}
