import 'package:json_annotation/json_annotation.dart';

part 'beach_config_models.g.dart';

// Modelo principal de configuración de playa
@JsonSerializable()
class BeachConfigDto {
  final int id;
  final String name;
  final bool active;

  BeachConfigDto({
    required this.id,
    required this.name,
    required this.active,
  });

  factory BeachConfigDto.fromJson(Map<String, dynamic> json) =>
      _$BeachConfigDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BeachConfigDtoToJson(this);
}

// Modelo para paginación simple (puedes expandirlo según tu paginador real)
@JsonSerializable()
class Pagination {
  final int page;
  final int pageSize;
  final int total;

  Pagination({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}

// Modelo para respuesta paginada de configuraciones de playa
@JsonSerializable()
class BeachConfigListResponse {
  final List<BeachConfigDto> data;
  final Pagination? pagination;

  BeachConfigListResponse({
    required this.data,
    this.pagination,
  });

  factory BeachConfigListResponse.fromJson(Map<String, dynamic> json) =>
      _$BeachConfigListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BeachConfigListResponseToJson(this);
}

// Modelo para crear/actualizar (sin id)
@JsonSerializable()
class BeachConfigUpsertRequest {
  final String name;
  final bool active;

  BeachConfigUpsertRequest({
    required this.name,
    required this.active,
  });

  factory BeachConfigUpsertRequest.fromJson(Map<String, dynamic> json) =>
      _$BeachConfigUpsertRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BeachConfigUpsertRequestToJson(this);
}

// Modelo para respuesta simple tipo { "data": true }
@JsonSerializable()
class BoolApiResponse {
  final bool data;
  BoolApiResponse({required this.data});

  factory BoolApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BoolApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BoolApiResponseToJson(this);
}

// Modelo tipo LinkType
@JsonSerializable()
class LinkType {
  final int id;
  final String name;

  LinkType({
    required this.id,
    required this.name,
  });

  factory LinkType.fromJson(Map<String, dynamic> json) =>
      _$LinkTypeFromJson(json);
  Map<String, dynamic> toJson() => _$LinkTypeToJson(this);
}

@JsonSerializable()
class LinkTypeListResponse {
  final List<LinkType> data;
  final Pagination? pagination;

  LinkTypeListResponse({
    required this.data,
    this.pagination,
  });

  factory LinkTypeListResponse.fromJson(Map<String, dynamic> json) =>
      _$LinkTypeListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LinkTypeListResponseToJson(this);
}

// Modelo para usuarios de playa
@JsonSerializable()
class BeachUserAssignRequest {
  final String userId;
  BeachUserAssignRequest({required this.userId});

  factory BeachUserAssignRequest.fromJson(Map<String, dynamic> json) =>
      _$BeachUserAssignRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BeachUserAssignRequestToJson(this);
}

// Modelo para lista por usuario (respuesta)
@JsonSerializable()
class BeachConfigSimpleListResponse {
  final List<BeachConfigDto> data;

  BeachConfigSimpleListResponse({required this.data});

  factory BeachConfigSimpleListResponse.fromJson(Map<String, dynamic> json) =>
      _$BeachConfigSimpleListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BeachConfigSimpleListResponseToJson(this);
}
