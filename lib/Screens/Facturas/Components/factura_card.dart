import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

class FacturaCard extends StatelessWidget {
  final Factura factura;
  final int index;
  final VoidCallback onInfoPressed;
  final VoidCallback onPrintPressed;
  final VoidCallback onConfirmPressed;

  const FacturaCard({
    super.key,
    required this.factura,
    required this.index,
    required this.onInfoPressed,
    required this.onPrintPressed,
    required this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color stripe = _docColor(factura);
    final Color onCard = Colors.black.withValues(alpha:  0.86);
    final Color onMuted = Colors.black.withValues(alpha: 0.62);

    return Container(
      decoration: BoxDecoration(
        color: kContrateFondoOscuro, // surface clara sobre fondo dark
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: .06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Stripe como border izquierdo: cero inventos con alturas infinitas
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: stripe, width: 6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ← NO stretch
          children: [
            // Header: chip + total
            Row(
              children: [
                _DocTypeChip(factura: factura, color: stripe),
                const Spacer(),
                Text(
                  VariosHelpers.formattedToCurrencyValue(
                      (factura.totalFactura ?? 0).toString()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: stripe,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
    
            // Cliente (si no es ticket)
            if (!factura.isTicket)
              Text(
                (factura.cliente.trim().isNotEmpty == true
                        ? factura.cliente
                        : factura.descripCliente) ??
                    '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onCard,
                ),
              ),
    
            const SizedBox(height: 10),
    
            // Metadatos
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MetaPill(label: 'N°', value: factura.nFactura, onCard: onCard, onMuted: onMuted),
                _MetaPill(
                    label: 'Fecha',
                    value: VariosHelpers.formatYYYYmmDD(factura.fechaHoraTrans),
                    onCard: onCard,
                    onMuted: onMuted),
                _MetaPill(
                    label: 'Hora',
                    value: VariosHelpers.formatToHour(factura.fechaHoraTrans),
                    onCard: onCard,
                    onMuted: onMuted),
                _MetaPill(
                    label: 'Productos',
                    value: '${factura.detalles.length}',
                    onCard: onCard,
                    onMuted: onMuted),
                _MetaPill(
                    label: factura.plazo == 0 ? 'Contado' : 'Crédito',
                    value: '',
                    onCard: onCard,
                    onMuted: onMuted),
              ],
            ),
    
            const SizedBox(height: 12),
            const Divider(height: 1),
    
            // Acciones
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleAction(
                    tooltip: 'Detalles',
                    bg: kBlueColorLogo,
                    icon: Icons.list_outlined,       // mismo ícono
                    onPressed: onInfoPressed,
                  ),
                  const SizedBox(width: 8),
                  _CircleAction(
                    tooltip: 'Imprimir',
                    bg: Colors.blueGrey,
                    icon: Icons.print_outlined,      // mismo ícono
                    onPressed: onPrintPressed,
                  ),
                  const SizedBox(width: 8),
                  if (!factura.isDevolucion)
                    _CircleAction(
                      tooltip: 'Nota de crédito',
                      bg: kPrimaryColor,
                      icon: Icons.arrow_back,        // mismo ícono
                      onPressed: onConfirmPressed,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _docColor(Factura f) {
    if (f.isDevolucion) return const Color(0xFFE67E22); // NC naranja
    if (f.isTicket)    return const Color(0xFF2ECC71); // Factura verde
    if (f.isFactura)     return const Color(0xFF3498DB); // Ticket azul
    return kPrimaryColor;
  }
}

class _DocTypeChip extends StatelessWidget {
  final Factura factura;
  final Color color;
  const _DocTypeChip({required this.factura, required this.color});

  @override
  Widget build(BuildContext context) {
    final String text = factura.isDevolucion
        ? 'Nota de Crédito'
        : (factura.isFactura ? 'Factura Electrónica' : 'Ticket Electrónico');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _readable(color),
          letterSpacing: .2,
        ),
      ),
    );
  }

  Color _readable(Color base) {
    // texto leíble sobre chip claro
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - .22).clamp(0.0, 1.0)).toColor();
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;
  final Color onCard;
  final Color onMuted;
  const _MetaPill({
    required this.label,
    required this.value,
    required this.onCard,
    required this.onMuted,
  });

  @override
  Widget build(BuildContext context) {
    final bool onlyLabel = value.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: .06)),
      ),
      child: onlyLabel
          ? Text(label, style: TextStyle(color: onMuted, fontWeight: FontWeight.w600))
          : RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(color: onMuted, fontWeight: FontWeight.w600)),
                  TextSpan(text: value, style: TextStyle(color: onCard, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final String tooltip;
  final Color bg;
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleAction({
    required this.tooltip,
    required this.bg,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: bg,
          shape: const CircleBorder(),
          fixedSize: const Size(48, 48), // hitbox accesible
          padding: EdgeInsets.zero,      // sin relleno extra
        ),
      ),
    );
  }
}


