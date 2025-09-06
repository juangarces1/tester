import 'package:json_annotation/json_annotation.dart';
part 'currentdispatch.g.dart';

@JsonSerializable()
class CurrentDispatch {
  final int id;
  final int nozzleNumber;
  final double totalValue;
  final double totalVolume;
  final double unitPrice;
  final int fuelCode;
  final int saleStatus;
  final String saleId;

  CurrentDispatch({
    required this.id,
    required this.nozzleNumber,
    required this.totalValue,
    required this.totalVolume,
    required this.unitPrice,
    required this.fuelCode,
    required this.saleStatus,
    required this.saleId,
  });

  factory CurrentDispatch.fromJson(Map<String, dynamic> json) => _$CurrentDispatchFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentDispatchToJson(this);
}
