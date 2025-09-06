// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currentdispatch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentDispatch _$CurrentDispatchFromJson(Map<String, dynamic> json) =>
    CurrentDispatch(
      id: (json['id'] as num).toInt(),
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      fuelCode: (json['fuelCode'] as num).toInt(),
      saleStatus: (json['saleStatus'] as num).toInt(),
      saleId: json['saleId'] as String,
    );

Map<String, dynamic> _$CurrentDispatchToJson(CurrentDispatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nozzleNumber': instance.nozzleNumber,
      'totalValue': instance.totalValue,
      'totalVolume': instance.totalVolume,
      'unitPrice': instance.unitPrice,
      'fuelCode': instance.fuelCode,
      'saleStatus': instance.saleStatus,
      'saleId': instance.saleId,
    };
