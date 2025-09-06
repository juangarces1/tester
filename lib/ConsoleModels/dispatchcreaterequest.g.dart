// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatchcreaterequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchCreateRequest _$DispatchCreateRequestFromJson(
        Map<String, dynamic> json) =>
    DispatchCreateRequest(
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$DispatchCreateRequestToJson(
        DispatchCreateRequest instance) =>
    <String, dynamic>{
      'nozzleNumber': instance.nozzleNumber,
      'volume': instance.volume,
    };
