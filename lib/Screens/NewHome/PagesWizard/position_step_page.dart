import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/PagesWizard/hose_step_page.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/ViewModels/new_map.dart';

class PositionStepPage extends StatefulWidget {
  final String dispatchId;
  const PositionStepPage({super.key, required this.dispatchId});

  @override
  State<PositionStepPage> createState() => _PositionStepPageState();
}

class _PositionStepPageState extends State<PositionStepPage> {
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

    if (mapProv.isError && !mapProv.toastShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Fluttertoast.showToast(
          msg: 'No se pudo cargar el mapa 😖',
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      });
      mapProv.markToastShown();
    }

    final map = mapProv.stationMap;
    final positions = map != null
        ? (map.values.toList()
          ..sort((a, b) => a.number.compareTo(b.number)))
        : <PositionPhysical>[];

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
              ? _EmptyState(
                  onRetry: _refreshMap,
                )
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
                            final isSelected = dispatch.selectedPosition?.number ==
                                position.number;
                            return _PositionCard(
                              position: position,
                              isSelected: isSelected,
                              onTap: () {
                                dispatch.selectPosition(position);
                                despachosProv.refresh();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HoseStepPage(dispatchId: widget.dispatchId),
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
  final bool isSelected;
  const _PositionCard({
    required this.position,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final accent = position.hoses.isNotEmpty
        ? position.hoses.first.fuel.color
        : Colors.blueGrey;
    final status = _statusLabel(position);
    final statusColor = _statusColor(status);
    final availableCount = position.hoses
        .where((h) => h.status.toLowerCase() == 'available')
        .length;
    final pumpLabel = position.pumpName.isNotEmpty &&
            position.pumpName.toLowerCase() != 'sin mapa'
        ? position.pumpName
        : 'Surtidor ${position.pumpId > 0 ? position.pumpId : position.number}';
    final faceLabel = position.faceLabel.isNotEmpty
        ? 'Cara ${position.faceLabel}'
        : 'Cara';
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
                accent.withOpacity(0.9),
                accent.withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.35),
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
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor, width: 1.3),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faceDescription.isNotEmpty
                      ? '$faceLabel - $faceDescription'
                      : faceLabel,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total de mangueras: ${position.hoses.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Disponibles ahora: $availableCount',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _SelectionHint(highlight: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  final Color highlight;
  const _SelectionHint({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.touch_app,
          color: highlight.withOpacity(0.9),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Toca para ver la lista de mangueras',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
