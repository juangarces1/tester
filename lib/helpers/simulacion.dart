import 'dart:async';
import 'dart:math';
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';
import 'package:tester/ConsoleModels/pump_faces_model.dart';

/// Mock que simula la respuesta de la API getPumpsAndFaces()
class MockConsoleApiHelper {
  static Future<List<PumpData>> getPumpsAndFaces() async {
    // Simula retardo de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Genera 5 pumps
    final pumps = List<PumpData>.generate(5, (pumpIndex) {
      final pumpId = pumpIndex + 1;
      return PumpData(
        id: pumpId,
        pumpName: 'Pump $pumpId',
        description: 'Mock Pump $pumpId',
        companyId: 1,
        company: 'MockCompany',
        numberOfFaces: 2,
        // Cada face tiene 3 mangueras → 2 faces × 3 = 6 elementos
        dispensers: List<DispenserFace>.generate(6, (faceIndex) {
          final faceNumber = faceIndex ~/ 3 + 1;
          final hoseNumber = faceIndex % 3 + 1;
          return DispenserFace(
            id: '$pumpId-$faceNumber-$hoseNumber',
            description: 'Hose $hoseNumber of face $faceNumber',
            numberOfFace: faceNumber,
          );
        }),
      );
    });

    return pumps;
  }

  static Future<List<DispenserStatus>> getDispensersStatus() async {
    // Simula latencia de red
    await Future.delayed(const Duration(milliseconds: 500));

    const int pumpCount = 5;        // misma cantidad que en getPumpsAndFaces()
    const int facesPerPump = 2;
    const int hosesPerFace = 3;

    final random = Random();
    final List<DispenserStatus> dispensers = [];

    for (var pumpId = 1; pumpId <= pumpCount; pumpId++) {
      // Construye lista de mangueras para este dispensador
      final List<DispenserHose> hoses = [];
      for (var face = 1; face <= facesPerPump; face++) {
        for (var hoseIdx = 1; hoseIdx <= hosesPerFace; hoseIdx++) {
          final nozzleNumber = ((pumpId - 1) * facesPerPump * hosesPerFace) +
                               ((face - 1) * hosesPerFace) +
                               hoseIdx;
          hoses.add(DispenserHose(
            number: nozzleNumber,
            key: 'P${pumpId}F${face}H$hoseIdx',
            status: _randomHoseStatus(random),
            description: 'Manguera $hoseIdx',
            totalVolume: double.parse((random.nextDouble() * 100).toStringAsFixed(2)),
            totalAmount: double.parse((random.nextDouble() * 200).toStringAsFixed(2)),
          ));
        }
      }

      dispensers.add(DispenserStatus(
        number: pumpId,
        key: 'D$pumpId',
        description: 'Dispensador $pumpId',
        status: 'Available',
        activeHose: hoses.isNotEmpty ? hoses.first.key : '',
        hoses: hoses,
      ));
    }

    return dispensers;
  }

  /// Genera un estado aleatorio para una manguera.
  static String _randomHoseStatus(Random rnd) {
    const statuses = ['Available', 'Dispensing', 'Unpaid', 'Blocked'];
    return statuses[rnd.nextInt(statuses.length)];
  }

}




