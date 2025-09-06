import 'package:json_annotation/json_annotation.dart';

part 'dispatchcreaterequest.g.dart';

@JsonSerializable()
class DispatchCreateRequest {
  final int nozzleNumber;
  final double volume;

  DispatchCreateRequest({
    required this.nozzleNumber,
    required this.volume,
  });

  factory DispatchCreateRequest.fromJson(Map<String, dynamic> json) => _$DispatchCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DispatchCreateRequestToJson(this);
}
