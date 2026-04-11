import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

class MinimalLoader extends StatelessWidget {
  const MinimalLoader({
    super.key,
    this.size = 40,
    this.color = kNewred,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: const TextStyle(
                color: kNewtextSec,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
