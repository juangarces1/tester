import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/Screens/NewHome/PagesWizard/position_hoses_page.dart';

class FacesListPage extends StatefulWidget {
  const FacesListPage({super.key});

  @override
  State<FacesListPage> createState() => _FacesListPageState();
}

class _FacesListPageState extends State<FacesListPage> {
  bool _loadingInFlight = false;
  bool _isFirstEntry = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMap());
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Con SignalR el mapa se actualiza automáticamente vía push.
  /// Este método ya no hace polling; solo resetea el flag de primera entrada.
  Future<void> _refreshMap() async {
    if (_loadingInFlight) return;

    final mapProv = context.read<MapProvider>();
    if (!mapProv.isConnected) {
      // Reintentar conexión si está desconectado o hubo error
      await mapProv.connect();
    }

    setState(() {
      _loadingInFlight = false;
      _isFirstEntry = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();

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
      backgroundColor: const Color(0xFF121212), // Material Deep Grey
      appBar: AppBar(
        title: const Text('Selecciona posición',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: _isFirstEntry && mapProv.isLoading
          ? const Center(
              child: LoaderComponent(loadingText: 'Cargando mapa...'))
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
                            SizedBox(height: 110),
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
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.95, // Reverted to compact size
                          ),
                          itemCount: positions.length,
                          itemBuilder: (_, index) {
                            final position = positions[index];
                            final status = _statusLabel(position);
                            // Permitir selección si está disponible O si aún
                            // no llegó el primer ReceiveStatus del hub (unknown/sin datos)
                            final isAvailable =
                                status.toLowerCase() == 'disponible' ||
                                    status.toLowerCase() == 'bloqueada' ||
                                    status.toLowerCase() == 'sin datos';
                            return _PositionCard(
                              position: position,
                              enabled: isAvailable,
                              onTap: () {
                                if (!isAvailable) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PositionHosesPage(
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
  final bool enabled;
  const _PositionCard({
    required this.position,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(position);
    final isFueling = status == 'Despachando';

    // Si está despachando, buscamos la manguera activa para usar su color
    Color baseColor = _statusColor(status);
    if (isFueling) {
      final fuelingHose = position.hoses.firstWhere(
        (h) => h.status.toLowerCase().contains('fuel'),
        orElse: () => position.hoses.first,
      );
      baseColor = fuelingHose.fuel.color;
    }

    // Dynamic contrast for text on baseColor
    final onBaseColor =
        ThemeData.estimateBrightnessForColor(baseColor) == Brightness.light
            ? Colors.black87
            : Colors.white;

    // Darker version for text on white background
    final darkStatusColor = isFueling
        ? baseColor.withValues(alpha: 0.9)
        : status == 'Disponible'
            ? const Color(0xFF1B5E20) // Deep Green
            : const Color(0xFF1A237E); // Deep Blue

    final availableCount = position.hoses
        .where((h) => h.status.toLowerCase() == 'available')
        .length;

    String infoText = 'Mangueras: $availableCount';
    if (isFueling) {
      final fuelingHose = position.hoses.firstWhere(
        (h) => h.status.toLowerCase().contains('fuel'),
        orElse: () => position.hoses.first,
      );
      infoText = fuelingHose.fuel.name;
    }

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: enabled
                ? baseColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5),
      ),
      color: const Color(0xFF1E1E1E),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            // Dominant Color Block (65%)
            Expanded(
              flex: 62,
              child: Container(
                width: double.infinity,
                color: baseColor,
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        _statusIcon(status),
                        size: 80,
                        color: onBaseColor.withValues(alpha: 0.12),
                      ),
                    ),
                    Center(
                      child: Text(
                        'D ${position.number.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: onBaseColor,
                          fontSize: 50, // Increased by ~15% (from 42)
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Status/Info Footer (35%)
            Expanded(
              flex: 38,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: darkStatusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isFueling) ...[
                      const SizedBox(height: 1),
                      Text(
                        infoText.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: darkStatusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

  // Prioridad de estados (el más crítico define la tarjeta)
  if (normalized.any((s) => s.contains('error'))) return 'Error';
  if (normalized.any((s) => s.contains('blocked'))) return 'Bloqueada';
  if (normalized.any((s) => s.contains('calling'))) return 'Llamando';
  if (normalized.any((s) => s.contains('fuel'))) return 'Despachando';
  if (normalized.any((s) => s.contains('author'))) return 'Autorizada';
  if (normalized.any((s) => s.contains('busy'))) return 'Ocupada';
  if (normalized.any((s) => s.contains('waiting'))) return 'Esperando';
  if (normalized.any((s) => s.contains('stopped'))) return 'Detenida';
  if (normalized.any((s) => s.contains('available'))) return 'Disponible';

  // Estado inicial o fallbacks
  if (normalized.isEmpty || normalized.every((s) => s == 'unknown')) {
    return 'Sin datos';
  }
  if (normalized.every((s) => s == 'unavailable')) {
    return 'No Configurada';
  }

  final raw = normalized.first;
  return raw[0].toUpperCase() + raw.substring(1);
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'disponible':
      return Colors.greenAccent;
    case 'autorizada':
      return Colors.cyanAccent;
    case 'despachando':
      return Colors.blue; // Azul puro
    case 'ocupada':
      return Colors.orangeAccent;
    case 'detenida':
      return Colors.blueGrey;
    case 'bloqueada':
      return Colors.indigoAccent;
    case 'llamando':
      return Colors
          .lightBlueAccent; // Podría parpadear en una implementación futura
    case 'esperando':
      return Colors.amber;
    case 'error':
      return Colors.red;
    case 'no configurada':
      return Colors.grey.shade800;
    case 'sin datos':
      return Colors.grey.shade700;
    default:
      return Colors.white70;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'disponible':
      return Icons.check_circle_rounded;
    case 'autorizada':
      return Icons.verified_rounded;
    case 'despachando':
      return Icons.local_gas_station_rounded;
    case 'ocupada':
      return Icons.lock_clock_rounded;
    case 'detenida':
      return Icons.stop_circle_rounded;
    case 'bloqueada':
      return Icons.lock_outline_rounded;
    case 'llamando':
      return Icons.front_hand_rounded; // Mano levantada
    case 'esperando':
      return Icons.hourglass_top_rounded;
    case 'error':
      return Icons.error_rounded;
    case 'no configurada':
      return Icons.desktop_access_disabled_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}
