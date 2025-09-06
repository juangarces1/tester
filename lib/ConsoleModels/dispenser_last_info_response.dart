import 'package:json_annotation/json_annotation.dart';
part 'dispenser_last_info_response.g.dart';

@JsonSerializable()
class DispenserLastInfoResponse {
  final double lastSaleAmount;
  final double lastSalePPU;
  final int lastSaleStatus;
  final String lastSaleId;
  final int lastSaleNumber;
  final double lastSaleVolume;
  final int lastSaleProduct;
  final double lastSaleAmountTotal;
  final double lastSaleVolumeTotal;
  final String lastSaleGeneralId;
  final String lastSaleAttendandId;

  DispenserLastInfoResponse({
    required this.lastSaleAmount,
    required this.lastSalePPU,
    required this.lastSaleStatus,
    required this.lastSaleId,
    required this.lastSaleNumber,
    required this.lastSaleVolume,
    required this.lastSaleProduct,
    required this.lastSaleAmountTotal,
    required this.lastSaleVolumeTotal,
    required this.lastSaleGeneralId,
    required this.lastSaleAttendandId,
  });

  factory DispenserLastInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$DispenserLastInfoResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DispenserLastInfoResponseToJson(this);
}
