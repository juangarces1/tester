import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/Components/overlay/app_overlay.dart';
import 'package:tester/Components/state/state_widgets.dart';
import 'package:tester/fuelred/fuelred_provider.dart';

/// Tab FuelRed P4S — muestra transacciones esperando + despachos autorizados.
class FuelRedPage extends StatelessWidget {
  const FuelRedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateView<FuelRedProvider>(
      onLoading: () => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: ShimmerList(itemCount: 3, cardHeight: 120),
      ),
      onEmpty: () => const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Sin ordenes FuelRed',
        subtitle: 'Cuando un chofer P4S llegue a la estacion\naparecera aqui',
      ),
      onError: (msg, retry) => ErrorCard(
        message: msg,
        onRetry: () => context.read<FuelRedProvider>().syncFromRest(),
      ),
      onContent: (prov) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildActionHub(context, prov)),
          if (prov.waitingTransactions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Esperando verificacion',
                prov.waitingCount,
                const Color(0xFFFF9100),
              ),
            ),
            SliverList.separated(
              itemCount: prov.waitingTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildWaitingCard(context, prov, prov.waitingTransactions[i]),
            ),
          ],
          if (prov.pendingDispatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Despachos autorizados',
                prov.pendingCount,
                const Color(0xFF00E676),
              ),
            ),
            SliverList.separated(
              itemCount: prov.pendingDispatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildDispatchCard(context, prov, prov.pendingDispatches[i]),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION HUB — con diagnóstico de conexión
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionHub(BuildContext context, FuelRedProvider prov) {
    final wsColor =
        prov.wsConnected ? const Color(0xFF00E676) : const Color(0xFFFF1744);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kNewborder,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF3B3B).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Ícono P4S
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B3B), Color(0xFFE02020)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            // Título + conteos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FuelRed P4S',
                    style: TextStyle(
                      color: kContrateFondoOscuro,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${prov.waitingCount} esperando · ${prov.pendingCount} pendientes',
                    style: TextStyle(
                      color: kNewtextSec.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Indicador WS compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: wsColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: wsColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    prov.wsConnected ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: wsColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, int count, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: kContrateFondoOscuro,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WAITING CARD (Sello 1 ok, esperando verificación de vehículo)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWaitingCard(
      BuildContext context, FuelRedProvider prov, Map<String, dynamic> tx) {
    final driverName = tx['driver_name'] as String? ?? 'Chofer';
    final pumpLabel = tx['pump_label'] as String? ?? '—';
    final txId = tx['transaction_id'] as int? ?? tx['id'] as int? ?? 0;
    final createdAt = tx['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: kNewborder,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRfidScanSheet(context, prov, tx),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF9100).withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Ícono naranja (esperando)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFFFF9100),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                color: kContrateFondoOscuro,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pumpLabel • TX #$txId',
                              style: const TextStyle(
                                color: kNewtextSec,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tiempo
                      if (createdAt.isNotEmpty)
                        Text(
                          _timeAgo(createdAt),
                          style: const TextStyle(
                            color: kNewtextSec,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botón de acción
                  Material(
                    color: const Color(0xFFFF9100).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nfc_rounded,
                              size: 18, color: Color(0xFFFF9100)),
                          SizedBox(width: 8),
                          Text(
                            'Escanear RFID del vehículo',
                            style: TextStyle(
                              color: Color(0xFFFF9100),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RFID SCAN BOTTOM SHEET (Sello 2+3)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showRfidScanSheet(
      BuildContext context, FuelRedProvider prov, Map<String, dynamic> tx) {
    final txId = tx['transaction_id'] as int? ?? tx['id'] as int? ?? 0;
    final driverName = tx['driver_name'] as String? ?? 'Chofer';
    final pumpLabel = tx['pump_label'] as String? ?? '—';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kNewborder,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _RfidScanSheet(
        txId: txId,
        driverName: driverName,
        pumpLabel: pumpLabel,
        prov: prov,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPATCH CARD (Sello 4 ok, despacho autorizado)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDispatchCard(
      BuildContext context, FuelRedProvider prov, Map<String, dynamic> d) {
    final driverName = d['driver_name'] as String? ?? 'Chofer';
    final plate = d['plate'] as String? ?? '—';
    final pumpLabel = d['pump_label'] as String? ?? '—';
    final hoseLabel = d['hose_label'] as String? ?? '—';
    final fuelType = d['fuel_type'] as String? ?? '—';
    final amount = d['amount'] as num? ?? 0;
    final liters = d['liters'] as num? ?? 0;
    final txId = d['transaction_id'] as int? ?? d['id'] as int? ?? 0;
    final status = d['dispatch_status'] as String? ?? 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: kNewborder,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: Color(0xFF00E676),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$driverName • $plate',
                          style: const TextStyle(
                            color: kContrateFondoOscuro,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$pumpLabel → $hoseLabel • $fuelType',
                          style: const TextStyle(
                            color: kNewtextSec,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),

              const SizedBox(height: 12),

              // Métricas
              Row(
                children: [
                  _buildMetric('Litros', liters.toStringAsFixed(1)),
                  const SizedBox(width: 16),
                  _buildMetric('Monto', '₡${_formatNumber(amount)}'),
                  const SizedBox(width: 16),
                  _buildMetric('TX', '#$txId'),
                ],
              ),

              const SizedBox(height: 12),

              // Botones de acción según estado
              _buildActions(context, prov, txId, status, d),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: kNewtextSec, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: kContrateFondoOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, FuelRedProvider prov, int txId, String status,
      Map<String, dynamic> dispatch) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _AuthorizeButton(prov: prov, dispatch: dispatch),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                label: 'Cancelar',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFFF1744),
                onTap: () => _confirmCancel(context, prov, txId),
              ),
            ),
          ],
        );
      case 'acknowledged':
        return Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Iniciar despacho',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF00E676),
                onTap: () => prov.startDispatch(txId),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                label: 'Cancelar',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFFF1744),
                onTap: () => _confirmCancel(context, prov, txId),
              ),
            ),
          ],
        );
      case 'dispensing':
        return _actionButton(
          label: 'Despachando... (completar desde consola)',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFFF9100),
          onTap: null,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  void _confirmCancel(
      BuildContext context, FuelRedProvider prov, int txId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNewborder,
        title: const Text('Cancelar despacho',
            style: TextStyle(color: kContrateFondoOscuro)),
        content: const Text('¿Seguro que desea cancelar este despacho FuelRed?',
            style: TextStyle(color: kNewtextSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              prov.cancelDispatch(
                  dispatchId: txId, reason: 'Cancelado por estación');
            },
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Color(0xFFFF1744))),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  String _formatNumber(num value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  ({String label, Color color}) _statusConfig(String status) {
    return switch (status) {
      'pending' => (label: 'Pendiente', color: const Color(0xFFFF9100)),
      'acknowledged' => (label: 'Recibido', color: const Color(0xFF29B6F6)),
      'dispensing' => (label: 'Despachando', color: const Color(0xFF00E676)),
      'dispensed' => (label: 'Completado', color: const Color(0xFF00C853)),
      'cancelled' => (label: 'Cancelado', color: const Color(0xFFFF1744)),
      _ => (label: status, color: const Color(0xFF8892A0)),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RFID SCAN SHEET — Escaneo NFC para verificación Sello 2+3
// ═══════════════════════════════════════════════════════════════════════════
enum _ScanPhase { idle, scanning, verifying, success, error }

class _RfidScanSheet extends StatefulWidget {
  const _RfidScanSheet({
    required this.txId,
    required this.driverName,
    required this.pumpLabel,
    required this.prov,
  });

  final int txId;
  final String driverName;
  final String pumpLabel;
  final FuelRedProvider prov;

  @override
  State<_RfidScanSheet> createState() => _RfidScanSheetState();
}

class _RfidScanSheetState extends State<_RfidScanSheet> {
  // idle → scanning → verifying → success → error
  _ScanPhase _phase = _ScanPhase.idle;
  String? _scannedUid;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Iniciar escaneo automáticamente al abrir
    _startScan();
  }

  @override
  void dispose() {
    FlutterNfcKit.finish().catchError((_) {});
    super.dispose();
  }

  String _formatUid(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
  }

  Future<void> _startScan() async {
    if (_phase == _ScanPhase.scanning || _phase == _ScanPhase.verifying) return;
    setState(() {
      _phase = _ScanPhase.scanning;
      _errorMessage = null;
    });

    try {
      final ava = await FlutterNfcKit.nfcAvailability;
      if (ava != NFCAvailability.available) {
        setState(() {
          _phase = _ScanPhase.error;
          _errorMessage = 'NFC no disponible en este dispositivo';
        });
        return;
      }

      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
        androidPlatformSound: true,
      );

      final uid = _formatUid(tag.id);
      await FlutterNfcKit.finish();

      if (uid.isEmpty) {
        setState(() {
          _phase = _ScanPhase.error;
          _errorMessage = 'No se pudo leer el UID de la tarjeta';
        });
        return;
      }

      try { await HapticFeedback.selectionClick(); } catch (_) {}
      setState(() {
        _scannedUid = uid;
        _phase = _ScanPhase.verifying;
      });

      await _verifyVehicle(uid);
    } catch (e) {
      await FlutterNfcKit.finish().catchError((_) {});
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.error;
        _errorMessage = e.toString().contains('timeout')
            ? 'Tiempo agotado — acerque la tarjeta RFID'
            : 'Error NFC: $e';
      });
    }
  }

  Future<void> _verifyVehicle(String rfidTag) async {
    // Obtener identificador del pistero (RFID tag o código de empleado)
    final cierreProv = context.read<CierreActivoProvider>();
    final pisteroCode = cierreProv.usuario?.attendantId ?? '';

    if (pisteroCode.isEmpty) {
      setState(() {
        _phase = _ScanPhase.error;
        _errorMessage = 'No se encontró identificador del pistero. Verifique su sesión.';
      });
      return;
    }

    try {
      final result = await widget.prov.verifyVehicle(
        transactionId: widget.txId,
        rfidTag: rfidTag,
        pisteroCode: pisteroCode,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() => _phase = _ScanPhase.success);
        // Re-sync para que la lista se actualice
        widget.prov.syncFromRest();
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _phase = _ScanPhase.error;
          _errorMessage = 'Vehículo no reconocido o no asignado a esta flotilla';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.error;
        _errorMessage = 'Error al verificar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kNewtextSec.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Info de la transacción
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFFFF9100), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.driverName,
                        style: const TextStyle(
                          color: kContrateFondoOscuro,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.pumpLabel} • TX #${widget.txId}',
                        style: const TextStyle(color: kNewtextSec, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Estado del escaneo
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildScanState(),
            ),

            const SizedBox(height: 24),

            // Botón de acción
            if (_phase == _ScanPhase.error || _phase == _ScanPhase.idle)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.nfc_rounded),
                  label: const Text('Reintentar escaneo',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: _startScan,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanState() {
    return switch (_phase) {
      _ScanPhase.scanning => Column(
          key: const ValueKey('scan_scanning'),
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9100)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acerque la tarjeta RFID',
              style: TextStyle(
                color: kContrateFondoOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Escanee el RFID del parabrisas del vehículo',
              style: TextStyle(color: kNewtextSec, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      _ScanPhase.verifying => Column(
          key: const ValueKey('scan_verifying'),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_rounded,
                  color: Color(0xFF29B6F6), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificando vehículo...',
              style: TextStyle(
                color: kContrateFondoOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (_scannedUid != null) ...[
              const SizedBox(height: 6),
              Text(
                'RFID: $_scannedUid',
                style: const TextStyle(
                    color: kNewtextSec,
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      _ScanPhase.success => Column(
          key: const ValueKey('scan_success'),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF00E676), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vehículo verificado',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Esperando autorización del chofer (Sello 4)...',
              style: TextStyle(color: kNewtextSec, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      _ScanPhase.error => Column(
          key: const ValueKey('scan_error'),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF1744), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(
                color: Color(0xFFFF1744),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      _ScanPhase.idle => Column(
          key: const ValueKey('scan_idle'),
          children: [
            Icon(Icons.nfc_rounded,
                size: 64, color: kNewtextSec.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Listo para escanear',
              style: TextStyle(
                color: kContrateFondoOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTHORIZE BUTTON — StatefulWidget para manejar loading
// ═══════════════════════════════════════════════════════════════════════════
class _AuthorizeButton extends StatefulWidget {
  const _AuthorizeButton({required this.prov, required this.dispatch});
  final FuelRedProvider prov;
  final Map<String, dynamic> dispatch;

  @override
  State<_AuthorizeButton> createState() => _AuthorizeButtonState();
}

class _AuthorizeButtonState extends State<_AuthorizeButton> {
  bool _loading = false;

  Future<void> _authorize() async {
    setState(() => _loading = true);
    try {
      final ok = await widget.prov.authorizeDispatch(
        context: context,
        dispatch: widget.dispatch,
      );
      if (!mounted) return;
      if (ok) {
        AppOverlay.success(context, 'Despacho autorizado — movido a Despachos');
      } else {
        AppOverlay.error(context, 'Error al autorizar despacho');
      }
    } catch (e) {
      if (!mounted) return;
      AppOverlay.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF00E676).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _loading ? null : _authorize,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: _loading
                ? [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Autorizando...',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                : [
                    const Icon(Icons.play_circle_fill_rounded,
                        size: 18, color: Color(0xFF00E676)),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Autorizar',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
