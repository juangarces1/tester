// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beachconfigdto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeachConfigDto _$BeachConfigDtoFromJson(Map<String, dynamic> json) =>
    BeachConfigDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      active: json['active'] as bool,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BeachConfigDtoToJson(BeachConfigDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'active': instance.active,
      'description': instance.description,
    };
