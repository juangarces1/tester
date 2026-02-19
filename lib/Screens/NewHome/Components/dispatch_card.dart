import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';

import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Peddlers/peddlers_add_screen.dart';
import 'package:tester/Screens/checkout/checkount.dart';
import 'package:tester/Screens/credito/credit_process_screen.dart';
import 'package:tester/Screens/tickets/ticket_screen.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class DispatchCard extends StatefulWidget {
  const DispatchCard({super.key, required this.d});
  final AltDispatchControl d;

  @override
  State<DispatchCard> createState() => _DispatchCardState();
}

class _DispatchCardState extends State<DispatchCard>
    with TickerProviderStateMixin {
  // ----------------- helpers visuales -----------------
  Color _statusColor(AltDispatchControl dc) {
    if (dc.stage == DispatchStage.readyToAuthorize && dc.authorizationExpired) {
      return Colors.red; // o un ámbar si prefieres
    }
    final s = dc.hoseStatusEnum;
    switch (dc.stage) {
      case DispatchStage.authorizing:
        return Colors.teal.shade700;
      case DispatchStage.authorized:
        return Colors.green;
      case DispatchStage.dispatching:
        return Colors.blue;
      case DispatchStage.completed:
        return Colors.orange;
      case DispatchStage.unpaid:
        return Colors.purple;
      default:
        {
          return switch (s) {
            HoseStatus.available => Colors.teal,
            HoseStatus.authorized => Colors.teal,
            HoseStatus.fueling => Colors.blue,
            HoseStatus.busy => Colors.grey,
            HoseStatus.stopped => Colors.grey,
            HoseStatus.unpaid => Colors.orange,
            HoseStatus.finished => Colors.purple,
            _ => Colors.blueGrey,
          };
        }
    }
  }

  String _statusLabel(AltDispatchControl dc) {
    if (dc.stage == DispatchStage.readyToAuthorize && dc.authorizationExpired) {
      return 'Expiró';
    }
    final s = dc.hoseStatusEnum;
    switch (dc.stage) {
      case DispatchStage.authorizing:
        return 'Autorizando…';
      case DispatchStage.authorized:
        return 'Autorizado';
      case DispatchStage.dispatching:
        return 'Despachando';
      case DispatchStage.completed:
        return 'Completado';
      case DispatchStage.unpaid:
        return 'Sin pagar';
      default:
        {
          return switch (s) {
            HoseStatus.available => 'Disponible',
            HoseStatus.authorized => 'Autorizado',
            HoseStatus.fueling => 'Despachando',
            HoseStatus.busy => 'Cerrando…',
            HoseStatus.stopped => 'Detenida',
            HoseStatus.unpaid => 'Sin pagar',
            HoseStatus.finished => 'Finalizado',
            _ => '—',
          };
        }
    }
  }

  String _fmtMoney(num? v) =>
      v == null ? '—' : VariosHelpers.formattedToCurrencyValue(v.toString());

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.d,
      builder: (_, __) {
        final color = _statusColor(widget.d);
        final label = _statusLabel(widget.d);

        return Card(
          color: const Color(0xFF151515),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      // avatar combustible
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: widget.d.fuel?.color ?? Colors.white24,
                        child: const Icon(Icons.local_gas_station,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.d.fuel?.name ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.d.selectedPosition != null &&
                                      widget.d.selectedHose != null
                                  ? 'POS ${widget.d.selectedPosition!.number} · MANG ${widget.d.selectedHose!.nozzleNumber}'
                                  : '—',
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
                          key: ValueKey(
                              '${widget.d.stage}-${widget.d.hoseStatus}'),
                          label: Text(
                            label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          backgroundColor: color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 8),

                  // ───────── RESUMEN PRESET / TANQUE (CONDICIONAL) ─────────
                  if (widget.d.stage == DispatchStage.authorizing ||
                      widget.d.stage == DispatchStage.authorized ||
                      widget.d.stage == DispatchStage.readyToAuthorize ||
                      widget.d.stage == DispatchStage.dispatching) ...[
                    Row(
                      children: [
                        Icon(
                          widget.d.tankFull
                              ? Icons.water_drop
                              : (widget.d.preset.isVolume
                                  ? Icons.local_gas_station
                                  : Icons.attach_money),
                          size: 24,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.d.tankFull
                                ? 'Tanque lleno'
                                : (widget.d.preset.isVolume
                                    ? 'Preset: ${(widget.d.preset.volume ?? 0).toStringAsFixed(2)} L'
                                    : 'Preset: ${_fmtMoney((widget.d.preset.amount ?? 0))}'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ---------- ESTADO DE DESPACHO ----------
                  if (widget.d.stage == DispatchStage.dispatching)
                    _dispatchingIndicator(),

                  // ---------- SINCRONIZACIÓN / RESUMEN FINAL ----------
                  if (widget.d.stage == DispatchStage.unpaid ||
                      widget.d.stage == DispatchStage.completed)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: widget.d.loadingLastSale
                          ? _syncIndicator('Sincronizando con consola...')
                          : widget.d.persistingTx
                              ? _syncIndicator('Esperando confirmación...')
                              : _finalSummary(widget.d),
                    ),

                  const SizedBox(height: 12),

                  // ---------- FACTURACIÓN (editable en paralelo) + ACCIONES ----------
                  Row(
                    children: [
                      if (widget.d.canEditInvoiceType) ...[
                        _invoiceTypePill(context),
                        const SizedBox(width: 12),
                      ],
                      // Botón de finalizar despacho (solo visible antes de despachar)
                      if (widget.d.stage == DispatchStage.readyToAuthorize ||
                          widget.d.stage == DispatchStage.authorizing ||
                          widget.d.stage == DispatchStage.authorized)
                        IconButton(
                          onPressed: () => _confirmEndDispatch(context),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.redAccent,
                          tooltip: 'Finalizar despacho',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.15),
                          ),
                        ),
                      Expanded(child: Container()),
                      // Botones contextuales mínimos
                      if (widget.d.stage == DispatchStage.authorizing)
                        _miniBtn(context, icon: Icons.close, label: 'Cancelar',
                            onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Cancelar autorización (pendiente de implementar)')),
                          );
                        }),
                      if (widget.d.stage == DispatchStage.dispatching)
                        _miniBtn(context, icon: Icons.stop, label: 'Detener',
                            onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Detener despacho (pendiente de implementar)')),
                          );
                        }),
                      if (widget.d.stage == DispatchStage.completed ||
                          widget.d.stage == DispatchStage.unpaid)
                        _miniBtn(context,
                            icon: Icons.receipt_long,
                            label: 'Facturar', onTap: () {
                          _goFacturacion(widget.d);
                        }),

                      if (widget.d.stage == DispatchStage.completed ||
                          widget.d.stage == DispatchStage.unpaid)
                        _miniBtn(context,
                            icon: Icons.settings, label: 'Procesar', onTap: () {
                          widget.d.markCompleted();
                        }),

                      // _miniBtn(
                      //   context,
                      //   icon: Icons.warning_amber_rounded,
                      //   label: 'Forzar Sin pagar',
                      //   onTap: () {
                      //     widget.d.markUnpaid();
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('markUnpaid() ejecutado')),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                  if (widget.d.canRetry)
                    _miniBtn(
                      context,
                      icon: Icons.refresh,
                      label: 'Reintentar',
                      onTap: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reintentando autorización…')),
                        );
                        final ok = await widget.d.retryAuthorize();

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(ok
                                  ? 'Autorizado nuevamente ✅'
                                  : 'No se pudo autorizar ❌')),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _finalSummary(AltDispatchControl d) {
    // Preferimos la transacción de consola si ya está sincronizada
    final tx = d.consoleTx;

    final volume = tx?.totalVolume ?? d.consoleTx?.totalVolume ?? 0;
    final total = tx?.totalValue ?? d.consoleTx?.totalValue ?? 0;
    final unit = tx?.unitPrice ?? d.price ?? 0;

    final isSync = tx != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSync ? Icons.check_circle : Icons.sync,
                color: isSync ? Colors.greenAccent : Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isSync ? 'Sincronizado con consola' : 'Sincronizando valores…',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
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
              if (tx?.saleNumber != null && tx!.saleNumber != 0)
                _pill('Venta #${tx.saleNumber}'),
              if (tx?.nozzleNumber != null) _pill('M${tx!.nozzleNumber}'),
              if (tx?.duration != null) _pill('Duración ${tx!.duration}s'),
              if (tx?.fuelCode != null && tx!.fuelCode != 0)
                _pill('Prod ${tx.fuelCode}'),
              if (d.tankFull) _pill('Tanque lleno'),
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

  Widget _dispatchingIndicator() {
    final hose = widget.d.selectedHose;
    final amount = hose?.totalAmount ?? 0;
    final volume = hose?.totalVolume ?? 0;
    final tag = hose?.tagId;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
          // Valores en vivo
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
                color: Colors.blue.withOpacity(0.2),
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

  Widget _invoiceTypePill(
    BuildContext context,
  ) {
    final current = widget.d.invoiceType?.name.toUpperCase() ?? 'TIPO';
    return InkWell(
      onTap: () => _pickInvoiceType(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: current == 'TIPO'
              ? Colors.deepPurple
              : widget.d.invoiceType!.color,
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
      widget.d.setInvoiceType(result);
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

  /// Muestra un diálogo de confirmación para finalizar el despacho
  Future<void> _confirmEndDispatch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Finalizar despacho',
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
            child: const Text('Sí, finalizar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final dispenserId = widget.d.selectedPosition?.number;
    if (dispenserId == null) {
      Fluttertoast.showToast(msg: 'No hay dispensador seleccionado');
      return;
    }

    // El nuevo API no expone un endpoint de finalización manual.
    // El estado se actualiza automáticamente vía SignalR.
    widget.d.markCompleted();
    Fluttertoast.showToast(msg: 'Despacho finalizado ✅');
  }

  void _goFacturacion(AltDispatchControl control) async {
    final type = control.invoiceType;
    final tx = control.tx;

    // CASO ESPECIAL: producto exonerado (idproducto == 4)
    // ==========================================================
    if (tx?.idproducto == 4) {
      try {
        // Actualiza el estado a Exonerado en el backend (si aplica)
        final cp = Provider.of<CierreActivoProvider>(context, listen: false);

        //Si la transaccion es de exonerado no se factura se procesa y se marcha completado el despacho

        tx!.estado = "Exonerado";
        tx.idcierre = cp.cierreFinal!.idcierre!;
        Response response = await ApiHelper.put(
            "TransaccionesApi", tx.idtransaccion.toString(), tx.toJson());

        if (!response.isSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error al exonerar transacción: ${response.message}')),
          );
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción exonerada exitosamente')),
          );
          control.markCompleted();
          return;
        }

        // Finaliza el proceso visualmente
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exonerar transacción: $e')),
        );
      }
      return;
    }

    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona el tipo de factura para continuar')),
      );
      return;
    }
    if (tx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay transacción para facturar')),
      );
      return;
    }

    // 1) Crear factura base (sin agregar aún)
    final factProv = context.read<FacturasProvider>();
    final cierreFinal = context.read<CierreActivoProvider>().cierreFinal;
    final empleado = context.read<CierreActivoProvider>().usuario;

    final invoice = factProv.newInvoice(
        type: type, cliente: null, cierre: cierreFinal, empleado: empleado);

    // Asegura lista mutable
    invoice.detail = (invoice.detail ?? const <Product>[]).toList();

    Response response =
        await ApiHelper.getTransaccionAsProductById(tx.idtransaccion);

    if (!mounted) return;

    if (!response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al obtener producto: ${response.message}')),
      );
      return;
    }

    final prod = response.result as Product;

    invoice.detail!.add(prod);

    // 5) Reaplicar flags por si tu modelo usa booleans
    type.applyFlagsTo(invoice);

    // 6) Agregar al provider y obtener índice
    final index = factProv.addInvoice(invoice);
    widget.d.markCompleted();
    // 7) Navegar pasando índice + control
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => type.screenForWith(index: index, control: control)),
    );
  }
}

extension InvoiceTypeNav on InvoiceType {
  Widget screenForWith({
    required int index,
    required AltDispatchControl control,
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
