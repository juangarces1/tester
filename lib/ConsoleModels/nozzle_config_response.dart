import 'package:json_annotation/json_annotation.dart';
part 'nozzle_config_response.g.dart';

@JsonSerializable()
class NozzleConfigResponse {
  final int nozzleNumber;
  final String config;

  NozzleConfigResponse({
    required this.nozzleNumber,
    required this.config,
  });

  factory NozzleConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$NozzleConfigResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleConfigResponseToJson(this);
}
