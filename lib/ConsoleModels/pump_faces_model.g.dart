// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pump_faces_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PumpFacesResponse _$PumpFacesResponseFromJson(Map<String, dynamic> json) =>
    PumpFacesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => PumpData.fromJson(e as Map<String, dynamic>))
          .toList(),
      ok: json['ok'] as bool,
      count: (json['count'] as num).toInt(),
      pageCount: (json['pageCount'] as num).toInt(),
      pageIndex: (json['pageIndex'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      filteredCount: (json['filteredCount'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
    );

Map<String, dynamic> _$PumpFacesResponseToJson(PumpFacesResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'ok': instance.ok,
      'count': instance.count,
      'pageCount': instance.pageCount,
      'pageIndex': instance.pageIndex,
      'pageSize': instance.pageSize,
      'filteredCount': instance.filteredCount,
      'totalCount': instance.totalCount,
    };

PumpData _$PumpDataFromJson(Map<String, dynamic> json) => PumpData(
      id: (json['id'] as num).toInt(),
      pumpName: json['pumpName'] as String,
      description: json['description'] as String,
      companyId: (json['companyId'] as num).toInt(),
      company: json['company'] as String,
      numberOfFaces: (json['numberOfFaces'] as num).toInt(),
      dispensers: (json['dispensers'] as List<dynamic>)
          .map((e) => DispenserFace.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PumpDataToJson(PumpData instance) => <String, dynamic>{
      'id': instance.id,
      'pumpName': instance.pumpName,
      'description': instance.description,
      'companyId': instance.companyId,
      'company': instance.company,
      'numberOfFaces': instance.numberOfFaces,
      'dispensers': instance.dispensers,
    };

DispenserFace _$DispenserFaceFromJson(Map<String, dynamic> json) =>
    DispenserFace(
      id: json['id'] as String,
      description: json['description'] as String,
      numberOfFace: (json['numberOfFace'] as num).toInt(),
    );

Map<String, dynamic> _$DispenserFaceToJson(DispenserFace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'numberOfFace': instance.numberOfFace,
    };
