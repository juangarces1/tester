// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beach_config_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeachConfigDto _$BeachConfigDtoFromJson(Map<String, dynamic> json) =>
    BeachConfigDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$BeachConfigDtoToJson(BeachConfigDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'active': instance.active,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'total': instance.total,
    };

BeachConfigListResponse _$BeachConfigListResponseFromJson(
        Map<String, dynamic> json) =>
    BeachConfigListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => BeachConfigDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BeachConfigListResponseToJson(
        BeachConfigListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'pagination': instance.pagination,
    };

BeachConfigUpsertRequest _$BeachConfigUpsertRequestFromJson(
        Map<String, dynamic> json) =>
    BeachConfigUpsertRequest(
      name: json['name'] as String,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$BeachConfigUpsertRequestToJson(
        BeachConfigUpsertRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'active': instance.active,
    };

BoolApiResponse _$BoolApiResponseFromJson(Map<String, dynamic> json) =>
    BoolApiResponse(
      data: json['data'] as bool,
    );

Map<String, dynamic> _$BoolApiResponseToJson(BoolApiResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

LinkType _$LinkTypeFromJson(Map<String, dynamic> json) => LinkType(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$LinkTypeToJson(LinkType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

LinkTypeListResponse _$LinkTypeListResponseFromJson(
        Map<String, dynamic> json) =>
    LinkTypeListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => LinkType.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LinkTypeListResponseToJson(
        LinkTypeListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'pagination': instance.pagination,
    };

BeachUserAssignRequest _$BeachUserAssignRequestFromJson(
        Map<String, dynamic> json) =>
    BeachUserAssignRequest(
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$BeachUserAssignRequestToJson(
        BeachUserAssignRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
    };

BeachConfigSimpleListResponse _$BeachConfigSimpleListResponseFromJson(
        Map<String, dynamic> json) =>
    BeachConfigSimpleListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => BeachConfigDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BeachConfigSimpleListResponseToJson(
        BeachConfigSimpleListResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
    };
