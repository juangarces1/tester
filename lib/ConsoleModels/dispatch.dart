import 'package:json_annotation/json_annotation.dart';

part 'dispatch.g.dart';

@JsonSerializable()
class Dispatch {
  final int id;
  final int nozzleNumber;
  final double volume;

  Dispatch({
    required this.id,
    required this.nozzleNumber,
    required this.volume,
  });

  factory Dispatch.fromJson(Map<String, dynamic> json) => _$DispatchFromJson(json);
  Map<String, dynamic> toJson() => _$DispatchToJson(this);
}
