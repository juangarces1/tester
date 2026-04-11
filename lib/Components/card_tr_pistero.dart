import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class CardTrPistero extends StatelessWidget {
  final Product product;
  final String lista;
  final ValueChanged<Product>? onItemSelected;
  final VoidCallback? onPrint;
  final bool showPrintIcon;
  final bool selected;

  const CardTrPistero({
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
    final palette = _FuelPalette.from(product.detalle);
    final radius = BorderRadius.circular(22);
    final attendant = _attendantName(product);
    final liters = '${product.cantidad.toStringAsFixed(3)} L';
    final totalText =
        VariosHelpers.formattedToCurrencyValue(product.total.toString());
    final headerTitle =
        (lista.isNotEmpty ? lista : product.detalle).toUpperCase();
    final headerSubtitle =
        lista.isNotEmpty ? product.detalle.toUpperCase() : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Colors.white,
        border: Border.all(
          color: selected ? palette.accent : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onItemSelected?.call(product),
                borderRadius: radius,
                splashColor: palette.primary.withValues(alpha: 0.12),
                highlightColor: palette.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LaneBadge(
                        number: product.dispensador,
                        title: headerTitle,
                        subtitle: headerSubtitle,
                        palette: palette,
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          attendant,
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                       Padding(
                               padding: const EdgeInsets.only(left: 20),
                               child: _InfoTile(
                                label: 'Total',
                                value: totalText,
                                emphasize: true,
                                palette: palette,
                                fontSize: 16,
                                                           ),
                             ),
                               const SizedBox(width: 50),
                       Padding(
                         padding: const EdgeInsets.only(left: 20),
                         child: _InfoTile(
                                label: 'Litros',
                                value: liters,
                                fontSize: 16,
                              ),
                       ),
                
                            

                    ],
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
            if (showPrintIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: _PrintAction(
                  product: product,
                  onOverride: onPrint,
                ),
              ),
            if (selected)
              const Positioned(
                top: 14,
                left: 14,
                child: _CheckBadge(),
              ),
          ],
        ),
      ),
    );
  }

  String _attendantName(Product product) {
    final raw = product.pistero?.trim();
    if (raw == null || raw.isEmpty) return 'SIN PISTERO';
    return raw.toUpperCase();
  }
}

class _LaneBadge extends StatelessWidget {
  final int number;
  final String title;
  final String? subtitle;
  final _FuelPalette palette;

  const _LaneBadge({
    required this.number,
    required this.title,
    required this.palette,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final showSubtitle =
        subtitle != null && subtitle!.isNotEmpty && subtitle != title;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _LaneNumberBadge(number: number, palette: palette),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [               
                if (showSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                     overflow: TextOverflow.ellipsis,
                     maxLines: 1,
                    subtitle!,
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(18),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.local_gas_station, color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _LaneNumberBadge extends StatelessWidget {
  final int number;
  final _FuelPalette palette;

  const _LaneNumberBadge({
    required this.number,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final text = number > 0 ? number.toString() : '--';
    return Text(
      text,
      style: TextStyle(
        fontSize: getProportionateScreenWidth(24),
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final _FuelPalette? palette;
  final double fontSize;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.fontSize,
    this.palette,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = palette?.accent ?? Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: emphasize
            ? palette?.primary.withValues(alpha: 0.08) ?? Colors.grey.shade100
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [         
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize
                  ? getProportionateScreenWidth(fontSize)
                  : getProportionateScreenWidth(fontSize -2),
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: emphasize
                  ? accent
                  : Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}




class _FuelPalette {
  final Color primary;
  final Color accent;

  const _FuelPalette(this.primary, this.accent);

  LinearGradient get gradient => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static _FuelPalette from(String detail) {
    final lower = detail.toLowerCase();
    if (lower.contains('super')) {
      return const _FuelPalette(Color.fromARGB(255, 140, 11, 149), Color.fromARGB(255, 99, 3, 111));
    }
    if (lower.contains('plus') || lower.contains('regular')) {
      return const _FuelPalette(Color.fromARGB(255, 227, 47, 30), Color.fromARGB(255, 210, 2, 2));
    }
    if (lower.contains('diesel')) {
      return const _FuelPalette(Color.fromARGB(255, 9, 140, 79), Color.fromARGB(255, 3, 137, 74));
    }
    return const _FuelPalette(Color.fromARGB(255, 9, 111, 154), Color.fromARGB(255, 7, 131, 203));
  }
}

class _PrintAction extends StatelessWidget {
  final Product product;
  final VoidCallback? onOverride;

  const _PrintAction({
    required this.product,
    this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterProvider>(
      builder: (context, printer, _) {
        final busy = printer.busy;
        final bound = printer.isBound;
        return _ActionCircle(
          onTap: busy ? null : () => _handleTap(context, printer),
          tooltip: busy
              ? 'Imprimiendo...'
              : (bound ? 'Imprimir' : 'Conectar impresora'),
          icon: busy ? Icons.print_disabled : Icons.print,
        );
      },
    );
  }

  void _handleTap(BuildContext context, PrinterProvider printer) async {
    if (onOverride != null) {
      onOverride!.call();
      return;
    }

     printer.runLocked(() async {
       final ok = await printer.ensureBound();
       if (!ok) {
         Fluttertoast.showToast(msg: 'No se pudo conectar a la impresora');
         return;
       }
       try {
         final tp = TestPrint(totalChars: 32);
         await tp.printTransaccion(product);
         Fluttertoast.showToast(msg: 'Transaccion enviada a impresion');
       } catch (e, st) {
         debugPrint('printTransaccion error: $e\n$st');
         Fluttertoast.showToast(msg: 'Error al imprimir: $e');
       }
     });

      
       final tp = TestPrint(totalChars: 32);
         await tp.printTransaccion(product);
        Fluttertoast.showToast(msg: 'Transaccion enviada a impresion');

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
        color: Colors.black.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
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
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
