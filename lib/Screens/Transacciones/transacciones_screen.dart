import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/tranascciones_provider.dart';
import 'package:tester/Screens/Transacciones/Components/tx_app_bar.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

import 'package:tester/Models/transaccion.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/Models/response.dart'; // si ya lo usas en el proyecto



enum TxFilter { copiado, efectivo, credito, facturadas, noFacturadas }

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  TxFilter _filter = TxFilter.copiado;
  bool _bootstrapped = false;
  bool _loading = false;
  String? _error;

 @override
  void initState() {
    super.initState();
    // Bootstrap después del primer frame para no disparar en build()
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapIfNeeded());
  }

  Future<void> _bootstrapIfNeeded() async {
    if (_bootstrapped) return;
    final prov = context.read<TransaccionesProvider>();
    if (prov.items.isEmpty) {
      await _fetchFromBackend();
    }
    _bootstrapped = true;
  }

  Future<void> _fetchFromBackend() async {
    setState(() { _loading = true; _error = null; });
    try {

      final cierreProv = context.read<CierreActivoProvider>();
      final int? cierre = cierreProv.cierreFinal?.idcierre;

      // ⬇️ AJUSTA esta llamada al método real en tu ApiHelper
      // por ejemplo: final resp = await ApiHelper.getTransaccionesUsuarioTurno(...);
      final Response resp = await ApiHelper.getTransaccionesByCierre(cierre); 

      if (!resp.isSuccess) {
        setState(() => _error = resp.message ?? 'No se pudo cargar transacciones.');
        return;
      }

      final list  = resp.result;

      // ⬇️ AJUSTA el método del provider que reemplace la lista
      // p. ej. prov.replaceAll(list) / prov.setItems(list) / prov.load(list)
      context.read<TransaccionesProvider>().setAll(list); 
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

    @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransaccionesProvider>();

    final List<Transaccion> items = switch (_filter) {
      TxFilter.copiado   => prov.items.where((t) => t.estado == 'Copiado').toList(),
      TxFilter.efectivo  => prov.items.where((t) => t.estado == 'Efectivo').toList(),
      TxFilter.credito   => prov.items.where((t) => t.estado == 'Credito').toList(),
      TxFilter.facturadas   => prov.items.where((t) => t.facturada != 'no').toList(),
      TxFilter.noFacturadas   => prov.items.where((t) => t.facturada == 'no').toList(),
    };

    final countAll    = prov.length;
    final countUnpaid = prov.unpaid.length;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewborder,
        appBar: ConsoleAppBar(
          title: 'Transacciones',
          subtitle: 'Consulta',
          backgroundColor: kBlueColorLogo,
          foreColor: Colors.white,
          elevation: 3,
          shadowColor: kPrimaryColor,
          centerTitle: false,
          showBottomDivider: true,
          bottomDividerColor: Colors.white24,
          pillBackButton: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$countUnpaid/$countAll',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 15),
            _FiltersRow(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 10),

            // ---- Contenido con RefreshIndicator / Loading / Error ----
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchFromBackend,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    children: [
                                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: _fetchFromBackend,
                                        child: const Text('Reintentar'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : (items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [SizedBox(height: 80), _EmptyState()],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemCount: items.length,
                                itemBuilder: (_, i) => _TxCard(tx: items[i]),
                              )),
              ),
            ),
          ],
        ),
      ),
    );
  }

 
}

class _FiltersRow extends StatelessWidget {
  final TxFilter filter;
  final ValueChanged<TxFilter> onChanged;

  const _FiltersRow({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const selStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    const baseStyle = TextStyle(color: Colors.white70);

    Widget chip(String label, TxFilter f) {
      final selected = filter == f;
      return ChoiceChip(
        label: Text(label, style: selected ? selStyle : baseStyle),
        selected: selected,
        backgroundColor: const Color(0xFF1A2130),
        selectedColor: const Color(0xFF2A3550),
        onSelected: (_) => onChanged(f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Impagas', TxFilter.copiado),
          const SizedBox(width: 8),
          chip('Credito', TxFilter.credito),
          const SizedBox(width: 8),
          chip('Efectivo', TxFilter.efectivo),
           const SizedBox(width: 8),
          chip('Facturadas', TxFilter.facturadas),
           const SizedBox(width: 8),
          chip('No Facturadas', TxFilter.noFacturadas),

        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Transaccion tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final accent = _fuelAccentColor(tx);
   
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Acento lateral por combustible
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: combustible + estado
                  Row(
                    children: [
                      Icon(_fuelIcon(tx), color: accent, size: 18),
                      const SizedBox(width: 6),
                      Text(_fuelName(tx),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      _StateChip(isUnpaid: tx.isUnpaid), // 👈 estado impaga/pagada
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Monto (grande) + Volumen
                  Row(
                    children: [
                      Text(
                        VariosHelpers.formattedToCurrencyValue(tx.total.toString()),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${tx.volumen.toStringAsFixed(2)} L',
                        style: const TextStyle(color: kNewtextPri, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      // Badge con numero / idtransaccion
                      if (tx.numero > 0 || tx.idtransaccion > 0)
                        _SaleBadge(text: _saleTag(tx)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fila inferior: Manguera · Precio/L · HH:mm + chip pago (si hay)
                  Row(
                    children: [
                      Text(
                        'Manguera: M-${tx.dispensador} · ${_precioUnitL(tx)} · ${_hhmm(tx.fechatransaccion)}',
                        style: const TextStyle(color: Color(0xFF95A0B2), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (tx.estado.isNotEmpty) _PayChip(text: tx.estado),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _precioUnitL(Transaccion t) {
    // Si quieres formateo moneda por litro:
    // return '${VariosHelpers.formattedToCurrencyValue(t.preciounitario.toString())}/L';
    // Si prefieres simple:
    return '${t.preciounitario}/L';
  }

  static String _saleTag(Transaccion t) {
    if (t.numero > 0) return '#${t.numero}';
    if (t.idtransaccion > 0) return '#${t.idtransaccion}';
    return '';
  }

  static String _hhmm(String s) {
    final dt = DateTime.tryParse(s);
    if (dt == null) return s; // fallback si viene en otro formato
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
    // Si tu string viene "YYYY-MM-DD HH:mm:ss" (con espacio),
    // puedes hacer: DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }

  static String _fuelName(Transaccion t) {
    // Ajusta a tu catálogo si existe:
    switch (t.idproducto) {
      case 2: return 'Regular';
      case 1: return 'Súper';
      case 3: return 'Diésel';
      default: return t.nombreproducto.isNotEmpty ? t.nombreproducto : 'Combustible';
    }
  }

  static IconData _fuelIcon(Transaccion t) {
    switch (t.idproducto) {
      case 1:
      case 2:
      case 3:
      case 4:
        return Icons.local_gas_station;
      default:
        return Icons.water_drop;
    }
  }

  static Color _fuelAccentColor(Transaccion t) {
    switch (t.idproducto) {
      case 2: return kRegularColor;    // Regular
      case 1: return kSuperColor;      // Súper
      case 3: return kDieselColor;     // Diésel
      default:
        return const Color(0xFF41506B);
    }
  }
}

class _StateChip extends StatelessWidget {
  final bool isUnpaid;
  const _StateChip({required this.isUnpaid});

  @override
  Widget build(BuildContext context) {
    final bg = isUnpaid ? const Color(0xFF3A2A00) : const Color(0xFF0A2E1A);
    final tx = isUnpaid ? const Color(0xFFFFC55A) : const Color(0xFF59D196);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(isUnpaid ? 'IMPAGA' : 'PAGADA', style: TextStyle(color: tx, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String text;
  const _PayChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2432),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C3446)),
      ),
      child: Text('Pago: $text', style: const TextStyle(color: Color(0xFFB9C2D3), fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SaleBadge extends StatelessWidget {
  final String text;
  const _SaleBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF20283A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No hay transacciones en este filtro',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }
}
