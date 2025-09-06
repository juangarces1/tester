import 'package:json_annotation/json_annotation.dart';

part 'beachconfigdto.g.dart';

@JsonSerializable()
class BeachConfigDto {
  final int id;
  final String name;
  final bool active;
  final String? description; // Campo nuevo, opcional

  BeachConfigDto({
    required this.id,
    required this.name,
    required this.active,
    this.description,
  });

  factory BeachConfigDto.fromJson(Map<String, dynamic> json) =>
      _$BeachConfigDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BeachConfigDtoToJson(this);
}
