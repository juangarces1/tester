import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/Screens/NewHome/PagesWizard/preset_step_page.dart';

class PositionHosesPage extends StatefulWidget {
  final int positionNumber; // solo para el título
  final int pumpId;
  final int faceIndex;
  final String dispatchId;
  const PositionHosesPage({
    required this.positionNumber,
    required this.pumpId,
    required this.faceIndex,
    required this.dispatchId,
    super.key,
  });

  @override
  State<PositionHosesPage> createState() => _PositionHosesPageState();
}

class _PositionHosesPageState extends State<PositionHosesPage> {
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
    final DispatchControl dispatch = despachosProv.getById(widget.dispatchId)!;
    final map = mapProv.stationMap;
    PositionPhysical? position;
    List<HosePhysical> hoses = <HosePhysical>[];
    if (map != null) {
      final sameFace = map.values.where(
        (p) => p.pumpId == widget.pumpId && p.faceIndex == widget.faceIndex,
      );
      if (sameFace.isNotEmpty) {
        final list = sameFace.toList()..sort((a, b) => a.number.compareTo(b.number));
        final first = list.first;
        final mergedHoses = <HosePhysical>[];
        for (final p in list) {
          mergedHoses.addAll(p.hoses);
        }
        mergedHoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
        position = PositionPhysical(
          number: widget.positionNumber,
          pumpId: first.pumpId,
          pumpName: first.pumpName,
          faceIndex: first.faceIndex,
          faceLabel: first.faceLabel,
          faceDescription: first.faceDescription,
          hoses: List.unmodifiable(mergedHoses),
        );
        hoses = mergedHoses;
      }
    }

    final availableCount =
        hoses.where((h) => h.status.toLowerCase() == 'available').length;

    final titleText = 'POS ${widget.positionNumber.toString().padLeft(2, '0')}';
    // final subtitleParts = <String>[];
    // if (position?.pumpName.isNotEmpty == true) subtitleParts.add(position!.pumpName);
    // final faceLabel = position != null && position.faceLabel.isNotEmpty
    //     ? 'Posición ${position.faceLabel}'
    //     : '';
    // if (faceLabel.isNotEmpty) subtitleParts.add(faceLabel);
    // if ((position?.faceDescription.trim().isNotEmpty ?? false)) {
    //   subtitleParts.add(position!.faceDescription.trim());
    // }
     final subtitleText = position!.pumpName;
   
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titleText, style: const TextStyle(color: Colors.white)),
            if (subtitleText.isNotEmpty)
              Text(
                subtitleText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
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
        ],
      ),
      body: mapProv.isLoading && map == null
          ? const Center(child: CircularProgressIndicator())
          : map == null
              ? _NoPositionSelected(
                  message: 'No pudimos cargar las posiciones. Intenta actualizar.',
                  onRetry: _refreshMap,
                )
              : position == null
                  ? _NoPositionSelected(
                      message:
                          'No encontramos la posición seleccionada. Intenta recargar.',
                      onRetry: _refreshMap,
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshMap,
                      color: Colors.white,
                      backgroundColor: Colors.black87,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            sliver: SliverToBoxAdapter(
                              child: _HoseSummary(
                                total: hoses.length,
                                available: availableCount,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final hose = hoses[index];
                                  final isAvailable =
                                      hose.status.toLowerCase() == 'available';
                                  return _HoseCard(
                                    hose: hose,
                                    enabled: isAvailable,
                                    onTap: () {
                                      if (!isAvailable) return;
                                      if (position == null) return;
                                      dispatch.selectHose(pos: position, hose: hose);
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
                                childCount: hoses.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3 / 3.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _NoPositionSelected extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  const _NoPositionSelected({this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ev_station, size: 62, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            message ?? 'Selecciona una posición para ver mangueras',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
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

class _HoseSummary extends StatelessWidget {
  final int total;
  final int available;
  const _HoseSummary({required this.total, required this.available});

  @override
  Widget build(BuildContext context) {
    final availabilityColor =
        available > 0 ? Colors.greenAccent : Colors.orangeAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total manguera${total == 1 ? '' : 's'} en esta posición',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          available > 0 ? '$available disponibles' : 'Sin mangueras disponibles',
          style: TextStyle(
            color: availabilityColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HoseCard extends StatelessWidget {
  final HosePhysical hose;
  final bool enabled;
  final VoidCallback onTap;
  const _HoseCard({required this.hose, this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = hose.fuel.color;
    final statusLabel = _hoseStatusLabel(hose.status);
    final statusColor = _hoseStatusColor(statusLabel);
    final statusIcon = _hoseStatusIcon(statusLabel);
    final cardColor = enabled ? accent : accent.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 6,
        color: cardColor,
        shadowColor: accent.withValues(alpha: enabled ? 0.35 : 0.18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Center(
                 child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: statusColor, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
               ),
              const SizedBox(height: 20),
              Text(
                'D0${hose.nozzleNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                hose.fuel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.local_gas_station,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 28,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

String _hoseStatusLabel(String raw) {
  final normalized = raw.toLowerCase();
  if (normalized.contains('fuel')) return 'Despachando';
  if (normalized.contains('author')) return 'Autorizada';
  if (normalized.contains('available')) return 'Disponible';
  if (normalized.contains('busy')) return 'Ocupada';
  if (normalized.isEmpty || normalized == 'unknown') return 'Sin datos';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

Color _hoseStatusColor(String status) {
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

IconData _hoseStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'disponible':
      return Icons.check_circle_outline;
    case 'autorizada':
      return Icons.verified_outlined;
    case 'despachando':
      return Icons.local_fire_department_outlined;
    case 'ocupada':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}
