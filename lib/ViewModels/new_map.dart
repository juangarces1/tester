

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
  final int number;                 // 1,2,3… global
  final List<HosePhysical> hoses;   // mangueras de la cara
  const PositionPhysical({required this.number, required this.hoses});
}

// -----------------------------  BUILDER  ---------------------------------
class PositionBuilder {
  static Map<int, PositionPhysical> build({
    required List<PumpData> pumps,
    required List<DispenserStatus> statuses,
  }) {
    // 1) Índice de caras por id → (pumpId, faceIndex) para ordenar estable
    final faceMetaById = <String, _FaceMeta>{};
    for (final p in pumps) {
      for (final f in p.dispensers) {
        faceMetaById[f.id] = _FaceMeta(pumpId: p.id, faceIndex: f.numberOfFace);
      }
    }

    // 2) Agrupar mangueras por cara usando **statuses** (traen descripción y status)
    final hosesByFaceId = <String, List<HosePhysical>>{};
    for (final st in statuses) {
      final faceId = st.key; // Identificador único de la cara
      final list = hosesByFaceId.putIfAbsent(faceId, () => <HosePhysical>[]);

      for (final h in st.hoses) {
        final fuel = _fuelFromDispenser(st); // ← descripción tomada del status
        list.add(HosePhysical(
          nozzleNumber: h.number,
          hoseKey     : h.key,
          fuel        : fuel,
          status      : h.status,
        ));
      }
    }

    // 3) Orden: primero caras presentes en 'pumps' por (pumpId, faceIndex),
    //    luego las caras que salgan en statuses pero no existan en pumps.
    final knownFaceIds = faceMetaById.keys.toSet();
    final allFaceIds   = hosesByFaceId.keys.toSet();

    final orderedKnown = allFaceIds.where(knownFaceIds.contains).toList()
      ..sort((a,b) {
        final am = faceMetaById[a]!;
        final bm = faceMetaById[b]!;
        final cmp = am.pumpId.compareTo(bm.pumpId);
        return (cmp != 0) ? cmp : am.faceIndex.compareTo(bm.faceIndex);
      });

    final unknownFaces = allFaceIds.where((id) => !knownFaceIds.contains(id)).toList()
      ..sort(); // orden estable para las no mapeadas

    final faceOrder = <String>[...orderedKnown, ...unknownFaces];

    // 4) Construcción numerada
    final result = <int, PositionPhysical>{};
    var posCounter = 1;
    for (final faceId in faceOrder) {
      final hoses = hosesByFaceId[faceId]!;
      result[posCounter] = PositionPhysical(number: posCounter, hoses: hoses);
      posCounter++;
    }

    return result;
  }

  // --------------------- Fuel detection (desde DispenserHose) ------------
  static Fuel _fuelFromHose(DispenserHose hose) {     

   
    return  Fuel(name: hose.fuelType , color: hose.fuelColor);
  }

   static Fuel _fuelFromDispenser(DispenserStatus status) { 
     

    // Fallback
    return  Fuel(name: status.fuelType , color: status.fuelColor);
  }
}

// --------------------------- helpers internos ------------------------
class _FaceMeta {
  final int pumpId;
  final int faceIndex;
  const _FaceMeta({required this.pumpId, required this.faceIndex});
}
