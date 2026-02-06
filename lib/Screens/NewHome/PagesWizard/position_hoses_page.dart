import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/Providers/experimental/alt_despachos_provider.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Screens/NewHome/PagesWizard/preset_kind_page.dart';

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
  }

  Future<void> _refreshMap() async {
    if (_loadingInFlight) return;
    setState(() => _loadingInFlight = true);
    try {
      await context.read<MapProvider>().loadMapDirect();
    } finally {
      if (mounted) {
        setState(() => _loadingInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final despachosProv = context.watch<AltDespachosProvider>();
    final AltDispatchControl? dispatch =
        despachosProv.getById(widget.dispatchId);

    // Si el despacho fue eliminado, mostramos pantalla de error
    if (dispatch == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'El despacho ya no existe.\nPudo haber sido eliminado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final map = mapProv.stationMap;
    PositionPhysical? position;
    List<HosePhysical> hoses = <HosePhysical>[];
    if (map != null) {
      final sameFace = map.values.where(
        (p) => p.pumpId == widget.pumpId && p.faceIndex == widget.faceIndex,
      );
      if (sameFace.isNotEmpty) {
        final list = sameFace.toList()
          ..sort((a, b) => a.number.compareTo(b.number));
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
    final subtitleText = position?.pumpName ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titleText,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
            onPressed: _loadingInFlight ? null : _refreshMap,
          ),
        ],
      ),
      body: mapProv.isLoading && map == null
          ? const Center(
              child: LoaderComponent(loadingText: 'Cargando mangueras...'))
          : map == null
              ? _NoPositionSelected(
                  message:
                      'No pudimos cargar las posiciones. Intenta actualizar.',
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
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                                      dispatch.selectHose(
                                          pos: position, hose: hose);
                                      despachosProv.refresh();

                                      final fuelName =
                                          hose.fuel.name.toLowerCase();
                                      final isExonerado =
                                          fuelName.contains('exo');

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UnifiedPresetPage(
                                            dispatchId: widget.dispatchId,
                                            initialMode: isExonerado
                                                ? PresetMode.volume
                                                : PresetMode.amount,
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
                                childAspectRatio:
                                    0.85, // More vertical for hero style
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
  const _HoseCard(
      {required this.hose, this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _hoseStatusLabel(hose.status);
    final statusColor = _hoseStatusColor(statusLabel);
    final statusIcon = _hoseStatusIcon(statusLabel);

    final fuelColor = hose.fuel.color;
    // Determine text color for the fuel name based on background brightness
    final onFuelColor =
        ThemeData.estimateBrightnessForColor(fuelColor) == Brightness.light
            ? Colors.black
            : Colors.white;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: fuelColor.withValues(alpha: 0.5), width: 1.5),
      ),
      color: const Color(0xFF1E1E1E), // Darker card base
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            // Dominant Color Block for Fuel (65% height)
            Expanded(
              flex: 65,
              child: Container(
                width: double.infinity,
                color: enabled ? fuelColor : fuelColor.withValues(alpha: 0.4),
                child: Stack(
                  children: [
                    // Subtle background icon
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.local_gas_station,
                        size: 80,
                        color: onFuelColor.withValues(alpha: 0.1),
                      ),
                    ),
                    Center(
                      child: Text(
                        hose.fuel.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onFuelColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Information/Status Section (35% height)
            Expanded(
              flex: 35,
              child: Container(
                width: double.infinity,
                color: Colors.white, // High contrast for field use
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'M-${hose.nozzleNumber}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusColor.withValues(alpha: 0.8).withValues(
                            alpha: 1,
                            blue: statusColor.blue * 0.7,
                            green: statusColor.green * 0.7,
                            red: statusColor.red *
                                0.7), // Darker version for white background
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      return Icons.check_circle_rounded;
    case 'autorizada':
      return Icons.verified_rounded;
    case 'despachando':
      return Icons.flash_on_rounded;
    case 'ocupada':
      return Icons.lock_rounded;
    case 'detenida':
      return Icons.stop_circle_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}
