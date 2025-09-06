import 'package:json_annotation/json_annotation.dart';

part 'nozzle_info.g.dart';

@JsonSerializable()
class NozzleInfo {
  final int id;
  final int dispense;        // Número del dispensador físico
  final int icomPort;
  final String connector;
  final int address;
  final String position;     // "A", "B", "C"...
  final String fullAddress;
  final String dispenseAddress;
  final int nozzleNumber;
  final int tankNumber;
  final int fuelCode;
  final int pumpType;
  final num unitPriceCash;
  final num unitPriceCredit;
  final num unitPriceDebit;
  final int unitPriceDecimalPlaces;
  final int totalFieldDecimalPlaces;
  final int volumeFieldDecimalPlaces;

  NozzleInfo({
    required this.id,
    required this.dispense,
    required this.icomPort,
    required this.connector,
    required this.address,
    required this.position,
    required this.fullAddress,
    required this.dispenseAddress,
    required this.nozzleNumber,
    required this.tankNumber,
    required this.fuelCode,
    required this.pumpType,
    required this.unitPriceCash,
    required this.unitPriceCredit,
    required this.unitPriceDebit,
    required this.unitPriceDecimalPlaces,
    required this.totalFieldDecimalPlaces,
    required this.volumeFieldDecimalPlaces,
  });

  factory NozzleInfo.fromJson(Map<String, dynamic> json) => _$NozzleInfoFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleInfoToJson(this);
}

@JsonSerializable()
class NozzleApiResponse {
  final List<NozzleInfo> data;
  final bool ok;
  NozzleApiResponse({required this.data, required this.ok});

  factory NozzleApiResponse.fromJson(Map<String, dynamic> json) =>
      _$NozzleApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleApiResponseToJson(this);
}
