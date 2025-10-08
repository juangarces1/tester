import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Screens/Details/product_screen.dart';
import 'package:tester/helpers/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import '../constans.dart';


class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    this.aspectRatio = 1.0,
  });

  final Product product;
  final int index;
  final double aspectRatio;

 
  @override
Widget build(BuildContext context) {
  final baseColor = VariosHelpers.getShadedColor(product.detalle, kColorFondoOscuro);
  final bgGradient = LinearGradient(
    colors: [baseColor, Color.alphaBlend(Colors.black.withOpacity(0.08), baseColor)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  return Material(
    color: Colors.transparent,
    elevation: 10,
    shadowColor: Colors.black.withOpacity(0.15),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(index: index, product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(gradient: bgGradient, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(12),
        child: Column(
          // clave: deja que la imagen expanda y el resto sea compacto
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGEN EXPANDIDA (evita overflow)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white.withOpacity(0.06),
                  alignment: Alignment.center,
                  child: Hero(
                    tag: product.codigoArticulo,
                    child: CachedNetworkImage(
                      imageUrl: '${Constans.getImagenesUrl()}/${product.imageUrl}',
                      fit: BoxFit.contain,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported_outlined, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // TITULO (máx 2 líneas)
            Text(
              product.detalle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kContrateFondoOscuro,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
                letterSpacing: .1,
              ),
            ),

            const SizedBox(height: 8),

            // PRECIO (sin Spacer, compacto)
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Text(
                  NumberFormat.currency(locale: 'es_CR', symbol: '₡', decimalDigits: 0)
                      .format((product.total ?? 0).toDouble()),
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
      ),
    );
  }
}
