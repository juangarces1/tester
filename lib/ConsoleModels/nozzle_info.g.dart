// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nozzle_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NozzleInfo _$NozzleInfoFromJson(Map<String, dynamic> json) => NozzleInfo(
      id: (json['id'] as num).toInt(),
      dispense: (json['dispense'] as num).toInt(),
      icomPort: (json['icomPort'] as num).toInt(),
      connector: json['connector'] as String,
      address: (json['address'] as num).toInt(),
      position: json['position'] as String,
      fullAddress: json['fullAddress'] as String,
      dispenseAddress: json['dispenseAddress'] as String,
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      tankNumber: (json['tankNumber'] as num).toInt(),
      fuelCode: (json['fuelCode'] as num).toInt(),
      pumpType: (json['pumpType'] as num).toInt(),
      unitPriceCash: json['unitPriceCash'] as num,
      unitPriceCredit: json['unitPriceCredit'] as num,
      unitPriceDebit: json['unitPriceDebit'] as num,
      unitPriceDecimalPlaces: (json['unitPriceDecimalPlaces'] as num).toInt(),
      totalFieldDecimalPlaces: (json['totalFieldDecimalPlaces'] as num).toInt(),
      volumeFieldDecimalPlaces:
          (json['volumeFieldDecimalPlaces'] as num).toInt(),
    );

Map<String, dynamic> _$NozzleInfoToJson(NozzleInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dispense': instance.dispense,
      'icomPort': instance.icomPort,
      'connector': instance.connector,
      'address': instance.address,
      'position': instance.position,
      'fullAddress': instance.fullAddress,
      'dispenseAddress': instance.dispenseAddress,
      'nozzleNumber': instance.nozzleNumber,
      'tankNumber': instance.tankNumber,
      'fuelCode': instance.fuelCode,
      'pumpType': instance.pumpType,
      'unitPriceCash': instance.unitPriceCash,
      'unitPriceCredit': instance.unitPriceCredit,
      'unitPriceDebit': instance.unitPriceDebit,
      'unitPriceDecimalPlaces': instance.unitPriceDecimalPlaces,
      'totalFieldDecimalPlaces': instance.totalFieldDecimalPlaces,
      'volumeFieldDecimalPlaces': instance.volumeFieldDecimalPlaces,
    };

NozzleApiResponse _$NozzleApiResponseFromJson(Map<String, dynamic> json) =>
    NozzleApiResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => NozzleInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      ok: json['ok'] as bool,
    );

Map<String, dynamic> _$NozzleApiResponseToJson(NozzleApiResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'ok': instance.ok,
    };
