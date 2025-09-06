import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
part 'dispensersstatusresponse.g.dart';

@JsonSerializable()
class DispenserHose {
  final int number;
  final String key;
  final String status;       //  <-- Aqui esta el estado de la manguera que nos importa
  final String description;
  final num totalVolume;     //  <-- opcional, si lo usas
  final num totalAmount;     //  <-- opcional, si lo usas

  DispenserHose({
    required this.number,
    required this.key,
    required this.status,
    required this.description,
    required this.totalVolume,
    required this.totalAmount,
  });

  
  String get fuelType {
    final d = description.toLowerCase();
    if (d.contains('regular')) return 'Regular';
    if (d.contains('diesel') || d.contains('diésel')) return 'Diesel';
    if (d.contains('exonerado')) return 'Exonerado';
    return 'Super';
  }

  /// Color asociado al tipo de combustible.
  /// Regular -> rojo, Diesel -> verde, Exonerado -> azul, Super -> morado.
  Color get fuelColor {
    switch (fuelType) {
      case 'Regular':
        return const Color(0xFFec1c24); // rojo
      case 'Diesel':
        return const Color(0xFF1dbd4a); // verde
      case 'Exonerado':
        return const Color(0xFF0078D4); // azul
      default: // Super
        return const Color(0xFFb634b8); // morado
    }
  }

  factory DispenserHose.fromJson(Map<String, dynamic> json) =>
      _$DispenserHoseFromJson(json);
  Map<String, dynamic> toJson() => _$DispenserHoseToJson(this);
}

@JsonSerializable()
class DispenserStatus {
  final int number;
  final String key;
  final String description;
  final String status;
  final String activeHose;
  final List<DispenserHose> hoses;

  DispenserStatus({
    required this.number,
    required this.key,
    required this.description,
    required this.status,
    required this.activeHose,
    required this.hoses,
  });

    String get fuelType {
    final d = description.toLowerCase();
    if (d.contains('regular')) return 'Regular';
    if (d.contains('diesel') || d.contains('diésel')) return 'Diesel';
    if (d.contains('exonerado')) return 'Exonerado';
    return 'Super';
  }

  /// Color asociado al tipo de combustible.
  /// Regular -> rojo, Diesel -> verde, Exonerado -> azul, Super -> morado.
  Color get fuelColor {
    switch (fuelType) {
      case 'Regular':
        return const Color(0xFFec1c24); // rojo
      case 'Diesel':
        return const Color(0xFF1dbd4a); // verde
      case 'Exonerado':
        return const Color(0xFF0078D4); // azul
      default: // Super
        return const Color(0xFFb634b8); // morado
    }
  }

  factory DispenserStatus.fromJson(Map<String, dynamic> json) =>
      _$DispenserStatusFromJson(json);
  Map<String, dynamic> toJson() => _$DispenserStatusToJson(this);
}

@JsonSerializable()
class DispensersStatusResponse {
  final List<DispenserStatus> dispensers;

  DispensersStatusResponse({required this.dispensers});

  factory DispensersStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$DispensersStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DispensersStatusResponseToJson(this);
}
