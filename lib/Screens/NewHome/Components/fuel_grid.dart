import 'package:flutter/material.dart';
import 'package:tester/ViewModels/new_map.dart';

class FuelTypeGrid extends StatelessWidget {
  final Map<int, PositionPhysical> stationMap;
  final void Function(Fuel) onSelected;
  final EdgeInsetsGeometry padding;
  const FuelTypeGrid({
    super.key,
    required this.stationMap,
    required this.onSelected,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    // recopilar tipos de fuel únicos
    final seen = <String, Fuel>{};
    for (final pos in stationMap.values) {
      for (final h in pos.hoses) {
        seen.putIfAbsent(h.fuel.name, () => h.fuel);
      }
    }
    final fuels = seen.values.toList();

    return GridView.builder(
      padding: padding,
      itemCount: fuels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 3.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final f = fuels[i];
        return _FuelCard(fuel: f, onTap: () => onSelected(f));
      },
    );
  }
}

class _FuelCard extends StatelessWidget {
  final Fuel fuel;
  final VoidCallback onTap;
  const _FuelCard({required this.fuel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: fuel.color,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconForFuel(), size: 52, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  fuel.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForFuel() {
    final n = fuel.name.toLowerCase();
    if (n.contains('premium') || n.contains('super')) return Icons.bolt;
    if (n.contains('regular')) return Icons.local_gas_station;
    if (n.contains('diésel') || n.contains('diesel')) return Icons.local_shipping;
    return Icons.help_outline;
  }
}
