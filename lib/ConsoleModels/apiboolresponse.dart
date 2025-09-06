import 'package:json_annotation/json_annotation.dart';

part 'apiboolresponse.g.dart';

@JsonSerializable()
class ApiBoolResponse {
  final bool data;

  ApiBoolResponse({required this.data});

  factory ApiBoolResponse.fromJson(Map<String, dynamic> json) => _$ApiBoolResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiBoolResponseToJson(this);
}
