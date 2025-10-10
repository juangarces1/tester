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
    final DispatchControl dispatch =  despachosProv.getById(widget.dispatchId)!;

    final selectedNumber = dispatch.selectedPosition?.number;
    final map = mapProv.stationMap;
    final position =
        selectedNumber != null && map != null ? map[selectedNumber] : null;

    final hoses = position != null
        ? List<HosePhysical>.from(position.hoses)
        : <HosePhysical>[];
    hoses.sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));
    final availableCount =
        hoses.where((hose) => hose.status.toLowerCase() == 'available').length;
    final pumpLabel = position?.pumpName ?? '';
    final faceLabel = position != null && position.faceLabel.isNotEmpty
        ? 'Cara ${position.faceLabel}'
        : '';
    final faceDescription = position?.faceDescription.trim() ?? '';
    final subtitleParts = <String>[];
    if (pumpLabel.isNotEmpty) subtitleParts.add(pumpLabel);
    if (faceLabel.isNotEmpty) subtitleParts.add(faceLabel);
    if (faceDescription.isNotEmpty) subtitleParts.add(faceDescription);
    final subtitleText = subtitleParts.join(' - ');
    final titleText = selectedNumber == null
        ? '2. Elige manguera'
        : '2. POS ${selectedNumber.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: const TextStyle(color: Colors.white),
            ),
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
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menu',
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
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 12),
                                sliver: SliverToBoxAdapter(
                                  child: _HoseSummary(
                                    total: hoses.length,
                                    available: availableCount,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final hose = hoses[index];
                                      final isAvailable =
                                          hose.status.toLowerCase() ==
                                              'available';
                                      return _HoseCard(
                                        hose: hose,
                                        enabled: isAvailable,
                                        onTap: () {
                                          if (!isAvailable) return;
                                          dispatch.selectHose(
                                            pos: position,
                                            hose: hose,
                                          );
                                          despachosProv.refresh();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PresetStepPage(
                                                dispatchId:
                                                    widget.dispatchId,
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
          '$total manguera${total == 1 ? '' : 's'} en esta cara',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          available > 0
              ? '$available disponibles'
              : 'Sin mangueras disponibles',
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
  const _HoseCard({
    required this.hose,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hose.fuel.color;
    final statusLabel = _hoseStatusLabel(hose.status);
    final statusColor = _hoseStatusColor(statusLabel);
    final statusIcon = _hoseStatusIcon(statusLabel);
    final cardColor = enabled ? accent : accent.withOpacity(0.45);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 6,
        color: cardColor,
        shadowColor: accent.withOpacity(enabled ? 0.35 : 0.18),
        child: Opacity(
          opacity: enabled ? 1 : 0.65,
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hose.fuel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
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
                    border: Border.all(
                      color: statusColor.withOpacity(0.7),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: const TextStyle(
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
      ),
    );
  }
}

String _hoseStatusLabel(String raw) {
  final normalized = raw.toLowerCase();
  if (normalized.contains('fuel')) return 'Despachando';
  if (normalized.contains('author')) return 'Autorizada';
  if (normalized.contains('available')) return 'Disponible';
  if (normalized.contains('unpaid')) return 'Pendiente pago';
  if (normalized.contains('blocked')) return 'Bloqueada';
  if (normalized.contains('busy')) return 'Ocupada';
  if (normalized.isEmpty) return 'Sin datos';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

Color _hoseStatusColor(String label) {
  switch (label.toLowerCase()) {
    case 'disponible':
      return Colors.greenAccent;
    case 'autorizada':
      return Colors.lightBlueAccent;
    case 'despachando':
      return Colors.orangeAccent;
    case 'pendiente pago':
      return Colors.amberAccent;
    case 'bloqueada':
    case 'ocupada':
      return Colors.redAccent;
    default:
      return Colors.white70;
  }
}

IconData _hoseStatusIcon(String label) {
  switch (label.toLowerCase()) {
    case 'disponible':
      return Icons.check_circle;
    case 'autorizada':
      return Icons.verified;
    case 'despachando':
      return Icons.local_fire_department;
    case 'pendiente pago':
      return Icons.payments;
    case 'bloqueada':
      return Icons.lock;
    case 'ocupada':
      return Icons.do_not_disturb_on;
    default:
      return Icons.help_outline;
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
            'No hay mangueras registradas en esta cara',
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
