import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Screens/Transacciones/Components/tx_app_bar.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Providers/transactions_provider.dart';

enum TxFilter { all, unpaid, paid }

class TransaccionesScreen extends StatefulWidget {
  const TransaccionesScreen({super.key});

  @override
  State<TransaccionesScreen> createState() => _TransaccionesScreenState();
}

class _TransaccionesScreenState extends State<TransaccionesScreen> {
  TxFilter _filter = TxFilter.unpaid;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionsProvider>();

    final List<ConsoleTransaction> items = switch (_filter) {
      TxFilter.all => prov.all,
      TxFilter.unpaid => prov.unpaid,
      TxFilter.paid => prov.all.where((t) => !(t.saleStatus == 0 && !t.paymentConfirmed)).toList()
    };

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewborder,
        appBar: ConsoleAppBar(
          title: 'Transacciones',
          subtitle: 'Consulta',          // opcional
          backgroundColor: kBlueColorLogo,
          foreColor: Colors.white,
          elevation: 3,
          shadowColor: kPrimaryColor,
          centerTitle: false,
          showBottomDivider: true,
          bottomDividerColor: Colors.white24,
          pillBackButton: true,          // mismo look “pill back”
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${prov.countUnpaid}/${prov.countAll}',
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
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _TxCard(tx: items[i]),
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
          chip('Impagas', TxFilter.unpaid),
          const SizedBox(width: 8),
          chip('Pagadas', TxFilter.paid),
          const SizedBox(width: 8),
          chip('Todas', TxFilter.all),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final ConsoleTransaction tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final accent = _fuelAccentColor(tx);
    final pago = (tx.paymentType ?? '').trim();
    final isUnpaid = tx.saleStatus == 0 && !tx.paymentConfirmed;

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
          Container(width: 4, height: 100, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),

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
                      _StateChip(isUnpaid: isUnpaid),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Monto (grande) + Volumen
                  Row(
                    children: [
                      Text(
                        VariosHelpers.formattedToCurrencyValue(tx.totalValue.toString()),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${tx.totalVolume.toStringAsFixed(2)} L',
                        style: const TextStyle(color: kNewtextPri, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      // Badge con saleNumber / saleId si existen
                      if ((tx.saleNumber) > 0 || (tx.saleId != null && tx.saleId!.isNotEmpty))
                        _SaleBadge(text: _saleTag(tx)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fila inferior: Manguera · Precio/L · HH:mm + chip pago (si hay)
                  Row(
                    children: [
                      Text(
                        'Manguera: M-${tx.nozzleNumber} · ${tx.unitPrice.toStringAsFixed(2)}/L · ${_hhmm(tx.dateTime)}',
                        style: const TextStyle(color: Color(0xFF95A0B2), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (pago.isNotEmpty) _PayChip(text: pago),
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

  static String _saleTag(ConsoleTransaction tx) {
    if (tx.saleNumber > 0) return '#${tx.saleNumber}';
    if (tx.saleId != null && tx.saleId!.isNotEmpty) {
      final s = tx.saleId!;
      return '#${s.length > 6 ? s.substring(0, 6) : s}';
    }
    return '';
  }

  static String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _fuelName(ConsoleTransaction tx) {
    // Ajusta a tu catálogo si lo tienes en provider
    switch (tx.fuelCode) {
      case 2: return 'Regular';
      case 1: return 'Súper';
      case 3: return 'Diésel';
      default:
        // Si el back marca exonerado via paymentType/nombre, cámbialo aquí
        return 'Combustible';
    }
  }

  static IconData _fuelIcon(ConsoleTransaction tx) {
    switch (tx.fuelCode) {
      case 1:
      case 2:
      case 3:
      case 4:
        return Icons.local_gas_station;
      default:
        return Icons.water_drop;
    }
  }

  static Color _fuelAccentColor(ConsoleTransaction tx) {
    // Usa tus constantes de colores; si alguna no existe, cambia el nombre aquí.
    switch (tx.fuelCode) {
      case 2: return kRegularColor;    // Regular
      case 1: return kSuperColor;      // Súper
      case 3: return kDieselColor;     // Diésel
      default:
        // Si manejas "Exonerado" como tipo especial:
        if ((tx.paymentType ?? '').toLowerCase().contains('exoner')) {
          return kExoColor;
        }
        return const Color(0xFF41506B); // fallback
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
