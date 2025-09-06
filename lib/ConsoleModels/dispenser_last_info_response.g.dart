// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispenser_last_info_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispenserLastInfoResponse _$DispenserLastInfoResponseFromJson(
        Map<String, dynamic> json) =>
    DispenserLastInfoResponse(
      lastSaleAmount: (json['lastSaleAmount'] as num).toDouble(),
      lastSalePPU: (json['lastSalePPU'] as num).toDouble(),
      lastSaleStatus: (json['lastSaleStatus'] as num).toInt(),
      lastSaleId: json['lastSaleId'] as String,
      lastSaleNumber: (json['lastSaleNumber'] as num).toInt(),
      lastSaleVolume: (json['lastSaleVolume'] as num).toDouble(),
      lastSaleProduct: (json['lastSaleProduct'] as num).toInt(),
      lastSaleAmountTotal: (json['lastSaleAmountTotal'] as num).toDouble(),
      lastSaleVolumeTotal: (json['lastSaleVolumeTotal'] as num).toDouble(),
      lastSaleGeneralId: json['lastSaleGeneralId'] as String,
      lastSaleAttendandId: json['lastSaleAttendandId'] as String,
    );

Map<String, dynamic> _$DispenserLastInfoResponseToJson(
        DispenserLastInfoResponse instance) =>
    <String, dynamic>{
      'lastSaleAmount': instance.lastSaleAmount,
      'lastSalePPU': instance.lastSalePPU,
      'lastSaleStatus': instance.lastSaleStatus,
      'lastSaleId': instance.lastSaleId,
      'lastSaleNumber': instance.lastSaleNumber,
      'lastSaleVolume': instance.lastSaleVolume,
      'lastSaleProduct': instance.lastSaleProduct,
      'lastSaleAmountTotal': instance.lastSaleAmountTotal,
      'lastSaleVolumeTotal': instance.lastSaleVolumeTotal,
      'lastSaleGeneralId': instance.lastSaleGeneralId,
      'lastSaleAttendandId': instance.lastSaleAttendandId,
    };
