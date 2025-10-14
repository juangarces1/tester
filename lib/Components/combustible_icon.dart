import 'package:flutter/material.dart';

const kRegularColor =  Color(0xFFec1c24);
const kSuperColor = Color(0xFFb634b8);
const kDieselColor = Color(0xFF1dbd4a);

class CombustibleIcon extends StatelessWidget {
  final String tipo;
  final double size;

  const CombustibleIcon({super.key, required this.tipo, this.size = 32});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (tipo.toLowerCase()) {
      case "super":
        icon = Icons.bolt;
        color = kSuperColor;
        break;
      case "regular":
        icon = Icons.local_gas_station;
        color = kRegularColor;
        break;
      case "diesel":
        icon = Icons.local_shipping; // Puedes cambiar por Icons.build si prefieres
        color = kDieselColor;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.18),
      radius: size / 2,
      child: Icon(icon, color: color, size: size * 0.7),
    );
  }
}
