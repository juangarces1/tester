// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nozzle_config_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NozzleConfigResponse _$NozzleConfigResponseFromJson(
        Map<String, dynamic> json) =>
    NozzleConfigResponse(
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      config: json['config'] as String,
    );

Map<String, dynamic> _$NozzleConfigResponseToJson(
        NozzleConfigResponse instance) =>
    <String, dynamic>{
      'nozzleNumber': instance.nozzleNumber,
      'config': instance.config,
    };
