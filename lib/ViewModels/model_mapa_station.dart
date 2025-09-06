import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';

class PumpBeach {
  final int id;
  final String pumpName;
  final int numberOfFaces;
  final List<PumpBeachDispenser> dispensers;
  PumpBeach({required this.id, required this.pumpName, required this.numberOfFaces, required this.dispensers});
}

class PumpBeachDispenser {
  final int id;
  final int numberOfFace;
  PumpBeachDispenser({required this.id, required this.numberOfFace});
}

class MangueraConEstado {
  final PumpBeachDispenser dispenserInfo;  // del mapa físico
  final DispenserStatus? status;           // estado (puede ser null si no está en status)

  MangueraConEstado({required this.dispenserInfo, this.status});
}

class CaraAgrupada {
  final String pumpName;
  final int cara;
  final List<MangueraConEstado> mangueras;
  CaraAgrupada({required this.pumpName, required this.cara, required this.mangueras});
}

List<CaraAgrupada> agruparPorCara(
    List<PumpBeach> pumps,
    List<DispenserStatus> statuses,
  ) {
  // Indexa status por id (manguera)
  final statusPorId = { for (var s in statuses) s.number: s };
  final List<CaraAgrupada> resultado = [];

  for (final pump in pumps) {
    final caras = <int, List<MangueraConEstado>>{};
    for (final d in pump.dispensers) {
      final estado = statusPorId[d.id];
      caras.putIfAbsent(d.numberOfFace, () => []);
      caras[d.numberOfFace]!.add(
        MangueraConEstado(dispenserInfo: d, status: estado),
      );
    }
    for (final entry in caras.entries) {
      resultado.add(
        CaraAgrupada(
          pumpName: pump.pumpName,
          cara: entry.key,
          mangueras: entry.value,
        ),
      );
    }
  }
  return resultado;
}