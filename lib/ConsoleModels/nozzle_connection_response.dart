import 'package:json_annotation/json_annotation.dart';
part 'nozzle_connection_response.g.dart';

@JsonSerializable()
class NozzleConnectionResponse {
  final int nozzleNumber;
  final bool connected;

  NozzleConnectionResponse({
    required this.nozzleNumber,
    required this.connected,
  });

  factory NozzleConnectionResponse.fromJson(Map<String, dynamic> json) =>
      _$NozzleConnectionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleConnectionResponseToJson(this);
}
