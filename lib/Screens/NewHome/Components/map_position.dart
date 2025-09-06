import 'package:flutter/material.dart';
import 'package:tester/ViewModels/new_map.dart'          // PositionPhysical, HosePhysical
    show PositionPhysical, HosePhysical;

/// ===================
///  StationMapPage
/// ===================
class StationMapPage extends StatelessWidget {
  final Map<int, PositionPhysical> fullMap;
  final String fuelDescription;                // ej. “Gasolina Premium”

  const StationMapPage({
    super.key,
    required this.fullMap,
    required this.fuelDescription,
  });

  @override
  Widget build(BuildContext context) {
    /* --------- Plano: lista de (pos, hose) que cumplen filtros --------- */
    final hosesToShow = <_HoseInfo>[];

    for (final pos in fullMap.values) {
      for (final hose in pos.hoses) {
        if (hose.status == 'Available' &&
            hose.fuel.name.toLowerCase() ==
                fuelDescription.toLowerCase()) {
          hosesToShow.add(_HoseInfo(pos: pos, hose: hose));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa – $fuelDescription disponibles'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: hosesToShow.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => HoseTile(info: hosesToShow[i]),
      ),
    );
  }
}

/* Pequeño wrapper para pasar ambos datos al Tile */
class _HoseInfo {
  final PositionPhysical pos;
  final HosePhysical     hose;
  const _HoseInfo({required this.pos, required this.hose});
}

/// ===================
///  HoseTile
/// ===================
class HoseTile extends StatelessWidget {
  final _HoseInfo info;
  const HoseTile({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final pos  = info.pos;
    final hose = info.hose;

    return Card(
      color: Colors.green.shade500,            // siempre “Available”
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Posición ${pos.number}',                     // nº posición global
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'M${hose.nozzleNumber}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                hose.fuel.name,                           // descripción tal cual
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white70, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
