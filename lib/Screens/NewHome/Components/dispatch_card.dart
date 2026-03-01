import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Models/FuelRed/product.dart';

import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/experimental/active_dispatch_manager.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';
import 'package:tester/Screens/Peddlers/peddlers_add_screen.dart';
import 'package:tester/Screens/checkout/checkount.dart';
import 'package:tester/Screens/credito/credit_process_screen.dart';
import 'package:tester/Screens/tickets/ticket_screen.dart';

import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class DispatchCard extends StatefulWidget {
  const DispatchCard({super.key, required this.d});
  final DispatchSession d;

  @override
  State<DispatchCard> createState() => _DispatchCardState();
}

class _DispatchCardState extends State<DispatchCard> {
  // ----------------- helpers visuales basados en NozzleStatus -----------------
  Color _statusColor(NozzleStatus status, DispatchSession d) {
    // Prioridad: estado derivado de la sesión > estado crudo de SignalR
    if (d.needsSettlement) return Colors.purple;
    if (d.isCompleted) return Colors.orange;
    if (d.canRetryOrDiscard) return Colors.deepOrange;

    switch (status) {
      case NozzleStatus.fueling:
        return Colors.blue;
      case NozzleStatus.ready:
        return Colors.teal.shade700;
      case NozzleStatus.waiting:
        return Colors.amber;
      case NozzleStatus.error:
      case NozzleStatus.failure:
        return Colors.red;
      case NozzleStatus.busy:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(NozzleStatus status, DispatchSession d) {
    if (d.needsSettlement) return 'Sin pagar';
    if (d.isCompleted) return 'Completado';
    if (d.canRetryOrDiscard) return 'Cancelada';

    switch (status) {
      case NozzleStatus.available:
        return 'Libre';
      case NozzleStatus.blocked:
        return 'Bloqueada';
      case NozzleStatus.fueling:
        return 'Despachando';
      case NozzleStatus.ready:
        return 'Pronto';
      case NozzleStatus.waiting:
        return 'Esperando';
      case NozzleStatus.error:
      case NozzleStatus.failure:
        return 'Error';
      case NozzleStatus.busy:
        return 'Ocupada';
      case NozzleStatus.notConfigured:
        return 'Sin config';
      case NozzleStatus.unknown:
        return 'Desconocido';
    }
  }

  String _fmtMoney(num? v) =>
      v == null ? '—' : VariosHelpers.formattedToCurrencyValue(v.toString());

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final d = widget.d;
    final status = d.currentStatus;
    final mVolume = mapProv.getLiters(d.nozzleCode) ?? 0.0;
    final mAmount = mapProv.getCash(d.nozzleCode) ?? 0.0;
    final mTag = mapProv.getTag(d.nozzleCode) ?? '';

    final color = _statusColor(status, d);
    final label = _statusLabel(status, d);

    return Card(
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: d.fuel.color,
                    child: const Icon(Icons.local_gas_station,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.fuel.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'POS ${d.position.number} · MANG ${d.nozzleCode}',
                          style: const TextStyle(
                              color: Color.fromARGB(227, 255, 255, 255),
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Chip(
                      key: ValueKey('${status.name}-${d.hasFueled}'),
                      label: Text(
                        label,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      backgroundColor: color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 8),

              // ───────── RESUMEN PRESET / TANQUE ─────────
              if (d.isWaiting || d.isDispensing) ...[
                Row(
                  children: [
                    Icon(
                      d.isTankFull
                          ? Icons.water_drop
                          : (d.preset.isVolume
                              ? Icons.local_gas_station
                              : Icons.attach_money),
                      size: 24,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.isTankFull
                            ? 'Tanque lleno'
                            : (d.preset.isVolume
                                ? 'Preset: ${(d.preset.volume ?? 0).toStringAsFixed(2)} L'
                                : 'Preset: ${_fmtMoney((d.preset.amount ?? 0))}'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // ---------- ESTADO DE DESPACHO EN VIVO ----------
              if (d.isDispensing)
                _dispatchingIndicator(
                    amount: mAmount, volume: mVolume, tag: mTag),

              // ---------- SINCRONIZACIÓN / RESUMEN FINAL ----------
              if (d.needsSettlement || d.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: d.syncedProduct == null
                      ? _syncIndicator('Sincronizando con consola...')
                      : _finalSummary(d),
                ),

              const SizedBox(height: 12),

              // ---------- ACCIONES ----------
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Pill de facturación (solo si necesita cierre)
                  if (d.needsSettlement || d.isCompleted)
                    _invoiceTypePill(context),
                  // Botón de cancelar/descartar (antes de despachar o si no despachó)
                  if (d.canRetryOrDiscard || d.isWaiting)
                    IconButton(
                      onPressed: () => _confirmEndDispatch(context),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                      tooltip: 'Cancelar despacho',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                      ),
                    ),
                  // Reintentar si no despachó y la manguera volvió a reposo
                  if (d.canRetryOrDiscard)
                    _miniBtn(context, icon: Icons.refresh, label: 'Reintentar',
                        onTap: () {
                      _retryDispatch(context, d);
                    }),
                  // Detener despacho en curso
                  if (d.isDispensing)
                    _miniBtn(context, icon: Icons.stop, label: 'Detener',
                        onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Detener despacho (pendiente de integrar API de parada)')),
                      );
                    }),
                  // Facturar / Cerrar si necesita settlement
                  if (d.needsSettlement || d.isCompleted) ...[
                    _miniBtn(context,
                        icon: Icons.receipt_long, label: 'Facturar', onTap: () {
                      _goFacturacion(d);
                    }),
                    _miniBtn(context, icon: Icons.settings, label: 'Cerrar',
                        onTap: () {
                      context.read<ActiveDispatchManager>().finishSession(d.id);
                    }),
                  ],
                  // Error de hardware -> ofrecer reintentar
                  if (d.currentStatus == NozzleStatus.error ||
                      d.currentStatus == NozzleStatus.failure)
                    _miniBtn(context, icon: Icons.refresh, label: 'Reintentar',
                        onTap: () {
                      _retryDispatch(context, d);
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _finalSummary(DispatchSession d) {
    final prod = d.syncedProduct;
    if (prod == null) return const SizedBox.shrink();

    final volume = prod.cantidad;
    final total = prod.total;
    final unit = prod.precioUnit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Producto sincronizado',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _metricTile(
                      title: 'Volumen',
                      value: '${volume.toStringAsFixed(3)} L')),
              const SizedBox(width: 8),
              Expanded(
                  child: _metricTile(title: 'Total', value: _fmtMoney(total))),
              const SizedBox(width: 8),
              Expanded(
                  child: _metricTile(
                      title: 'Precio/L', value: unit.toStringAsFixed(0))),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (prod.transaccion > 0) _pill('Tx #${prod.transaccion}'),
              if (prod.dispensador > 0) _pill('Disp ${prod.dispensador}'),
              if (prod.detalle.isNotEmpty) _pill(prod.detalle),
              if (d.isTankFull) _pill('Tanque lleno'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      );

  Widget _metricTile({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dispatchingIndicator({
    required num amount,
    required num volume,
    required String? tag,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Despachando combustible...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _liveValueItem(
                  'Volumen',
                  '${volume.toStringAsFixed(3)} L',
                  Icons.local_gas_station,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _liveValueItem(
                  'Importe',
                  _fmtMoney(amount),
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          if (tag != null && tag.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nfc, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 6),
                  Text(
                    'TAG: $tag',
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
        ],
      ),
    );
  }

  Widget _liveValueItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _syncIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceTypePill(BuildContext context) {
    final current = widget.d.invoiceType.name.toUpperCase();
    return InkWell(
      onTap: () => _pickInvoiceType(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.d.invoiceType.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            Text(current,
                style: TextStyle(
                    color: current == 'PEDDLER' ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Icon(Icons.edit,
                color: current == 'PEDDLER' ? Colors.black : Colors.white,
                size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickInvoiceType(BuildContext context) async {
    final result = await showModalBottomSheet<InvoiceType>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        const items = InvoiceType.values;
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (_, i) {
              final it = items[i];
              return InkWell(
                onTap: () => Navigator.pop(context, it),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      it.name.toUpperCase(),
                      style: TextStyle(
                        color: it.color,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        widget.d.invoiceType = result;
      });
    }
  }

  Widget _miniBtn(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF2A2A2A),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _confirmEndDispatch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancelar autorización',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cancelar este despacho?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.2),
            ),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    context.read<ActiveDispatchManager>().finishSession(widget.d.id);
    Fluttertoast.showToast(msg: 'Despacho cancelado localmente');
  }

  void _goFacturacion(DispatchSession d) async {
    final type = d.invoiceType;
    final prod = d.syncedProduct;

    if (prod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay producto sincronizado para facturar')),
      );
      return;
    }

    // 1) Crear factura base
    final factProv = context.read<FacturasProvider>();
    final cierreFinal = context.read<CierreActivoProvider>().cierreFinal;
    final empleado = context.read<CierreActivoProvider>().usuario;

    final invoice = factProv.newInvoice(
        type: type, cliente: null, cierre: cierreFinal, empleado: empleado);

    invoice.detail = (invoice.detail ?? const <Product>[]).toList();

    // 2) Agregar el producto sincronizado directamente a la factura
    invoice.detail!.add(prod);

    type.applyFlagsTo(invoice);

    final index = factProv.addInvoice(invoice);

    d.markAsFinished();

    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => type.screenForWith(index: index, session: d)),
    );
  }

  Future<void> _retryDispatch(
      BuildContext context, DispatchSession session) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      ),
    );

    bool isSuccess = false;
    final nozzleCode = session.nozzleCode;
    final tagId = session.userIdentifier;

    try {
      if (session.isTankFull) {
        isSuccess = await ConsoleApiHelper.presetTankFull(
            nozzleCode: nozzleCode, tagId: tagId);
      } else if (session.preset.isVolume) {
        isSuccess = await ConsoleApiHelper.presetByVolume(
            nozzleCode: nozzleCode,
            liters: session.preset.volume!,
            tagId: tagId);
      } else if (session.preset.isAmount) {
        isSuccess = await ConsoleApiHelper.presetByAmount(
            nozzleCode: nozzleCode,
            amount: session.preset.amount!,
            tagId: tagId);
      }
    } catch (_) {
      isSuccess = false;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (isSuccess) {
      session.currentStatus = NozzleStatus.blocked;
      session.hasFueled = false;
      context.read<ActiveDispatchManager>().forceRefresh();
      Fluttertoast.showToast(
          msg: 'Despacho re-autorizado', backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: 'Fallo al reintentar, comunícate con la consola',
          backgroundColor: Colors.red);
    }
  }
}

extension InvoiceTypeNav on InvoiceType {
  Color get color {
    switch (this) {
      case InvoiceType.contado:
        return Colors.green;
      case InvoiceType.ticket:
        return Colors.blueAccent;
      case InvoiceType.credito:
        return Colors.redAccent;
      case InvoiceType.peddler:
        return Colors.amber;
    }
  }

  Widget screenForWith({
    required int index,
    required DispatchSession session,
  }) {
    switch (this) {
      case InvoiceType.contado:
        return CheaOutScreen(
          index: index,
        );
      case InvoiceType.ticket:
        return TicketScreen(
          index: index,
        );
      case InvoiceType.credito:
        return ProceeeCreditScreen(
          index: index,
        );
      case InvoiceType.peddler:
        return PeddlersAddScreen(
          index: index,
        );
    }
  }

  void applyFlagsTo(dynamic invoice) {
    invoice.isContado = this == InvoiceType.contado;
    invoice.isTicket = this == InvoiceType.ticket;
    invoice.isCredit = this == InvoiceType.credito;
    invoice.isPeddler = this == InvoiceType.peddler;
  }
}
