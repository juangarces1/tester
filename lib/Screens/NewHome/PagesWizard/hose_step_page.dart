// lib/Screens/Dispatch/hose_step_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/Components/menu_page.dart';
import 'package:tester/Screens/NewHome/PagesWizard/preset_step_page.dart';
import 'package:tester/ViewModels/new_map.dart';

class HoseStepPage extends StatefulWidget {
  final String dispatchId;
  const HoseStepPage({required this.dispatchId, super.key});

  @override
  State<HoseStepPage> createState() => _HoseStepPageState();
}

class _HoseStepPageState extends State<HoseStepPage> {
  bool _loadingInFlight = false;

  @override
  void initState() {
    super.initState();
    // Después del primer frame, forzar carga del mapa con await
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMap();
    });
  }

  Future<void> _refreshMap() async {
    final mapProv = Provider.of<MapProvider>(context, listen: false);
    if (_loadingInFlight) return; // evita recargas concurrentes
    _loadingInFlight = true;
    await mapProv.loadMap();
    _loadingInFlight = false;
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = Provider.of<MapProvider>(context);
    final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
    final dispatch = despachosProv.getById(widget.dispatchId)!;

    // Mostrar error una sola vez
    if (mapProv.isError && !mapProv.toastShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando el mapa: ${mapProv.error}')),
        );
        mapProv.markToastShown();
      });
    }

    // Loader mientras se carga o no hay mapa
    if (mapProv.isLoading || mapProv.stationMap == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stationMap = mapProv.stationMap!;

    // Filtrar mangueras disponibles para el combustible seleccionado
    final fuel = dispatch.fuel;
    final entries = <_HoseEntry>[];
    stationMap.forEach((_, pos) {
      for (final h in pos.hoses) {
        if (h.fuel.name == fuel!.name && h.status == 'Available') {
     // if (h.fuel.name == fuel!.name ) {
          entries.add(_HoseEntry(position: pos, hose: h));
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('3. Elige Manguera', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mapa',
            onPressed: _refreshMap,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menú',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'No hay mangueras para ese combustible',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshMap,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const Divider(color: Colors.grey),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: e.hose.fuel.color,
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      'POS ${e.position.number} — M-${e.hose.nozzleNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      e.hose.fuel.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    onTap: () {
                      dispatch.selectHose(
                        pos: e.position,
                        hose: e.hose,
                      );
                      despachosProv.refresh();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresetStepPage(dispatchId: dispatch.id!),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

/// Helper interno para agrupar posición + manguera
class _HoseEntry {
  final PositionPhysical position;
  final HosePhysical hose;
  _HoseEntry({required this.position, required this.hose});
}
