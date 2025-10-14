// lib/ui/pos_adapters.dart



import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/modelos_faces.dart';

import '../ViewModels/new_map.dart' show Fuel, HosePhysical, PositionPhysical;
import 'fuel_palette.dart'; // para fuelName(...)

// --- Helpers ----

String hoseKeyFromNozzle(int nozzleNumber) => 'M${nozzleNumber.toString().padLeft(2, '0')}';

String faceLabelFromIndex(int faceIndex) {
  // Convención típica: 1->A, 2->B, 3->C...
  if (faceIndex <= 0) return faceIndex.toString();
  const base = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return faceIndex <= base.length ? base[faceIndex - 1] : faceIndex.toString();
}

// Ajusta este creador si tu Fuel tiene otra firma
Fuel fuelFromCode(int fuelCode) {
  return Fuel(
    color: Colors.red,
    name: fuelName(fuelCode), // de fuel_palette.dart
  );
}

// --- Adapters ----

HosePhysical toHosePhysical(HoseView h) {
  return HosePhysical(
    nozzleNumber: h.nozzleNumber,
    hoseKey: hoseKeyFromNozzle(h.nozzleNumber),
    fuel: fuelFromCode(h.fuelCode),
    status: h.status, // crudo del API ("Available", "Unpaid", etc.)
  );
}

PositionPhysical toPositionPhysical(FaceView f) {
  final label = faceLabelFromIndex(f.face);
  final pumpName = f.pumpName ?? 'Surtidor ${f.pumpId}';

  // Mapea todas las mangueras de la cara
  final hoses = f.hoses.map(toHosePhysical).toList();

  return PositionPhysical(
    number: f.pos,                      // POS global (1..N)
    pumpId: f.pumpId,                   // id del surtidor físico
    pumpName: pumpName,                 // nombre descriptivo
    faceIndex: f.face,                  // índice físico de la cara (1,2,…)
    faceLabel: label,                   // "A", "B", ...
    faceDescription: '$pumpName · Cara $label (POS ${f.pos})',
    hoses: hoses,                       // mangueras asociadas a la cara
  );
}
