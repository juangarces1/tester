import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';                    
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Providers/facturas_provider.dart';        
import 'package:tester/Models/FuelRed/product.dart';
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
    final baseColor =
        VariosHelpers.getShadedColor(product.detalle, kColorFondoOscuro);
    final bgGradient = LinearGradient(
      colors: [baseColor, Color.alphaBlend(Colors.black.withValues(alpha: 0.08), baseColor)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // ✅ Agregar al carrito (factura del provider por index) y cerrar
          final prov = context.read<FacturasProvider>();
          final inv  = prov.getInvoiceByIndex(index);
          inv.detail ??= [];

          // ya está en el carrito?
          final exists = inv.detail!.any((e) =>
              e.codigoArticulo == product.codigoArticulo &&
              e.transaccion    == product.transaccion);

          if (!exists) {
            // usa cantidad 1 por defecto
            product.cantidad = (product.cantidad <= 0) ? 1 : product.cantidad;

            // si NO es combustible (transaccion == 0), descuenta inventario local si aplica
            if (product.transaccion == 0 && product.inventario > 0) {
              product.inventario -= 1;
            }
            inv.detail!.add(product);
          } else {
            // si prefieres incrementar cuando ya existe, descomenta:
            // final i = inv.detail!.indexWhere((e) =>
            //   e.codigoArticulo == product.codigoArticulo &&
            //   e.transaccion    == product.transaccion);
            // final item = inv.detail![i];
            // if (item.transaccion == 0 && item.inventario > 0) {
            //   item.inventario -= 1;
            //   item.cantidad   += 1;
            // }
          }

          FacturaService.updateFactura(context, inv);
          Navigator.of(context).pop(); // cierra la lista de productos
        },
        child: Container(
          decoration: BoxDecoration(gradient: bgGradient, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // imagen
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.06),
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
                            color: Colors.white.withValues(alpha: 0.18),
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

              // título
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

              // precio (usa total)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    NumberFormat.currency(locale: 'es_CR', symbol: '₡', decimalDigits: 0)
                        .format(product.total.toDouble()),
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
