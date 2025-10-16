class DetailTransfer {
  int? id;
  String? fecha;
  int? monto;
  int? cierre;
  String? pistero;

  DetailTransfer({this.id, this.fecha, this.monto, this.cierre, this.pistero});

  factory DetailTransfer.fromJson(Map<String, dynamic> json) => DetailTransfer(
        id: json['id'] as int?,
        fecha: json['fecha'] as String?,
        monto: json['monto'] as int?,
        cierre: json['cierre'] as int?,
        pistero: json['pistero'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'monto': monto,
        'cierre': cierre,
        'pistero': pistero,
      };
}
