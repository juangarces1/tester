import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

class ListaSinpesScreen extends StatefulWidget {
  final int index;
  const ListaSinpesScreen({super.key, required this.index});

  @override
  State<ListaSinpesScreen> createState() => _ListaSinpesScreenState();
}

class _ListaSinpesScreenState extends State<ListaSinpesScreen> {
  final _scroll = ScrollController();
  List<Sinpe> _sinpes = [];
  late Invoice _factura;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _factura = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
    _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Response resp =
        await ApiHelper.getSinpes(_factura.cierre!.idcierre ?? 0);
    if (!mounted) return;

    if (!resp.isSuccess) {
      setState(() {
        _loading = false;
        _error = resp.message;
      });
      return;
    }
    final lista = List<Sinpe>.from(resp.result)
      ..removeWhere((s) => s.activo == 1);
    setState(() {
      _loading = false;
      _sinpes = lista;
    });
  }

  void _select(Sinpe s) {
    if (s.monto > _factura.saldo) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Monto excede el saldo'),
          content: const Text(
              'El monto del SINPE no puede ser mayor que el saldo de la factura.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _factura.formPago!.sinpe = s;
      _factura.formPago!.totalSinpe = s.monto;
      FacturaService.updateFactura(context, _factura);
    });
    Navigator.pop(context);
  }

  String _fmtMoney(num v) =>
      NumberFormat.currency(locale: 'es_CR', symbol: '¢', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: kBlueColorLogo,
            onRefresh: _fetch,
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                _Header(saldo: _factura.saldo, total: _sinpes.length),
                if (_loading) const _ShimmerList(),
                if (!_loading && _error != null)
                  _ErrorState(message: _error!, onRetry: _fetch),
                if (!_loading && _error == null && _sinpes.isEmpty)
                  const _EmptyState(),
                if (!_loading && _error == null && _sinpes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SinpeCard(
                          key: ValueKey('sinpe_${_sinpes[index].id}'),
                          sinpe: _sinpes[index],
                          fmtMoney: _fmtMoney,
                          onTap: () => _select(_sinpes[index]),
                        ),
                        childCount: _sinpes.length,
                      ),
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

class _Header extends StatelessWidget {
  final double saldo;
  final int total;
  const _Header({required this.saldo, required this.total});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 64,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: _GlassBackButton(),
      ),
      leadingWidth: 56,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('SINPE Móvil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text('$total disponibles',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          child: _SaldoBadge(saldo: saldo),
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            NumberFormat.currency(
                    locale: 'es_CR', symbol: '¢', decimalDigits: 0)
                .format(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
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

class _SinpeCard extends StatelessWidget {
  final Sinpe sinpe;
  final String Function(num) fmtMoney;
  final VoidCallback onTap;

  const _SinpeCard({
    super.key,
    required this.sinpe,
    required this.fmtMoney,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/sinpe.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fmtMoney(sinpe.monto),
                              style: const TextStyle(
                                color: kNewgreen,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const _DisponibleChip(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sinpe.nombreEmpleado,
                        style: const TextStyle(
                          color: kNewtextPri,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Comprobante ${sinpe.numComprobante} · ${DateFormat('dd/MM/yy').format(sinpe.fecha)}',
                        style: const TextStyle(
                          color: kNewtextMut,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sinpe.nota.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sinpe.nota,
                          style: const TextStyle(
                            color: kNewtextSec,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: kNewtextMut, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisponibleChip extends StatelessWidget {
  const _DisponibleChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kNewgreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNewgreen.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'DISPONIBLE',
        style: TextStyle(
          color: kNewgreen,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/sinpe.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin SINPE disponibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Creá un SINPE desde la pantalla de administración',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
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
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 56),
              const SizedBox(height: 12),
              const Text(
                'Ups…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _ShimmerCard(),
          childCount: 5,
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Container(
          height: 92,
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
