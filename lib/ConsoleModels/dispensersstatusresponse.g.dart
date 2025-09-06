// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispensersstatusresponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispenserHose _$DispenserHoseFromJson(Map<String, dynamic> json) =>
    DispenserHose(
      number: (json['number'] as num).toInt(),
      key: json['key'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      totalVolume: json['totalVolume'] as num,
      totalAmount: json['totalAmount'] as num,
    );

Map<String, dynamic> _$DispenserHoseToJson(DispenserHose instance) =>
    <String, dynamic>{
      'number': instance.number,
      'key': instance.key,
      'status': instance.status,
      'description': instance.description,
      'totalVolume': instance.totalVolume,
      'totalAmount': instance.totalAmount,
    };

DispenserStatus _$DispenserStatusFromJson(Map<String, dynamic> json) =>
    DispenserStatus(
      number: (json['number'] as num).toInt(),
      key: json['key'] as String,
      description: json['description'] as String,
      status:  json['status'] as String,
      activeHose: json['activeHose'] as String,
      hoses: (json['hoses'] as List<dynamic>)
          .map((e) => DispenserHose.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DispenserStatusToJson(DispenserStatus instance) =>
    <String, dynamic>{
      'number': instance.number,
      'key': instance.key,
      'description': instance.description,
      'status': instance.status,
      'activeHose': instance.activeHose,
      'hoses': instance.hoses,
    };

DispensersStatusResponse _$DispensersStatusResponseFromJson(
        Map<String, dynamic> json) =>
    DispensersStatusResponse(
      dispensers: (json['dispensers'] as List<dynamic>)
          .map((e) => DispenserStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DispensersStatusResponseToJson(
        DispensersStatusResponse instance) =>
    <String, dynamic>{
      'dispensers': instance.dispensers,
    };
