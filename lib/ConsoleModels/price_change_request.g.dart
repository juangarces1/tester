// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_change_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceChangeRequest _$PriceChangeRequestFromJson(Map<String, dynamic> json) =>
    PriceChangeRequest(
      nozzleNumber: (json['nozzleNumber'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      level: (json['level'] as num).toInt(),
    );

Map<String, dynamic> _$PriceChangeRequestToJson(PriceChangeRequest instance) =>
    <String, dynamic>{
      'nozzleNumber': instance.nozzleNumber,
      'amount': instance.amount,
      'level': instance.level,
    };
