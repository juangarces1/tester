// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nozzle_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NozzleStatus _$NozzleStatusFromJson(Map<String, dynamic> json) => NozzleStatus(
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$NozzleStatusToJson(NozzleStatus instance) =>
    <String, dynamic>{
      'nozzleNumber': instance.nozzleNumber,
      'status': instance.status,
    };

NozzleStatusResponse _$NozzleStatusResponseFromJson(
        Map<String, dynamic> json) =>
    NozzleStatusResponse(
      statuses: (json['statuses'] as List<dynamic>)
          .map((e) => NozzleStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NozzleStatusResponseToJson(
        NozzleStatusResponse instance) =>
    <String, dynamic>{
      'statuses': instance.statuses,
    };
