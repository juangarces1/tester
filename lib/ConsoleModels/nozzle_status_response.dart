import 'package:json_annotation/json_annotation.dart';
part 'nozzle_status_response.g.dart';

@JsonSerializable()
class NozzleStatus {
  final int nozzleNumber;
  final String status;

  NozzleStatus({
    required this.nozzleNumber,
    required this.status,
  });

  factory NozzleStatus.fromJson(Map<String, dynamic> json) => _$NozzleStatusFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleStatusToJson(this);
}

@JsonSerializable()
class NozzleStatusResponse {
  final List<NozzleStatus> statuses;

  NozzleStatusResponse({required this.statuses});

  factory NozzleStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$NozzleStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NozzleStatusResponseToJson(this);
}
