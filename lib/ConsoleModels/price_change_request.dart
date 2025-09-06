import 'package:json_annotation/json_annotation.dart';
part 'price_change_request.g.dart';

@JsonSerializable()
class PriceChangeRequest {
  final int nozzleNumber;
  final double amount;
  final int level;

  PriceChangeRequest({
    required this.nozzleNumber,
    required this.amount,
    required this.level,
  });

  factory PriceChangeRequest.fromJson(Map<String, dynamic> json) =>
      _$PriceChangeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PriceChangeRequestToJson(this);
}
