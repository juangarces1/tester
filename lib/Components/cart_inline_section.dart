import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/constans.dart';

/// Cart inline compacto, pensado para embebido en la pantalla.
/// - Sin modales, sin Hero.
/// - Botones compactos tipo imagen (igual estilo que BotonTransacciones).
/// - Lista corta y densa.
/// - Sin chip de inventario; sin texto entre botones +/- (solo íconos).
class CartInlineCompact extends StatelessWidget {
  final int index;
  final VoidCallback onAddTransactions; // abre el modal de transacciones
  final VoidCallback onAddProducts;     // abre el selector de productos/aceites
  final bool? showProductsPage; // si true, abre Products
  
  const CartInlineCompact({
    super.key,
    required this.index,
    required this.onAddTransactions,
    required this.onAddProducts,
    this.showProductsPage,
  });

  @override
  Widget build(BuildContext context) {
    final factura = context.select<FacturasProvider, Invoice>(
      (p) => p.getInvoiceByIndex(index),
    );

    final items = factura.detail ?? const <Product>[];

    return Container(
      decoration: BoxDecoration(
        color: kNewsurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kNewborder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado compacto
          Row(
            children: [
              const Text(
                'Carrito',
                style: TextStyle(
                  color: kNewtextPri,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              _pill('${items.length} ítem${items.length == 1 ? '' : 's'}'),
              const Spacer(),
              _squareImageButton(
                asset: 'assets/AddTr.png',
                size: 34,
                onTap: onAddTransactions,
              ),
              const SizedBox(width: 8),
              (showProductsPage ?? true)
                ? _squareImageButton(
                    asset: 'assets/AceiteNoFondo.png',
                    size: 34,
                    onTap: onAddProducts,
                    fit: BoxFit.contain,
                  )
                : const SizedBox.shrink(),
             
            ],
          ),
          const SizedBox(height: 8),

          // Lista muy densa
          if (items.isEmpty)
            _emptyCart()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _CartLineCompact(
                product: items[i],
                onUpdate: () => FacturaService.updateFactura(context, factura),
                onRemove: () {
                  items.removeAt(i);
                  FacturaService.updateFactura(context, factura);
                },
              ),
            ),
        ],
      ),
    );
  }

  // Badge/píldora con conteo
  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNewborder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kNewtextPri,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  // Botón cuadrado con imagen (estilo BotonTransacciones)
  Widget _squareImageButton({
    required String asset,
    required double size,
    required VoidCallback onTap,
    BoxFit fit = BoxFit.cover,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: AssetImage(asset),
          fit: fit,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }

  Widget _emptyCart() {
    return Container(
      height: 34,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: kNewsurfaceHi,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNewborder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        'Sin productos',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .7),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Ítem de carrito en una sola línea, súper compacto.
/// - Muestra miniatura 56x56.
/// - Muestra nombre y **TOTAL** (product.total).
/// - Si es combustible (transaccion != 0) no muestra controles.
/// - Quita chip de inventario y el texto de cantidad entre botones.
class _CartLineCompact extends StatelessWidget {
  final Product product;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  const _CartLineCompact({
    required this.product,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool esCombustible = product.transaccion != 0;

    return Container(
      decoration: BoxDecoration(
        color: kNewsurfaceHi,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNewborder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Fila 1: miniatura + nombre + total
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _thumbnail(),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // nombre (una línea, elipsis)
                      Text(
                        product.detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kNewtextPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // TOTAL del producto (usa product.total)
                      Text(
                        product.transaccion != 0
                            ? 'Cantidad: ${product.cantidad}  Total: ${_fmtMoney(product.total.toDouble())}'
                            :
                       'P/U ${_fmtMoney(product.precioUnit.toDouble())}  Sub-Total: ${_fmtMoney(product.totalProducto.toDouble())} ',
                        style: const TextStyle(
                          color: kNewtextPri,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón eliminar visible siempre
              _roundIcon(
                icon: Icons.close_rounded,
                bg: const Color(0xFFB00020), // rojo
                onTap: onRemove,
              ),
            ],
          ),

          // Fila 2: Controles (solo si NO es combustible)
          // Fila 2: Controles (solo si NO es combustible)
          if (!esCombustible) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _roundIcon(
                  icon: Icons.remove_rounded,
                  bg: const Color(0xFF1E88E5), // azul
                  onTap: () {
                    if (product.cantidad > 1) {
                      product.cantidad -= 1;
                      product.inventario += 1;
                      onUpdate();
                    }
                  },
                ),
                const SizedBox(width: 10),
                // Cantidad entre - y +
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kNewborder),
                  ),
                  child: Text(
                    '${product.cantidad}',
                    style: const TextStyle(
                      color: kNewtextPri,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _roundIcon(
                  icon: Icons.add_rounded,
                  bg: const Color(0xFF2E7D32), // verde
                  onTap: () {
                    if (product.inventario > 0) {
                      product.cantidad += 1;
                      product.inventario -= 1;
                      onUpdate();
                    }
                  },
                ),
              ],
            ),
          ],

        ],
      ),
    );
  }

  // Miniatura 56×56 con tu misma lógica
  Widget _thumbnail() {
    const double w = 56, h = 56;

    Widget thumb;
    if (product.transaccion == 0) {
      // NO combustible → usa imagen remota
      final String rel = product.imageUrl;
      final String? url = (rel.trim().isNotEmpty)
          ? '${Constans.getImagenesUrl()}/$rel'
          : null;

      thumb = (url == null)
          ? const Image(
              image: AssetImage('assets/Logo.png'),
              fit: BoxFit.cover,
              width: w,
              height: h,
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: w,
              height: h,
              placeholder: (context, _) => const Image(
                image: AssetImage('assets/Logo.png'),
                fit: BoxFit.cover,
                width: w,
                height: h,
              ),
              errorWidget: (context, _, __) =>
                  const Icon(Icons.error, size: 24, color: kNewtextPri),
            );
    } else {
      // Combustible → asset por tipo (detalle)
      final ImageProvider asset = (product.detalle == 'Super')
          ? const AssetImage('assets/super.png')
          : (product.detalle == 'Regular')
              ? const AssetImage('assets/regular.png')
              : (product.detalle == 'Exonerado')
                  ? const AssetImage('assets/exonerado.png')
                  : const AssetImage('assets/diesel.png');

      thumb = Image(
        image: asset,
        fit: BoxFit.cover,
        width: w,
        height: h,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: w,
        height: h,
        color: Colors.black.withValues(alpha: .15),
        child: thumb,
      ),
    );
  }

  // Botón circular pequeño con color de fondo
  Widget _roundIcon({
  required IconData icon,
  required Color bg,
  required VoidCallback onTap,
}) {
  return Material(
    color: bg,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    ),
  );
}


  static String _fmtMoney(double v) {
    final s = v.toStringAsFixed(0);
    final buff = StringBuffer();
    int cnt = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buff.write(s[i]);
      cnt++;
      if (cnt == 3 && i != 0) {
        buff.write(',');
        cnt = 0;
      }
    }
    final str = buff.toString().split('').reversed.join();
    return '₡$str';
  }
}
