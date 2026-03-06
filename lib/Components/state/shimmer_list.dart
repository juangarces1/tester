import 'package:flutter/material.dart';
import 'package:tester/Components/state/shimmer_card.dart';

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 100,
  });

  final int itemCount;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => ShimmerCard(height: cardHeight),
      ),
    );
  }
}
