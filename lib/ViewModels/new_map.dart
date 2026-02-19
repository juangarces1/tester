import 'package:flutter/material.dart';
// Asumo que estos imports existen en tu proyecto:
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';
import 'package:tester/ConsoleModels/pump_faces_model.dart';
import 'package:tester/Models/FuelRed/nozzle_mapping.dart';

// ----------------------------- MODELOS ----------------------------------
class Fuel {
  final String name;
  final Color color;
  const Fuel({required this.name, required this.color});
}

class HosePhysical {
  final int nozzleNumber;
  final String hoseKey;
  final Fuel fuel;
  final String status;
  final String? facePosition;
  final String? fullAddress;
  final int? dispenserNumber;
  final String? dispenserKey;
  final int? fuelCode;
  final int? tankNumber;
  final int? pumpType;
  final num? unitPriceCash;
  final num? unitPriceCredit;
  final num? unitPriceDebit;
  final int? unitPriceDecimalPlaces;
  final int? totalFieldDecimalPlaces;
  final int? volumeFieldDecimalPlaces;
  final num? totalVolume;
  final num? totalAmount;
  final String? tagId;

  const HosePhysical({
    required this.nozzleNumber,
    required this.hoseKey,
    required this.fuel,
    required this.status,
    this.facePosition,
    this.fullAddress,
    this.dispenserNumber,
    this.dispenserKey,
    this.fuelCode,
    this.tankNumber,
    this.pumpType,
    this.unitPriceCash,
    this.unitPriceCredit,
    this.unitPriceDebit,
    this.unitPriceDecimalPlaces,
    this.totalFieldDecimalPlaces,
    this.volumeFieldDecimalPlaces,
    this.totalVolume,
    this.totalAmount,
    this.tagId,
  });
}

class PositionPhysical {
  final int number; // Indice global 1..N
  final int pumpId;
  final String pumpName;
  final int faceIndex;
  final String faceLabel;
  final String faceDescription;
  final List<HosePhysical> hoses;

  const PositionPhysical({
    required this.number,
    required this.pumpId,
    required this.pumpName,
    required this.faceIndex,
    required this.faceLabel,
    required this.faceDescription,
    required this.hoses,
  });
}

// -----------------------------  BUILDER CORREGIDO ---------------------------------
class PositionBuilder {
  static Map<int, PositionPhysical> build({
    required List<PumpData> pumps,
    required List<DispenserStatus> statuses,
    required List<NozzleMapping> mappings,
    bool strictPhysicalOnly = false,
  }) {
    final pumpById = {for (final pump in pumps) pump.id: pump};

    // 1. Mapeo de estados para búsqueda rápida
    final statusByNozzle = <int, _StatusContext>{};
    final statusByKey = <String, _StatusContext>{};
    final statusByDescription = <String, _StatusContext>{};

    for (final status in statuses) {
      for (final hose in status.hoses) {
        final ctx = _StatusContext(status, hose);
        statusByNozzle[hose.number] = ctx;
        statusByKey[hose.key] = ctx;

        final descKey = hose.description.trim().toLowerCase();
        if (descKey.isNotEmpty && !statusByDescription.containsKey(descKey)) {
          statusByDescription[descKey] = ctx;
        }
      }
    }

    final assignedKeys =
        <String>{}; // Para rastrear qué mangueras ya procesamos

    // CAMBIO IMPORTANTE: Agrupamos por ID de Surtidor (pumpId), no por dirección de manguera
    final groupsByPumpId = <int, _PositionGroup>{};

    // 2. Procesar Configuración (mapping de mangueras)
    for (final mapping in mappings) {
      // Determinamos el ID del surtidor
      final pumpId = mapping.dispenserNumber; // viene directo del mapping

      // Determinamos el nombre
      final pumpName = pumpById[pumpId]?.pumpName ?? 'Surtidor $pumpId';

      // Obtenemos o creamos el grupo para este SURTIDOR
      final group = groupsByPumpId.putIfAbsent(
        pumpId,
        () => _PositionGroup(
          pumpId: pumpId,
          pumpName: pumpName,
          // Usamos un índice base, puede refinarse si quieres separar caras A/B
          faceIndex: 1,
        ),
      );

      // Agregamos metadata al grupo (etiquetas, descripciones)
      group.faceData.addLabel(mapping.hoseKey);
      if (group.faceData.description == null && mapping.hoseKey.isNotEmpty) {
        // Podríamos usar una descripción genérica del surtidor
        group.faceData.description = pumpName;
      }

      // Busamos el estado correspondiente
      final statusCtx = _pickStatusFor(
        nozzleNumber: mapping.hoseNumber,
        hoseKey: mapping.hoseKey,
        description: mapping.hoseKey,
        byNozzle: statusByNozzle,
        byKey: statusByKey,
        byDescription: statusByDescription,
        assignedKeys: assignedKeys,
      );

      // Construimos la manguera
      final hose = _buildHose(
        pumpId: group.pumpId,
        nozzleNumber: mapping.hoseNumber,
        statusCtx: statusCtx,
        mapping: mapping,
        fallbackKey: mapping.hoseKey,
      );

      if (hose != null) {
        group.faceData.hoses.add(hose);
        if (statusCtx != null) {
          assignedKeys.add(statusCtx.hose.key);
        }
      }
    }

    // 3. Generar resultado final de grupos configurados
    final result = <int, PositionPhysical>{};
    var posCounter = 1;

    // Ordenamos por ID de surtidor
    final sortedPumpIds = groupsByPumpId.keys.toList()..sort();

    for (final pumpId in sortedPumpIds) {
      final group = groupsByPumpId[pumpId]!;

      if (group.faceData.hoses.isEmpty) continue;

      // Ordenamos las mangueras internamente por número
      group.faceData.hoses
          .sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

      final faceLabel =
          _resolveFaceLabel(group.faceData, group.faceData.faceIndex);
      // Descripción limpia
      final description = group.pumpName;

      result[posCounter] = PositionPhysical(
        number: posCounter,
        pumpId: group.pumpId,
        pumpName: group.pumpName,
        faceIndex: group.faceData.faceIndex,
        faceLabel: faceLabel,
        faceDescription: description,
        hoses: List.unmodifiable(group.faceData.hoses),
      );
      posCounter++;
    }

    // 4. Fallback (si strictPhysicalOnly es false): Mangueras en estado pero sin config
    if (!strictPhysicalOnly) {
      final fallbackGroups = <int, _FallbackGroup>{};

      for (final status in statuses) {
        for (final hose in status.hoses) {
          if (assignedKeys.contains(hose.key)) continue; // Ya fue asignada

          final ctx = _StatusContext(status, hose);
          // Intentamos adivinar a qué surtidor pertenece (por el dispenser number del status)
          final pumpId = status.number;

          final pumpName = pumpById[pumpId]?.pumpName ??
              (status.description.isNotEmpty
                  ? status.description
                  : 'Surtidor $pumpId');

          final group = fallbackGroups.putIfAbsent(
            pumpId,
            () => _FallbackGroup(
              pumpId: pumpId,
              pumpName: pumpName,
              faceIndex: 1,
            ),
          );

          group.faceData.description ??= status.description;

          final hosePhysical = _buildHose(
            pumpId: pumpId,
            nozzleNumber: hose.number,
            statusCtx: ctx,
            mapping: null, // null probablemente
            fallbackKey: hose.key,
          );

          if (hosePhysical != null) {
            group.faceData.hoses.add(hosePhysical);
            assignedKeys.add(hose.key);
          }
        }
      }

      // Procesar fallback groups
      final sortedFallbackIds = fallbackGroups.keys.toList()..sort();
      for (final pid in sortedFallbackIds) {
        final group = fallbackGroups[pid]!;
        if (group.faceData.hoses.isEmpty) continue;

        group.faceData.hoses
            .sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

        result[posCounter] = PositionPhysical(
          number: posCounter,
          pumpId: group.pumpId,
          pumpName: group.pumpName,
          faceIndex: group.faceData.faceIndex,
          faceLabel: "?",
          faceDescription: group.faceData.description ?? group.pumpName,
          hoses: List.unmodifiable(group.faceData.hoses),
        );
        posCounter++;
      }
    }

    return result;
  }

  // --- HELPERS ---

  static _StatusContext? _pickStatusFor({
    int? nozzleNumber,
    String? hoseKey,
    String? description,
    required Map<int, _StatusContext> byNozzle,
    required Map<String, _StatusContext> byKey,
    required Map<String, _StatusContext> byDescription,
    required Set<String> assignedKeys,
  }) {
    if (nozzleNumber != null) {
      final ctx = byNozzle[nozzleNumber];
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) return ctx;
    }
    if (hoseKey != null && hoseKey.isNotEmpty) {
      final ctx = byKey[hoseKey];
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) return ctx;
    }
    final descKey = description?.trim().toLowerCase() ?? '';
    if (descKey.isNotEmpty) {
      final ctx = byDescription[descKey];
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) return ctx;
    }
    return null;
  }

  static HosePhysical? _buildHose({
    required int pumpId,
    required int? nozzleNumber,
    required _StatusContext? statusCtx,
    required NozzleMapping? mapping,
    required String fallbackKey,
  }) {
    final resolvedNozzle =
        mapping?.hoseNumber ?? statusCtx?.hose.number ?? nozzleNumber;
    if (resolvedNozzle == null || resolvedNozzle <= 0) return null;

    final hoseKey = statusCtx?.hose.key ??
        (mapping?.hoseKey.isNotEmpty == true
            ? mapping!.hoseKey
            : (fallbackKey.isNotEmpty
                ? fallbackKey
                : 'P$pumpId-H$resolvedNozzle'));

    final hoseStatus =
        statusCtx?.hose.status ?? statusCtx?.dispenser.status ?? 'unknown';

    final fuel = _fuelFrom(hose: statusCtx?.hose);
    // Preferimos el dispensador proveniente del mapping porque ya trae la asociaci\u00f3n bomba/manguera.
    final dispenserNumber =
        mapping?.dispenserNumber ?? statusCtx?.dispenser.number ?? pumpId;

    return HosePhysical(
      nozzleNumber: resolvedNozzle,
      hoseKey: hoseKey,
      fuel: fuel,
      status: hoseStatus,
      facePosition: null,
      fullAddress: mapping?.hoseKey,
      dispenserNumber: dispenserNumber,
      dispenserKey: statusCtx?.dispenser.key,
      fuelCode: null,
      tankNumber: null,
      pumpType: null,
      unitPriceCash: null,
      unitPriceCredit: null,
      unitPriceDebit: null,
      unitPriceDecimalPlaces: null,
      totalFieldDecimalPlaces: null,
      volumeFieldDecimalPlaces: null,
      totalVolume: statusCtx?.hose.totalVolume,
      totalAmount: statusCtx?.hose.totalAmount,
    );
  }

  static Fuel _fuelFrom({
    DispenserHose? hose,
  }) {
    if (hose != null) {
      // CORRECCIÓN: Limpieza del string "Manguera 1 Super" -> "Super"
      String cleanName = hose.fuelType;
      // Regex: Busca "Manguera", espacio, dígitos, espacio y lo reemplaza por vacío
      cleanName = cleanName.replaceAll(RegExp(r'Manguera \d+ '), '').trim();
      // Si por alguna razón la regex borró todo o no coincidió pero queremos limpiar "Manguera "
      if (cleanName.startsWith("Manguera") && cleanName.split(' ').length > 2) {
        // Fallback manual si el regex falla en algún caso borde
        cleanName = cleanName.split(' ').sublist(2).join(' ');
      }

      return Fuel(name: cleanName, color: hose.fuelColor);
    }

    return const Fuel(name: 'Desconocido', color: Colors.grey);
  }

  /// NUEVO: Construye el mapa vinculando directamente NozzleMapping con DispenserStatus.
  /// Simplifica la lógica al no requerir datos físicos (pumps).
  static Map<int, PositionPhysical> buildDirect({
    required List<DispenserStatus> statuses,
    required List<NozzleMapping> mappings,
  }) {
    // 1. Mapeo de estados por número de manguera (nozzleNumber)
    final statusByNozzle = <int, DispenserHose>{};
    for (final status in statuses) {
      for (final hose in status.hoses) {
        statusByNozzle[hose.number] = hose;
      }
    }

    // 2. Agrupamiento por número de dispensador definido en los mappings
    final groupsByDispenser = <int, List<HosePhysical>>{};

    for (final mapping in mappings) {
      final nozzleNum = mapping.hoseNumber;
      final dispenserNum = mapping.dispenserNumber;

      // Buscamos el estado dinámico (si existe)
      final hoseStat = statusByNozzle[nozzleNum];

      final hose = HosePhysical(
        nozzleNumber: nozzleNum,
        hoseKey: mapping.hoseKey,
        fuel: _fuelFrom(hose: hoseStat),
        status: hoseStat?.status ?? 'unknown',
        dispenserNumber: dispenserNum,
        totalVolume: hoseStat?.totalVolume,
        totalAmount: hoseStat?.totalAmount,
      );

      groupsByDispenser.putIfAbsent(dispenserNum, () => []).add(hose);
    }

    // 3. Generación de posiciones físicas finales
    final result = <int, PositionPhysical>{};
    var posCounter = 1;

    // Ordenar los dispensadores por su número
    final sortedDispenserIds = groupsByDispenser.keys.toList()..sort();

    for (final dId in sortedDispenserIds) {
      final hoses = groupsByDispenser[dId]!;
      // Ordenar mangueras internamente por número
      hoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

      result[posCounter] = PositionPhysical(
        number: posCounter,
        pumpId: dId,
        pumpName: 'Surtidor $dId', // Requerido por el usuario
        faceIndex: 1, // Valor por defecto
        faceLabel: dId.toString(),
        faceDescription: 'Surtidor $dId',
        hoses: List.unmodifiable(hoses),
      );
      posCounter++;
    }

    return result;
  }
}

// ----------------------------- CLASES AUXILIARES INTERNAS ----------------------------------

class _StatusContext {
  final DispenserStatus dispenser;
  final DispenserHose hose;
  const _StatusContext(this.dispenser, this.hose);
}

class _FaceData {
  final int faceIndex;
  String? description;
  final List<String> labelCandidates = <String>[];
  final List<HosePhysical> hoses = <HosePhysical>[];

  _FaceData(this.faceIndex);

  void addLabel(String? candidate) {
    final normalized = _normalizeLabel(candidate);
    if (normalized.isEmpty) return;
    if (!labelCandidates.contains(normalized)) {
      labelCandidates.add(normalized);
    }
  }
}

// Agrupamos simplemente por ID de surtidor
class _PositionGroup {
  final int pumpId;
  final String pumpName;
  final _FaceData faceData;

  _PositionGroup({
    required this.pumpId,
    required this.pumpName,
    required int faceIndex,
  }) : faceData = _FaceData(faceIndex);
}

class _FallbackGroup {
  final int pumpId;
  final String pumpName;
  final _FaceData faceData;

  _FallbackGroup({
    required this.pumpId,
    required this.pumpName,
    required int faceIndex,
  }) : faceData = _FaceData(faceIndex);
}

// ----------------------------- UTILIDADES ----------------------------------

String _resolveFaceLabel(_FaceData data, int faceIndex) {
  if (data.labelCandidates.isNotEmpty) {
    return data.labelCandidates.first;
  }
  return faceIndex.toString();
}

String _normalizeLabel(String? value) {
  if (value == null) return '';
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.toUpperCase();
}
