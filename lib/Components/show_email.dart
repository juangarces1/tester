import 'package:flutter/material.dart';
import 'package:tester/sizeconfig.dart';

class ShowEmail extends StatelessWidget {
  final String? email;
  final Color? backgroundColor;

  const ShowEmail({
    super.key,
    this.email,
    this.backgroundColor,
  });

  bool get _isEmpty => (email == null || email!.trim().isEmpty);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFF0A2A43);

    return Container(
      // Alto más bajo y padding mínimo: compacto de verdad
       width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono pequeño y cuadrado
          SizedBox(
            height: 20,
            width: getProportionateScreenWidth(20),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset(
                "assets/email.png",
                errorBuilder: (_, __, ___) => const Icon(Icons.email_outlined, size: 18, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Texto en una sola línea, con elipsis
          Flexible(
            child: Text(
              _isEmpty ? '—' : email!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,           // más pequeño
                height: 1.1,            // compacta el interlineado
              ),
            ),
          ),
        ],
      ),
    );
  }
}
