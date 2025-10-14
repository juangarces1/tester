

import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/pump_faces_model.dart';         // PumpData, DispenserFace
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart'; // DispenserStatus, DispenserHose

// ----------------------------- MODELOS ----------------------------------
class Fuel {
  final String name;
  final Color  color;
  const Fuel({required this.name, required this.color});
}

class HosePhysical {
  final int    nozzleNumber;
  final String hoseKey;
  final Fuel   fuel;
  final String status;      // status crudo del API (authorized, fueling, etc.)
  const HosePhysical({
    required this.nozzleNumber,
    required this.hoseKey,
    required this.fuel,
    required this.status,
  });
}

class PositionPhysical {
  final int number;                   // 1,2,3… global
  final int pumpId;                   // identificador del surtidor físico
  final String pumpName;              // nombre descriptivo del surtidor
  final int faceIndex;                // índice físico de la cara (1,2,…)
  final String faceLabel;             // etiqueta legible (A/B o 1/2)
  final String faceDescription;       // descripción proveniente del mapa
  final List<HosePhysical> hoses;     // mangueras asociadas a la cara

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
    bool strictPhysicalOnly = false,
  }) {
    final hoseByNozzle = <int, DispenserHose>{};
    final hoseByKey = <String, DispenserHose>{};
    final hoseByDescription = <String, DispenserHose>{};

    for (final status in statuses) {
      for (final hose in status.hoses) {
        hoseByNozzle[hose.number] = hose;
        hoseByKey[hose.key] = hose;
        final descKey = hose.description.trim().toLowerCase();
        if (descKey.isNotEmpty && !hoseByDescription.containsKey(descKey)) {
          hoseByDescription[descKey] = hose;
        }
      }
    }

    final result = <int, PositionPhysical>{};
    final assignedHoseKeys = <String>{};
    var posCounter = 1;

    for (final pump in pumps) {
      final faces = <int, List<HosePhysical>>{};
      final faceDescriptions = <int, String>{};

      for (final face in pump.dispensers) {
        final faceIndex = face.numberOfFace;
        final hoses = faces.putIfAbsent(faceIndex, () => <HosePhysical>[]);

        if (!faceDescriptions.containsKey(faceIndex) ||
            faceDescriptions[faceIndex]!.isEmpty) {
          faceDescriptions[faceIndex] = face.description;
        }

        final nozzleNumber = int.tryParse(face.id) ?? -1;

        DispenserHose? statusHose;
        if (nozzleNumber >= 0) statusHose = hoseByNozzle[nozzleNumber];
        statusHose ??= hoseByKey[face.id];
        statusHose ??= hoseByDescription[face.description.trim().toLowerCase()];

        final fuel = statusHose != null
            ? _fuelFromHose(statusHose)
            : const Fuel(name: 'Desconocido', color: Colors.grey);

        final hoseKey = statusHose?.key ?? '${pump.id}-${face.id}';
        final hoseStatus = statusHose?.status ?? 'unknown';
        final resolvedNozzle = statusHose?.number ?? nozzleNumber;

        hoses.add(
          HosePhysical(
            nozzleNumber: resolvedNozzle,
            hoseKey: hoseKey,
            fuel: fuel,
            status: hoseStatus,
          ),
        );

        assignedHoseKeys.add(hoseKey);
      }

      final orderedFaces = faces.keys.toList()..sort();
      for (final faceIndex in orderedFaces) {
        final hoses = faces[faceIndex]!;
        hoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
        final faceLabel = _faceLabel(faceIndex);
        final description = faceDescriptions[faceIndex]?.trim() ?? '';

        result[posCounter] = PositionPhysical(
          number: posCounter,
          pumpId: pump.id,
          pumpName: pump.pumpName,
          faceIndex: faceIndex,
          faceLabel: faceLabel,
          faceDescription: description,
          hoses: List.unmodifiable(hoses),
        );
        posCounter++;
      }
    }

    if (!strictPhysicalOnly) {
      for (final status in statuses) {
        final remainingHoses = status.hoses
            .where((hose) => !assignedHoseKeys.contains(hose.key))
            .toList();

        if (remainingHoses.isEmpty) continue;

        remainingHoses.sort((a, b) => a.number.compareTo(b.number));
        final hoses = remainingHoses
            .map(
              (hose) => HosePhysical(
                nozzleNumber: hose.number,
                hoseKey: hose.key,
                fuel: _fuelFromHose(hose),
                status: hose.status,
              ),
            )
            .toList();

        final fallbackLabel = _faceLabel(status.number);
        result[posCounter] = PositionPhysical(
          number: posCounter,
          pumpId: status.number,
          pumpName: status.description,
          faceIndex: status.number,
          faceLabel: fallbackLabel,
          faceDescription: status.description,
          hoses: List.unmodifiable(hoses),
        );

        assignedHoseKeys.addAll(remainingHoses.map((hose) => hose.key));
        posCounter++;
      }
    }

    return result;
  }

  // --------------------- Fuel detection (desde DispenserHose) ------------
  static Fuel _fuelFromHose(DispenserHose hose) {
    return Fuel(name: hose.fuelType, color: hose.fuelColor);
  }
}

String _faceLabel(int faceIndex) {
  if (faceIndex <= 0) return '?';
  // Mostrar siempre como número de cara: 1, 2, 3, ...
  return faceIndex.toString();
}
