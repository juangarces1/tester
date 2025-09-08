import 'package:flutter/material.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class CardTr extends StatelessWidget {
  final Product product;
  final String lista;
  final ValueChanged<Product>? onItemSelected;
  final VoidCallback? onPrint;

  /// Muestra u oculta el icono de imprimir/detalle (por defecto NO se muestra).
  final bool showPrintIcon;

  /// Nuevo: estado visual de selección (para pintar overlay)
  final bool selected;

  const CardTr({
    super.key,
    required this.product,
    required this.lista,
    this.onItemSelected,
    this.onPrint,
    this.showPrintIcon = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color.fromARGB(255, 56, 58, 59);
    final radius = BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Fondo del card
            const Positioned.fill(child: ColoredBox(color: bg)),

            // Contenido
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Material(
                        color: Colors.transparent,
                        child: Ink.image(
                          image: _assetForFuel((product.detalle ?? '').toLowerCase()),
                          fit: BoxFit.cover,
                          child: InkWell(
                            onTap: () => onItemSelected?.call(product),
                            splashColor: Colors.white.withOpacity(0.12),
                            highlightColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      VariosHelpers.formattedToCurrencyValue(product.total.toString()),
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(22),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MeterChip(text: 'M-${product.dispensador}'),
                          const SizedBox(width: 8),
                          Text(
                            '${product.cantidad.toStringAsFixed(2)} L',
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Overlay de selección (oscurece sutil + borde blanco suave)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 2,
                      ),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
            ),

            // Badge de check (no estorba el icono de imprimir arriba-derecha)
            if (selected)
              const Positioned(
                top: 6,
                left: 6,
                child: _CheckBadge(),
              ),

            // Botón opcional (imprimir/detalle)
            if (showPrintIcon && onPrint != null)
              Positioned(
                top: 6,
                right: 6,
                child: _ActionCircle(
                  onTap: onPrint,
                  tooltip: 'Imprimir / Detalle',
                  icon: Icons.print,
                ),
              ),
          ],
        ),
      ),
    );
  }

  AssetImage _assetForFuel(String dLower) {
    if (dLower == 'super') return const AssetImage('assets/super.png');
    if (dLower == 'regular') return const AssetImage('assets/regular.png');
    if (dLower == 'exonerado' || dLower == 'comb exonerado') {
      return const AssetImage('assets/exonerado.png');
    }
    return const AssetImage('assets/diesel.png');
  }
}

class _MeterChip extends StatelessWidget {
  final String text;
  const _MeterChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: w < 360 ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.95),
        ),
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final VoidCallback? onTap;
  final String? tooltip;
  final IconData icon;

  const _ActionCircle({
    required this.onTap,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        iconSize: 24,
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: Icon(Icons.check, size: 16, color: Colors.black),
      ),
    );
  }
}
