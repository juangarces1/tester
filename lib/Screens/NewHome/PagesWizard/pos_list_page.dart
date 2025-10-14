// lib/ui/pos_list_page.dart
import 'package:flutter/material.dart';
import 'package:tester/Providers/faces_provider.dart';
import 'pos_detail_page.dart';

import 'package:provider/provider.dart';

class POSListPage extends StatelessWidget {
  final String dispatchId;
  const POSListPage({super.key, required this.dispatchId});

  @override
  Widget build(BuildContext context) {
    final faces = context.watch<FacesProvider>().faces;

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona POS'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: faces.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15,
          ),
          itemBuilder: (_, i) {
            final f = faces[i];
            final hosesCount = f.hoses.length;
            final unpaid = f.hoses.any((h) => h.status.toLowerCase() == 'unpaid');

            return _POSCard(
              title: 'POS ${f.pos}',
              subtitle: '${f.pumpName ?? 'Surtidor ${f.pumpId}'} · Cara ${f.face}',
              badgeText: '$hosesCount manguera${hosesCount == 1 ? '' : 's'}',
              highlight: unpaid ? 'Tiene pendientes' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => POSDetailPage(face: f, dispatchId: dispatchId),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _POSCard extends StatelessWidget {
  final String title, subtitle, badgeText;
  final String? highlight;
  final VoidCallback onTap;
  const _POSCard({
    required this.title, required this.subtitle, required this.badgeText, this.highlight, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text(badgeText, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                ),
              ),
              Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(subtitle, textAlign: TextAlign.center),
              if (highlight != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                      const SizedBox(width: 6),
                      Text(highlight!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
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
