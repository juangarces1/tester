import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/constans.dart';

/// Carrito inline SOLO LECTURA:
/// - Recibe los items como parámetro.
/// - Sin botones ni acciones.
/// - Compacto, para embebido en pantallas con scroll padre.
class CartInlineReadOnly extends StatelessWidget {
  final List<Product> items;
  final String title;        // texto del encabezado (por defecto "Detalle")
  final bool denseThumbnails; // true = miniaturas 48 en lugar de 56

  const CartInlineReadOnly({
    super.key,
    required this.items,
    this.title = 'Detalle',
    this.denseThumbnails = false,
  });

  @override
  Widget build(BuildContext context) {
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
          // Encabezado compacto (titulo + pill de conteo)
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kNewtextPri,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              _pill('${items.length} ítem${items.length == 1 ? '' : 's'}'),
            ],
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            _empty()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _CartLineInfo(
                product: items[i],
                denseThumb: denseThumbnails,
              ),
            ),
        ],
      ),
    );
  }

  // Pill de conteo
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

  Widget _empty() {
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

/// Ítem de carrito en modo SOLO INFO (sin acciones).
/// - Miniatura 56x56 (o 48x48 si denseThumb = true)
/// - Nombre, y línea de totales:
///   * Combustible: "Cantidad: X  Total: ₡N"
///   * Normal: "P/U ₡N  Sub-Total: ₡M"
class _CartLineInfo extends StatelessWidget {
  final Product product;
  final bool denseThumb;

  const _CartLineInfo({
    required this.product,
    required this.denseThumb,
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
      child: Row(
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
                  // Nombre (una línea, elipsis)
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
                  // Línea de totales
                  Text(
                    esCombustible
                        ? 'Cantidad: ${product.cantidad}  Total: ${_fmtMoney(product.total.toDouble())}'
                        : 'P/U ${_fmtMoney(product.precioUnit.toDouble())}  Sub-Total: ${_fmtMoney(product.totalProducto.toDouble())}',
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
        ],
      ),
    );
  }

  // Miniatura 56×56 (o 48×48) con misma lógica que tu carrito original
 Widget _thumbnail() {
  final double size = denseThumb ? 48 : 56;

  // 1) Prioridad: por nombre (case-insensitive, trim)
  final name = (product.detalle).trim().toLowerCase();
  ImageProvider? fuelAsset;
  if (name == 'super'  || name == 'comb gasolina super')  {
    fuelAsset = const AssetImage('assets/super.png');
  } else if (name == 'regular' || name == 'comb gasolina plus 91') {
    fuelAsset = const AssetImage('assets/regular.png');
  } else if (name == 'exonerado') {
    fuelAsset = const AssetImage('assets/exonerado.png');
  } else if (name == 'diesel' || name == 'comb diesel 50') {
    fuelAsset = const AssetImage('assets/diesel.png');
  }

  Widget thumb;
  if (fuelAsset != null) {
    // Coincidió por nombre → usar asset de combustible
    thumb = Image(image: fuelAsset, fit: BoxFit.cover);
  } else {
    // 2) Si no coincide por nombre → intentar con imageUrl
    final String rel = product.imageUrl;
    final String? url = (rel.trim().isNotEmpty)
        ? '${Constans.getImagenesUrl()}/$rel'
        : null;

    thumb = (url == null)
        ? const Image(
            image: AssetImage('assets/Logo.png'),
            fit: BoxFit.cover,
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, _) =>
                const Image(image: AssetImage('assets/Logo.png'), fit: BoxFit.cover),
            errorWidget: (context, _, __) =>
                const Icon(Icons.error, size: 24, color: kNewtextPri),
          );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: size,
      height: size,
      color: Colors.black.withValues(alpha: .15),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size, height: size, child: thumb),
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
