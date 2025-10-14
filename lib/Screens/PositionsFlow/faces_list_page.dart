import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/Screens/PositionsFlow/position_hoses_page.dart';

class FacesListPage extends StatefulWidget {
  final String dispatchId;
  const FacesListPage({required this.dispatchId, super.key});

  @override
  State<FacesListPage> createState() => _FacesListPageState();
}

class _FacesListPageState extends State<FacesListPage> {
  bool _loadingInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMap());
  }

  Future<void> _refreshMap() async {
    if (_loadingInFlight) return;
    _loadingInFlight = true;
    try {
      await context.read<MapProvider>().loadMap(strictPhysicalOnly: true);
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

    if (mapProv.isError && !mapProv.toastShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Fluttertoast.showToast(
          msg: 'No se pudo cargar el mapa',
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      });
      mapProv.markToastShown();
    }

    final map = mapProv.stationMap;
    // Lista base de posiciones
    final basePositions = map != null
        ? (map.values.toList()..sort((a, b) => a.number.compareTo(b.number)))
        : <PositionPhysical>[];

    // Garantiza agrupación estricta por (pumpId, faceIndex) en caso de que el builder
    // haya emitido posiciones por manguera por datos inconsistentes.
    final grouped = <String, List<PositionPhysical>>{};
    for (final p in basePositions) {
      final key = '${p.pumpId}-${p.faceIndex}';
      grouped.putIfAbsent(key, () => <PositionPhysical>[]).add(p);
    }

    var seq = 1;
    final positions = <PositionPhysical>[];
    grouped.forEach((_, list) {
      // fusiona hoses de todas las posiciones de la misma cara
      list.sort((a, b) => a.number.compareTo(b.number));
      final first = list.first;
      final mergedHoses = <HosePhysical>[];
      for (final p in list) {
        mergedHoses.addAll(p.hoses);
      }
      mergedHoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
      positions.add(
        PositionPhysical(
          number: seq++,
          pumpId: first.pumpId,
          pumpName: first.pumpName,
          faceIndex: first.faceIndex,
          faceLabel: first.faceLabel,
          faceDescription: first.faceDescription,
          hoses: List.unmodifiable(mergedHoses),
        ),
      );
    });
    positions.sort((a, b) => a.number.compareTo(b.number));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('1. Selecciona posición',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mapa',
            onPressed: _refreshMap,
          ),
        ],
      ),
      body: mapProv.isLoading && map == null
          ? const Center(child: CircularProgressIndicator())
          : map == null
              ? _EmptyState(onRetry: _refreshMap)
              : RefreshIndicator(
                  onRefresh: _refreshMap,
                  color: Colors.white,
                  backgroundColor: Colors.black87,
                  child: positions.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.ev_station,
                                size: 64, color: Colors.white38),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No hay posiciones disponibles',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: positions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (_, index) {
                            final position = positions[index];
                            return _PositionCard(
                              position: position,
                              onTap: () {
                                dispatch.selectPosition(position);
                                despachosProv.refresh();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PositionHosesPage(
                                      dispatchId: widget.dispatchId,
                                      positionNumber: position.number,
                                      pumpId: position.pumpId,
                                      faceIndex: position.faceIndex,
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

class _PositionCard extends StatelessWidget {
  final PositionPhysical position;
  final VoidCallback onTap;
  const _PositionCard({required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
   
    final status = _statusLabel(position);
     final accent = status == 'Disponible'
        ? Colors.green
        : status == 'Autorizada'
            ? Colors.lightBlueAccent
            : status == 'Despachando'
                ? Colors.indigo
                : status == 'Detenida'
                ? Colors.orangeAccent
                : status == 'Ocupada'
                    ? Colors.redAccent
                    : Colors.white70;
    final statusColor = _statusColor(status);
    final availableCount = position.hoses
        .where((h) => h.status.toLowerCase() == 'available')
        .length;
    final pumpLabel = position.pumpName.isNotEmpty &&
            position.pumpName.toLowerCase() != 'sin mapa'
        ? position.pumpName
        : 'Surtidor ${position.pumpId > 0 ? position.pumpId : position.number}';
    final faceLabel = position.faceLabel.isNotEmpty
        ? 'Posición ${position.faceLabel}'
        : 'Posición';
    final faceDescription = position.faceDescription.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.55),
                accent.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'POS ${position.number.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor, width: 1.3),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pumpLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            
                // Text(
                //   faceDescription.isNotEmpty
                //       ? '$faceLabel - $faceDescription'
                //       : faceLabel,
                //   style: const TextStyle(
                //     color: Colors.white60,
                //     fontSize: 13,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
                const SizedBox(height: 16),
                Text(
                  'Total de mangueras: ${position.hoses.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Disponibles ahora: $availableCount',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ev_station, size: 62, color: Colors.white38),
          const SizedBox(height: 16),
          const Text(
            'No pudimos cargar las posiciones',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(PositionPhysical position) {
  final normalized = position.hoses
      .map((h) => h.status.toLowerCase())
      .where((status) => status.isNotEmpty)
      .toList();

  if (normalized.any((s) => s.contains('fuel'))) {
    return 'Despachando';
  }
  if (normalized.any((s) => s.contains('author'))) {
    return 'Autorizada';
  }
  if (normalized.any((s) => s.contains('available'))) {
    return 'Disponible';
  }
  if (normalized.any((s) => s.contains('busy'))) {
    return 'Ocupada';
  }
  if (normalized.any((s) => s.contains('stopped'))) {
    return 'Detenida';
  }
  if (normalized.isEmpty) {
    return 'Sin datos';
  }
  final raw = normalized.first;
  return raw[0].toUpperCase() + raw.substring(1);
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'disponible':
      return Colors.greenAccent;
    case 'autorizada':
      return Colors.lightBlueAccent;
    case 'despachando':
      return Colors.orangeAccent;
    case 'ocupada':
      return Colors.redAccent;
    default:
      return Colors.white70;
  }
}
