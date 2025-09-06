// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nozzle_connection_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NozzleConnectionResponse _$NozzleConnectionResponseFromJson(
        Map<String, dynamic> json) =>
    NozzleConnectionResponse(
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      connected: json['connected'] as bool,
    );

Map<String, dynamic> _$NozzleConnectionResponseToJson(
        NozzleConnectionResponse instance) =>
    <String, dynamic>{
      'nozzleNumber': instance.nozzleNumber,
      'connected': instance.connected,
    };
