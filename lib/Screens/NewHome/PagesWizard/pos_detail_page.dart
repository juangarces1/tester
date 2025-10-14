// lib/ui/pos_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/ConsoleModels/fuel_palette.dart';
import 'package:tester/ConsoleModels/modelos_faces.dart';
import 'package:tester/ConsoleModels/pos_adapters.dart';
import 'package:tester/Providers/despachos_provider.dart';


class POSDetailPage extends StatelessWidget {
  final FaceView face;
  final String dispatchId; // ← viene del flujo
  const POSDetailPage({super.key, required this.face, required this.dispatchId});

  @override
  Widget build(BuildContext context) {
    final hoses = face.hoses;

    return Scaffold(
      appBar: AppBar(
        title: Text('POS ${face.pos} · ${face.pumpName ?? "Surtidor ${face.pumpId}"} · Cara ${face.face}'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: hoses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final h = hoses[i];
          return _HoseCard(
            hose: h,
            onSelect: () {
              final prov = context.read<DespachosProvider>();
              final ctrl = prov.getById(dispatchId);
              if (ctrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se encontró el DispatchControl del flujo actual')),
                );
                return;
              }

              // Adaptar a tus ViewModels físicos
             final pos = toPositionPhysical(face);
            final hose = toHosePhysical(h); // h = HoseView elegido

              // Guarda en el control + arranca watcher (lo hace selectHose)
              ctrl.selectHose(pos: pos, hose: hose);

              // Si quieres volver con el nozzle elegido:
              Navigator.pop(context, h.nozzleNumber);
            },
          );
        },
      ),
    );
  }
}

class _HoseCard extends StatelessWidget {
  final HoseView hose;
  final VoidCallback onSelect;
  const _HoseCard({required this.hose, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = fuelColor(hose.fuelCode);
    final name  = fuelName(hose.fuelCode);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(fuelIcon(hose.fuelCode), color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    _Chip(text: 'Nozzle ${hose.nozzleNumber}', color: cs.secondaryContainer, textColor: cs.onSecondaryContainer),
                    _Chip(text: hose.status, color: cs.tertiaryContainer, textColor: cs.onTertiaryContainer),
                  ]),
                  const SizedBox(height: 6),
                  Text(hose.fullAddress, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _PricePill(label: 'Cash',   value: hose.priceCash,   decimals: hose.priceDecimals),
                    const SizedBox(width: 6),
                    _PricePill(label: 'Credit', value: hose.priceCredit, decimals: hose.priceDecimals),
                    const SizedBox(width: 6),
                    _PricePill(label: 'Debit',  value: hose.priceDebit,  decimals: hose.priceDecimals),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: onSelect, icon: const Icon(Icons.check), label: const Text('Elegir')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text; final Color color; final Color textColor;
  const _Chip({required this.text, required this.color, required this.textColor});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
  );
}

class _PricePill extends StatelessWidget {
  final String label; final double value; final int decimals;
  const _PricePill({required this.label, required this.value, required this.decimals});
  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text('$label: ${value.toStringAsFixed(decimals)}',
        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}
