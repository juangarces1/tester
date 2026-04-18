import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Models/FuelRed/tranferview.dart';
import 'package:tester/Models/FuelRed/transparcial.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

class TransferScreen extends StatefulWidget {
  final int index;
  const TransferScreen({super.key, required this.index});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with TickerProviderStateMixin {
  List<Transferview> _transfers = [];
  final List<Transferview> _transferenciasAux = [];
  late final TabController _tab;
  late Invoice _factura;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _factura = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
    _fetch();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Response resp = await ApiHelper.getTransfes();
    if (!mounted) return;
    if (!resp.isSuccess) {
      setState(() {
        _loading = false;
        _error = resp.message;
      });
      return;
    }
    setState(() {
      _loading = false;
      _transfers = List<Transferview>.from(resp.result);
    });
    _syncSelected();
  }

  // Rehidrata el tab "Seleccionadas" si ya había transferencias aplicadas a la factura.
  void _syncSelected() {
    for (final p in _factura.formPago!.transfer.transfers) {
      _transferenciasAux.add(Transferview(
        id: p.id,
        saldo: p.saldo,
        cuenta: p.cuenta,
        numeroDeposito: p.numeroDeposito,
        cliente: p.cliente,
        monto: p.saldo,
        banco: p.banco,
      ));
      _transfers.removeWhere((t) => t.numeroDeposito == p.numeroDeposito);
    }
    setState(() {});
  }

  bool _sameClient(Transferview e) {
    final parciales = _factura.formPago!.transfer.transfers;
    if (parciales.isEmpty) return true;
    return parciales.last.cliente == e.cliente;
  }

  bool _nearZero(double v) => v > 0 && v <= 0.2;

  String _fmtMoney(num v) =>
      NumberFormat.currency(locale: 'es_CR', symbol: '¢', decimalDigits: 0)
          .format(v);

  void _select(Transferview e) {
    if (_factura.formPago!.transfer.saldoActual <= 0) {
      _toast('No hay saldo para agregar transferencias', err: true);
      return;
    }
    if (!_sameClient(e)) {
      _toast('Seleccione transferencias del mismo cliente', err: true);
      return;
    }
    final saldoFactura = _factura.formPago!.transfer.saldoActual;
    final saldoTr = e.saldo.toDouble();
    final diff = saldoTr - saldoFactura;
    final aplicado = diff > 0 ? saldoFactura : saldoTr;
    final resto = diff > 0 ? diff : 0.0;

    final parcial = TransParcial(
      id: e.id,
      saldo: resto.toInt(),
      aplicado: aplicado.toInt(),
      cuenta: e.cuenta,
      numeroDeposito: e.numeroDeposito,
      cliente: e.cliente,
      banco: e.banco,
    );

    setState(() {
      _factura.formPago!.transfer.transfers.add(parcial);
      FacturaService.updateFactura(context, _factura);
      _transferenciasAux.add(e);
      _transfers.remove(e);
      _tab.animateTo(1);
    });
  }

  void _unselect(int index) {
    setState(() {
      _transfers.add(_transferenciasAux[index]);
      _factura.formPago!.transfer.transfers.removeAt(index);
      _transferenciasAux.removeAt(index);
      FacturaService.updateFactura(context, _factura);
      _transfers.sort((a, b) => a.cliente.compareTo(b.cliente));
      _tab.animateTo(0);
    });
  }

  void _confirm() {
    if (_factura.formPago!.transfer.transfers.isEmpty) {
      _toast('Seleccione al menos una transferencia', err: true);
      return;
    }
    if (_nearZero(_factura.formPago!.transfer.saldoActual)) {
      _factura.formPago!.totalTransfer = _factura.saldo;
    } else {
      _factura.formPago!.totalTransfer =
          _factura.formPago!.transfer.totalAplicado;
    }
    FacturaService.updateFactura(context, _factura);
    Navigator.pop(context);
  }

  void _toast(String msg, {bool err = false}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: err ? const Color(0xFFD64045) : const Color(0xFF1BBF84),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final seleccionadas = _factura.formPago!.transfer.transfers.length;
    final saldoActual = _factura.formPago!.transfer.saldoActual;
    return Scaffold(
      floatingActionButton: seleccionadas > 0
          ? FloatingActionButton.extended(
              onPressed: _confirm,
              backgroundColor: kNewgreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Aplicar'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                saldoActual: saldoActual,
                seleccionadas: seleccionadas,
                disponibles: _transfers.length,
                tab: _tab,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _DisponiblesTab(
                      transfers: _transfers,
                      loading: _loading,
                      error: _error,
                      fmtMoney: _fmtMoney,
                      onTap: _select,
                      onRetry: _fetch,
                    ),
                    _SeleccionadasTab(
                      parciales: _factura.formPago!.transfer.transfers,
                      fmtMoney: _fmtMoney,
                      onDismiss: _unselect,
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

class _Header extends StatelessWidget {
  final double saldoActual;
  final int seleccionadas;
  final int disponibles;
  final TabController tab;

  const _Header({
    required this.saldoActual,
    required this.seleccionadas,
    required this.disponibles,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              children: [
                const _GlassBackButton(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferencias',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Aplicar saldos contra la factura',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _SaldoBadge(saldo: saldoActual),
              ],
            ),
          ),
          TabBar(
            controller: tab,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Disponibles ($disponibles)'),
              Tab(text: 'Seleccionadas ($seleccionadas)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaldoBadge extends StatelessWidget {
  final double saldo;
  const _SaldoBadge({required this.saldo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('SALDO',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          Text(
            NumberFormat.currency(
                    locale: 'es_CR', symbol: '¢', decimalDigits: 0)
                .format(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _DisponiblesTab extends StatelessWidget {
  final List<Transferview> transfers;
  final bool loading;
  final String? error;
  final String Function(num) fmtMoney;
  final void Function(Transferview) onTap;
  final Future<void> Function() onRetry;

  const _DisponiblesTab({
    required this.transfers,
    required this.loading,
    required this.error,
    required this.fmtMoney,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _ShimmerList();
    if (error != null) return _ErrorState(message: error!, onRetry: onRetry);
    if (transfers.isEmpty) {
      return const _EmptyState(
        title: 'Sin transferencias disponibles',
        message: 'No hay transferencias activas en este momento.',
      );
    }

    return RefreshIndicator(
      color: kBlueColorLogo,
      onRefresh: onRetry,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
        itemCount: transfers.length,
        itemBuilder: (context, i) => _TransferCard(
          key: ValueKey('tr_${transfers[i].id}'),
          cliente: transfers[i].cliente,
          deposito: transfers[i].numeroDeposito,
          banco: transfers[i].banco,
          monto: transfers[i].monto,
          saldo: transfers[i].saldo,
          fmtMoney: fmtMoney,
          onTap: () => onTap(transfers[i]),
        ),
      ),
    );
  }
}

class _SeleccionadasTab extends StatelessWidget {
  final List<TransParcial> parciales;
  final String Function(num) fmtMoney;
  final void Function(int) onDismiss;

  const _SeleccionadasTab({
    required this.parciales,
    required this.fmtMoney,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (parciales.isEmpty) {
      return const _EmptyState(
        title: 'Aún no seleccionás ninguna',
        message: 'Tocá una transferencia en "Disponibles" para aplicarla.',
        icon: Icons.inbox_rounded,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
      itemCount: parciales.length,
      itemBuilder: (context, i) {
        final p = parciales[i];
        return Dismissible(
          key: Key('parcial_${p.numeroDeposito}_$i'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismiss(i),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD64045),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 28),
          ),
          child: _TransferCard(
            cliente: p.cliente,
            deposito: p.numeroDeposito,
            banco: p.banco,
            monto: p.aplicado,
            saldo: p.saldo,
            fmtMoney: fmtMoney,
            aplicado: true,
          ),
        );
      },
    );
  }
}

class _TransferCard extends StatelessWidget {
  final String cliente;
  final String deposito;
  final String banco;
  final num monto;
  final num saldo;
  final String Function(num) fmtMoney;
  final VoidCallback? onTap;
  final bool aplicado;

  const _TransferCard({
    super.key,
    required this.cliente,
    required this.deposito,
    required this.banco,
    required this.monto,
    required this.saldo,
    required this.fmtMoney,
    this.onTap,
    this.aplicado = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = aplicado ? kNewgreen : const Color(0xFF0EA5E9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: kNewsurfaceHi,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kNewborder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        aplicado
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente,
                            style: const TextStyle(
                              color: kNewtextPri,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            banco,
                            style: const TextStyle(
                              color: kNewtextMut,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!aplicado)
                      const Icon(Icons.chevron_right_rounded,
                          color: kNewtextMut, size: 24),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Metric(
                      label: 'Depósito',
                      value: deposito,
                    ),
                    const SizedBox(width: 8),
                    _Metric(
                      label: aplicado ? 'Aplicado' : 'Monto',
                      value: fmtMoney(monto),
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    _Metric(
                      label: 'Saldo',
                      value: fmtMoney(saldo),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Metric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: kNewtextMut,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? kNewtextPri,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const _EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.sync_alt_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            const Text('Ups…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlueColorLogo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      itemCount: 5,
      itemBuilder: (context, _) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF1F252E);
    const hi = Color(0xFF2A323C);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1 + _c.value * 2, 0),
              end: Alignment(1 + _c.value * 2, 0),
              colors: const [base, hi, base],
              stops: const [0.1, 0.3, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}
