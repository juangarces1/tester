// lib/Screens/Dispatch/hose_step_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/Components/menu_page.dart';
import 'package:tester/Screens/NewHome/PagesWizard/preset_step_page.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMap();
    });
  }

  Future<void> _refreshMap() async {
    if (_loadingInFlight) return;
    _loadingInFlight = true;
    try {
      await context.read<MapProvider>().loadMap();
    } finally {
      _loadingInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final despachosProv = context.read<DespachosProvider>();
    final DispatchControl dispatch =
        despachosProv.getById(widget.dispatchId)!;

    final selectedNumber = dispatch.selectedPosition?.number;
    final map = mapProv.stationMap;
    final position =
        selectedNumber != null && map != null ? map[selectedNumber] : null;

    final hoses = position?.hoses
            .where((hose) => hose.status.toLowerCase() == 'available')
            .toList() ??
        <HosePhysical>[];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          selectedNumber == null
              ? '2. Elige manguera'
              : '2. POS ${selectedNumber.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white),
        ),
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
      body: mapProv.isLoading && map == null
          ? const Center(child: CircularProgressIndicator())
          : map == null
              ? _NoPositionSelected(
                  message: 'No pudimos cargar las posiciones. Intenta actualizar.',
                  onRetry: _refreshMap,
                )
              : selectedNumber == null
                  ? const _NoPositionSelected()
                  : position == null
                      ? _NoPositionSelected(
                      message:
                          'No encontramos la posición seleccionada. Intenta recargar.',
                      onRetry: _refreshMap,
                    )
                  : hoses.isEmpty
                      ? _NoAvailableHoses(onRetry: _refreshMap)
                      : RefreshIndicator(
                          onRefresh: _refreshMap,
                          color: Colors.white,
                          backgroundColor: Colors.black87,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3 / 3.6,
                            ),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: hoses.length,
                            itemBuilder: (_, index) {
                              final hose = hoses[index];
                              return _HoseCard(
                                hose: hose,
                                onTap: () {
                                  dispatch.selectHose(
                                    pos: position,
                                    hose: hose,
                                  );
                                  despachosProv.refresh();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PresetStepPage(
                                        dispatchId: widget.dispatchId,
                                      ),
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

class _HoseCard extends StatelessWidget {
  final HosePhysical hose;
  final VoidCallback onTap;
  const _HoseCard({required this.hose, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = hose.fuel.color;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 6,
        color: accent,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_gas_station,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                'M-${hose.nozzleNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hose.fuel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text(
                      'Disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAvailableHoses extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoAvailableHoses({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          const Text(
            'No hay mangueras disponibles en esta posición',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

class _NoPositionSelected extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _NoPositionSelected({
    this.message = 'Selecciona primero una posición',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ev_station, size: 60, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
