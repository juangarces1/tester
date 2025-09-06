import 'package:json_annotation/json_annotation.dart';

part 'api_list_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiListResponse<T> {
  final List<T> data;

  ApiListResponse({
    required this.data,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiListResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(
    Object Function(T value) toJsonT,
  ) =>
      _$ApiListResponseToJson(this, toJsonT);
}
