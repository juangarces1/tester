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

    final assignedKeys = <String>{};

    final nozzleToPumpId = <int, int>{};
    final nozzleFaceIndexByPump = <int, Map<int, int>>{};
    final groupsByAddress = <String, _PositionGroup>{};

    for (final nozzle in nozzles) {
      final rawAddress = nozzle.dispenseAddress.trim();
      final pumpId = _pumpIdFromAddress(rawAddress) ?? nozzle.dispense;
      final faceIndexCandidate =
          _indexFromPosition(nozzle.position) ?? nozzle.dispense;
      final faceIndex = faceIndexCandidate > 0 ? faceIndexCandidate : 1;

      final normalizedLabel = _normalizeLabel(nozzle.position);
      final fallbackLabel =
          normalizedLabel.isNotEmpty ? normalizedLabel : _faceLabel(faceIndex);
      final effectiveAddress =
          rawAddress.isNotEmpty ? rawAddress : 'P$pumpId-$fallbackLabel';
      final pumpName = pumpById[pumpId]?.pumpName ??
          (pumpId > 0 ? 'Surtidor $pumpId' : 'Posición $effectiveAddress');

      final group = groupsByAddress.putIfAbsent(
        effectiveAddress,
        () => _PositionGroup(
          dispenserAddress: effectiveAddress,
          pumpId: pumpId,
          pumpName: pumpName,
          faceIndex: faceIndex,
        ),
      );

      group.faceData.addLabel(nozzle.position);
      if (group.faceData.labelCandidates.isEmpty) {
        group.faceData.addLabel(fallbackLabel);
      }
      if ((group.faceData.description == null ||
              group.faceData.description!.isEmpty) &&
          nozzle.fullAddress.trim().isNotEmpty) {
        group.faceData.description = nozzle.fullAddress;
      }

      final statusCtx = _pickStatusFor(
        nozzleNumber: nozzle.nozzleNumber,
        hoseKey: nozzle.fullAddress,
        description: nozzle.fullAddress,
        byNozzle: statusByNozzle,
        byKey: statusByKey,
        byDescription: statusByDescription,
        assignedKeys: assignedKeys,
      );

      final hose = _buildHose(
        pumpId: group.pumpId,
        nozzleNumber: nozzle.nozzleNumber,
        statusCtx: statusCtx,
        nozzle: nozzle,
        fallbackKey: nozzle.fullAddress,
      );

      if (hose != null) {
        group.faceData.hoses.add(hose);
        if (statusCtx != null) {
          assignedKeys.add(statusCtx.hose.key);
        }
      }

      nozzleToPumpId[nozzle.nozzleNumber] = group.pumpId;
      final faceIndexForMap =
          group.faceData.faceIndex > 0 ? group.faceData.faceIndex : faceIndex;
      nozzleFaceIndexByPump
          .putIfAbsent(group.pumpId, () => <int, int>{})[nozzle.nozzleNumber] =
          faceIndexForMap;
    }

    final result = <int, PositionPhysical>{};
    var posCounter = 1;

    final sortedGroups = groupsByAddress.values.toList()
      ..sort((a, b) {
        final pumpComparison = a.pumpId.compareTo(b.pumpId);
        if (pumpComparison != 0) return pumpComparison;

        final faceComparison =
            a.faceData.faceIndex.compareTo(b.faceData.faceIndex);
        if (faceComparison != 0) return faceComparison;

        return a.dispenserAddress.compareTo(b.dispenserAddress);
      });

    for (final group in sortedGroups) {
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

          final pumpName = pumpById[pumpId]?.pumpName ??
              (status.description.trim().isNotEmpty
                  ? status.description
                  : (pumpId > 0
                      ? 'Surtidor $pumpId'
                      : 'Posición ${nozzle?.dispenseAddress ?? hose.key}'));
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

      final orderedFallbackGroups = fallbackGroups.values.toList()
        ..sort((a, b) {
          final pumpComparison = a.pumpId.compareTo(b.pumpId);
          if (pumpComparison != 0) return pumpComparison;

          return a.faceData.faceIndex.compareTo(b.faceData.faceIndex);
        });

      for (final group in orderedFallbackGroups) {
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
      final fuelInfo = fuel_palette.fuelFor(nozzle.fuelCode);
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

class _PositionGroup {
  final String dispenserAddress;
  final int pumpId;
  final String pumpName;
  final _FaceData faceData;

  _PositionGroup({
    required this.dispenserAddress,
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
