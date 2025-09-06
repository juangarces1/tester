// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dispatch _$DispatchFromJson(Map<String, dynamic> json) => Dispatch(
      id: (json['id'] as num).toInt(),
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$DispatchToJson(Dispatch instance) => <String, dynamic>{
      'id': instance.id,
      'nozzleNumber': instance.nozzleNumber,
      'volume': instance.volume,
    };
