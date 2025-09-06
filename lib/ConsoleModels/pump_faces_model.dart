import 'package:json_annotation/json_annotation.dart';

part 'pump_faces_model.g.dart';

@JsonSerializable()
class PumpFacesResponse {
  final List<PumpData> data;
  final bool ok;
  final int count;
  final int pageCount;
  final int pageIndex;
  final int pageSize;
  final int filteredCount;
  final int totalCount;

  PumpFacesResponse({
    required this.data,
    required this.ok,
    required this.count,
    required this.pageCount,
    required this.pageIndex,
    required this.pageSize,
    required this.filteredCount,
    required this.totalCount,
  });

  factory PumpFacesResponse.fromJson(Map<String, dynamic> json) =>
      _$PumpFacesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PumpFacesResponseToJson(this);
}

@JsonSerializable()
class PumpData {
  final int id;
  final String pumpName;
  final String description;
  final int companyId;
  final String company;
  final int numberOfFaces;
  final List<DispenserFace> dispensers;

  PumpData({
    required this.id,
    required this.pumpName,
    required this.description,
    required this.companyId,
    required this.company,
    required this.numberOfFaces,
    required this.dispensers,
  });

  factory PumpData.fromJson(Map<String, dynamic> json) =>
      _$PumpDataFromJson(json);

  Map<String, dynamic> toJson() => _$PumpDataToJson(this);
}

@JsonSerializable()
class DispenserFace {
  final String id; // Puede ser String o int, depende de la API real
  final String description;
  final int numberOfFace;

  DispenserFace({
    required this.id,
    required this.description,
    required this.numberOfFace,
  });

  factory DispenserFace.fromJson(Map<String, dynamic> json) =>
      _$DispenserFaceFromJson(json);

  Map<String, dynamic> toJson() => _$DispenserFaceToJson(this);
}
