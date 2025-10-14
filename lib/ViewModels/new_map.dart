import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';
import 'package:tester/ConsoleModels/fuel_palette.dart' as fuel_palette;
import 'package:tester/ConsoleModels/nozzle_info.dart';
import 'package:tester/ConsoleModels/pump_faces_model.dart';

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
  final String status; // estado crudo del API (authorized, fueling, etc.)
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
  });
}

class PositionPhysical {
  final int number; // global index 1..N
  final int pumpId;
  final String pumpName;
  final int faceIndex;
  final String faceLabel; // etiqueta legible (A/B/1/2)
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

// -----------------------------  BUILDER  ---------------------------------
class PositionBuilder {
  static Map<int, PositionPhysical> build({
    required List<PumpData> pumps,
    required List<DispenserStatus> statuses,
    required List<NozzleInfo> nozzles,
    bool strictPhysicalOnly = false,
  }) {
    final pumpById = {for (final pump in pumps) pump.id: pump};

    final nozzleFaceIndexByPump = <int, Map<int, int>>{};
    final faceDescriptionsByPump = <int, Map<int, String>>{};
    final nozzleToPumpId = <int, int>{};

    for (final pump in pumps) {
      final faceIndexMap =
          nozzleFaceIndexByPump.putIfAbsent(pump.id, () => <int, int>{});
      final descMap =
          faceDescriptionsByPump.putIfAbsent(pump.id, () => <int, String>{});

      for (final face in pump.dispensers) {
        final nozzleNumber = int.tryParse(face.id.trim());
        if (nozzleNumber != null) {
          faceIndexMap[nozzleNumber] = face.numberOfFace;
          nozzleToPumpId[nozzleNumber] = pump.id;
        }

        final desc = face.description.trim();
        if (desc.isNotEmpty && !descMap.containsKey(face.numberOfFace)) {
          descMap[face.numberOfFace] = desc;
        }
      }
    }

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

    final nozzleByNumber = {
      for (final nozzle in nozzles) nozzle.nozzleNumber: nozzle
    };

    final nozzlesByPump = <int, List<NozzleInfo>>{};
    for (final nozzle in nozzles) {
      final pumpId = nozzleToPumpId[nozzle.nozzleNumber] ??
          _pumpIdFromAddress(nozzle.dispenseAddress) ??
          _pumpIdFromAddress(nozzle.fullAddress);
      if (pumpId == null) continue;
      nozzlesByPump.putIfAbsent(pumpId, () => <NozzleInfo>[]).add(nozzle);
    }

    final assignedKeys = <String>{};

    final result = <int, PositionPhysical>{};
    var posCounter = 1;
    final processedPumpIds = <int>{};

    for (final pump in pumps) {
      processedPumpIds.add(pump.id);
      final faceData = <int, _FaceData>{};
      final usedNozzles = <int>{};

      final pumpFaceDescriptions = faceDescriptionsByPump[pump.id] ?? const {};
      pumpFaceDescriptions.forEach((faceIndex, description) {
        final data = faceData.putIfAbsent(faceIndex, () => _FaceData(faceIndex));
        data.description ??= description;
      });

      for (final face in pump.dispensers) {
        final data =
            faceData.putIfAbsent(face.numberOfFace, () => _FaceData(face.numberOfFace));
        final desc = face.description.trim();
        if (desc.isNotEmpty && (data.description == null || data.description!.isEmpty)) {
          data.description = desc;
        }

        final nozzleNumber = int.tryParse(face.id.trim());
        final nozzleInfo = nozzleNumber != null ? nozzleByNumber[nozzleNumber] : null;
        final statusCtx = _pickStatusFor(
          nozzleNumber: nozzleNumber,
          hoseKey: face.id,
          description: face.description,
          byNozzle: statusByNozzle,
          byKey: statusByKey,
          byDescription: statusByDescription,
          assignedKeys: assignedKeys,
        );

        data.addLabel(nozzleInfo?.position);
        if (data.labelCandidates.isEmpty) {
          data.addLabel(_faceLabel(face.numberOfFace));
        }

        final hose = _buildHose(
          pumpId: pump.id,
          nozzleNumber: nozzleNumber,
          statusCtx: statusCtx,
          nozzle: nozzleInfo,
          fallbackKey: face.id,
        );
        if (hose != null) {
          data.hoses.add(hose);
          if (statusCtx != null) {
            assignedKeys.add(statusCtx.hose.key);
          }
          if (nozzleInfo != null) {
            usedNozzles.add(nozzleInfo.nozzleNumber);
          }
        }
      }

      final pumpNozzles = nozzlesByPump[pump.id] ?? const <NozzleInfo>[];
      for (final nozzle in pumpNozzles) {
        if (usedNozzles.contains(nozzle.nozzleNumber)) continue;

        final statusCtx = _pickStatusFor(
          nozzleNumber: nozzle.nozzleNumber,
          hoseKey: nozzle.fullAddress,
          description: nozzle.fullAddress,
          byNozzle: statusByNozzle,
          byKey: statusByKey,
          byDescription: statusByDescription,
          assignedKeys: assignedKeys,
        );

        final faceIndex =
            nozzleFaceIndexByPump[pump.id]?[nozzle.nozzleNumber] ??
                _indexFromPosition(nozzle.position) ??
                statusCtx?.dispenser.number ??
                _nextFaceIndex(faceData);

        final data = faceData.putIfAbsent(faceIndex, () => _FaceData(faceIndex));
        if ((data.description == null || data.description!.isEmpty) &&
            nozzle.fullAddress.trim().isNotEmpty) {
          data.description = nozzle.fullAddress;
        }
        data.addLabel(nozzle.position);

        final hose = _buildHose(
          pumpId: pump.id,
          nozzleNumber: nozzle.nozzleNumber,
          statusCtx: statusCtx,
          nozzle: nozzle,
          fallbackKey: nozzle.fullAddress,
        );
        if (hose != null) {
          data.hoses.add(hose);
          if (statusCtx != null) {
            assignedKeys.add(statusCtx.hose.key);
          }
        }
      }

      final sortedFaces = faceData.keys.toList()..sort();
      for (final faceIndex in sortedFaces) {
        final data = faceData[faceIndex]!;
        data.hoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
        final faceLabel = _resolveFaceLabel(data, faceIndex);
        final description = data.description?.trim().isNotEmpty == true
            ? data.description!.trim()
            : '${pump.pumpName} - Cara $faceLabel';

        result[posCounter] = PositionPhysical(
          number: posCounter,
          pumpId: pump.id,
          pumpName: pump.pumpName,
          faceIndex: faceIndex,
          faceLabel: faceLabel,
          faceDescription: description,
          hoses: List.unmodifiable(data.hoses),
        );
        posCounter++;
      }
    }

    for (final entry in nozzlesByPump.entries) {
      if (processedPumpIds.contains(entry.key)) continue;

      final pumpId = entry.key;
      final pumpName = pumpById[pumpId]?.pumpName ?? 'Surtidor $pumpId';
      final faceData = <int, _FaceData>{};

      for (final nozzle in entry.value) {
        final statusCtx = _pickStatusFor(
          nozzleNumber: nozzle.nozzleNumber,
          hoseKey: nozzle.fullAddress,
          description: nozzle.fullAddress,
          byNozzle: statusByNozzle,
          byKey: statusByKey,
          byDescription: statusByDescription,
          assignedKeys: assignedKeys,
        );

        int faceIndex = _indexFromPosition(nozzle.position) ??
            statusCtx?.dispenser.number ??
            nozzle.dispense;
        if (faceIndex <= 0) {
          faceIndex = _nextFaceIndex(faceData);
        }

        final data = faceData.putIfAbsent(faceIndex, () => _FaceData(faceIndex));
        if ((data.description == null || data.description!.isEmpty) &&
            nozzle.fullAddress.trim().isNotEmpty) {
          data.description = nozzle.fullAddress;
        }
        data.addLabel(nozzle.position);

        final hose = _buildHose(
          pumpId: pumpId,
          nozzleNumber: nozzle.nozzleNumber,
          statusCtx: statusCtx,
          nozzle: nozzle,
          fallbackKey: nozzle.fullAddress,
        );

        if (hose != null) {
          data.hoses.add(hose);
          if (statusCtx != null) {
            assignedKeys.add(statusCtx.hose.key);
          }
        }
      }

      final sortedFaces = faceData.keys.toList()..sort();
      for (final faceIndex in sortedFaces) {
        final data = faceData[faceIndex]!;
        if (data.hoses.isEmpty) continue;

        data.hoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
        final faceLabel = _resolveFaceLabel(data, faceIndex);
        final description = data.description?.trim().isNotEmpty == true
            ? data.description!.trim()
            : '$pumpName - Cara $faceLabel';

        result[posCounter] = PositionPhysical(
          number: posCounter,
          pumpId: pumpId,
          pumpName: pumpName,
          faceIndex: faceIndex,
          faceLabel: faceLabel,
          faceDescription: description,
          hoses: List.unmodifiable(data.hoses),
        );
        posCounter++;
      }
    }

    if (!strictPhysicalOnly) {
      final fallbackGroups = <String, _FallbackGroup>{};

      for (final status in statuses) {
        for (final hose in status.hoses) {
          if (assignedKeys.contains(hose.key)) continue;

          final ctx = _StatusContext(status, hose);
          final nozzle = nozzleByNumber[hose.number];
          final pumpId = nozzleToPumpId[hose.number] ??
              _pumpIdFromAddress(nozzle?.dispenseAddress) ??
              status.number;
          var faceIndex = nozzleFaceIndexByPump[pumpId]?[hose.number] ??
              _indexFromPosition(nozzle?.position) ??
              status.number;
          if (faceIndex <= 0) {
            faceIndex = 1;
          }

          final pumpName = pumpById[pumpId]?.pumpName ?? status.description;
          final faceLabel = nozzle?.position ?? _faceLabel(faceIndex);
          final groupKey = '$pumpId|$faceIndex|$faceLabel';

          final group = fallbackGroups.putIfAbsent(
            groupKey,
            () => _FallbackGroup(
              pumpId: pumpId,
              pumpName: pumpName,
              faceIndex: faceIndex,
            ),
          );

          group.faceData.addLabel(faceLabel);
          if ((group.faceData.description == null ||
                  group.faceData.description!.isEmpty) &&
              (nozzle?.fullAddress.trim().isNotEmpty ?? false)) {
            group.faceData.description = nozzle!.fullAddress;
          }
          group.faceData.description ??= status.description;

          final hosePhysical = _buildHose(
            pumpId: pumpId,
            nozzleNumber: hose.number,
            statusCtx: ctx,
            nozzle: nozzle,
            fallbackKey: hose.key,
          );

          if (hosePhysical != null) {
            group.faceData.hoses.add(hosePhysical);
            assignedKeys.add(hose.key);
          }
        }
      }

      for (final group in fallbackGroups.values) {
        if (group.faceData.hoses.isEmpty) continue;

        group.faceData.hoses
            .sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
        final faceLabel =
            _resolveFaceLabel(group.faceData, group.faceData.faceIndex);
        final description =
            group.faceData.description?.trim().isNotEmpty == true
                ? group.faceData.description!.trim()
                : '${group.pumpName} - Cara $faceLabel';

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
    }

    return result;
  }

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
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) {
        return ctx;
      }
    }

    if (hoseKey != null && hoseKey.isNotEmpty) {
      final ctx = byKey[hoseKey];
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) {
        return ctx;
      }
    }

    final descKey = description?.trim().toLowerCase() ?? '';
    if (descKey.isNotEmpty) {
      final ctx = byDescription[descKey];
      if (ctx != null && !assignedKeys.contains(ctx.hose.key)) {
        return ctx;
      }
    }

    return null;
  }

  static HosePhysical? _buildHose({
    required int pumpId,
    required int? nozzleNumber,
    required _StatusContext? statusCtx,
    required NozzleInfo? nozzle,
    required String fallbackKey,
  }) {
    final resolvedNozzle =
        nozzle?.nozzleNumber ?? statusCtx?.hose.number ?? nozzleNumber;
    if (resolvedNozzle == null || resolvedNozzle <= 0) {
      return null;
    }

    final hoseKey = statusCtx?.hose.key ??
        (nozzle != null
            ? _hoseKeyFromNozzle(nozzle.nozzleNumber)
            : (fallbackKey.isNotEmpty
                ? fallbackKey
                : 'P$pumpId-H$resolvedNozzle'));

    final hoseStatus =
        statusCtx?.hose.status ?? statusCtx?.dispenser.status ?? 'unknown';

    final fuel = _fuelFrom(nozzle: nozzle, hose: statusCtx?.hose);

    return HosePhysical(
      nozzleNumber: resolvedNozzle,
      hoseKey: hoseKey,
      fuel: fuel,
      status: hoseStatus,
      facePosition: nozzle?.position,
      fullAddress: nozzle?.fullAddress,
      dispenserNumber: statusCtx?.dispenser.number ?? nozzle?.dispense,
      dispenserKey: statusCtx?.dispenser.key,
      fuelCode: nozzle?.fuelCode,
      tankNumber: nozzle?.tankNumber,
      pumpType: nozzle?.pumpType,
      unitPriceCash: nozzle?.unitPriceCash,
      unitPriceCredit: nozzle?.unitPriceCredit,
      unitPriceDebit: nozzle?.unitPriceDebit,
      unitPriceDecimalPlaces: nozzle?.unitPriceDecimalPlaces,
      totalFieldDecimalPlaces: nozzle?.totalFieldDecimalPlaces,
      volumeFieldDecimalPlaces: nozzle?.volumeFieldDecimalPlaces,
      totalVolume: statusCtx?.hose.totalVolume,
      totalAmount: statusCtx?.hose.totalAmount,
    );
  }

  static Fuel _fuelFrom({
    NozzleInfo? nozzle,
    DispenserHose? hose,
  }) {
    if (nozzle != null) {
      final catalogHit = fuel_palette.kFuelCatalog.containsKey(nozzle.fuelCode);
      final fuelInfo = fuel_palette.fuelFor(nozzle.fuelCode);
      if (catalogHit) {
        return Fuel(name: fuelInfo.name, color: fuelInfo.color);
      }
      if (hose != null) {
        return Fuel(name: hose.fuelType, color: hose.fuelColor);
      }
      return Fuel(name: fuelInfo.name, color: fuelInfo.color);
    }

    if (hose != null) {
      return Fuel(name: hose.fuelType, color: hose.fuelColor);
    }

    return const Fuel(name: 'Desconocido', color: Colors.grey);
  }
}

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

String _resolveFaceLabel(_FaceData data, int faceIndex) {
  if (data.labelCandidates.isNotEmpty) {
    return data.labelCandidates.first;
  }
  return _faceLabel(faceIndex);
}

String _hoseKeyFromNozzle(int nozzleNumber) =>
    'M${nozzleNumber.toString().padLeft(2, '0')}';

String _normalizeLabel(String? value) {
  if (value == null) return '';
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.toUpperCase();
}

int? _indexFromPosition(String? value) {
  final normalized = _normalizeLabel(value);
  if (normalized.isEmpty) return null;

  final code = normalized.codeUnitAt(0);
  if (code >= 65 && code <= 90) {
    return code - 64;
  }

  return int.tryParse(normalized);
}

int _nextFaceIndex(Map<int, _FaceData> faces) {
  final currentMax =
      faces.isEmpty ? 0 : faces.keys.reduce(math.max);
  var candidate = currentMax + 1;
  while (faces.containsKey(candidate)) {
    candidate++;
  }
  return candidate;
}

int? _pumpIdFromAddress(String? address) {
  if (address == null || address.isEmpty) return null;
  final segment = address.split('-').firstWhere(
    (element) => element.trim().isNotEmpty,
    orElse: () => '',
  );
  final match = RegExp(r'\d+').firstMatch(segment);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

String _faceLabel(int faceIndex) {
  if (faceIndex <= 0) return '?';
  return faceIndex.toString();
}
