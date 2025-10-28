import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tester/Components/cart_inline_readonly.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';


class DetalleFacturaScreen extends StatefulWidget {
  final Factura factura;
  const DetalleFacturaScreen({super.key, required this.factura});

  @override
  State<DetalleFacturaScreen> createState() => _DetalleFacturaScreenState();
}

class _DetalleFacturaScreenState extends State<DetalleFacturaScreen> {
  
  @override
  Widget build(BuildContext context) {
    final f = widget.factura;
    final stripe = _docColor(f);

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewborder,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: kNewsurface,
          title: const Text(
            'Detalle',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // ===== Header =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: _HeaderCard(factura: f, stripe: stripe),
              ),
            ),
        
            // ===== Detalle: CartInlineReadOnly (sin botones) =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                child: CartInlineReadOnly(
                  items: f.detalles,                 // 👈 le pasamos el detalle ya cargado
                  title: 'Detalle de la factura',    // título dentro del propio widget
                  denseThumbnails: true,             // miniaturas 48px (más compacto)
                ),
              ),
            ),
        
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Color _docColor(Factura f) {
    if (f.isDevolucion) return const Color(0xFFE67E22); // NC naranja
    if (f.isFactura) return const Color(0xFF2ECC71);    // Factura verde
    if (f.isTicket) return const Color(0xFF3498DB);     // Ticket azul
    return kPrimaryColor;
  }
}

class _HeaderCard extends StatelessWidget {
  final Factura factura;
  final Color stripe;
  const _HeaderCard({required this.factura, required this.stripe});

  @override
  Widget build(BuildContext context) {
    final onCard = Colors.black.withValues(alpha: .86);
    final onMuted = Colors.black.withValues(alpha: .62);

    return Container(
      decoration: BoxDecoration(
        color: kContrateFondoOscuro,
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
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: stripe, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip de tipo + Total
            Row(
              children: [
                _DocTypeChip(factura: factura, color: stripe),
                const Spacer(),
                Text(
                  NumberFormat.currency(symbol: '¢')
                      .format(factura.totalFactura ?? 0),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: stripe,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

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
                  fontWeight: FontWeight.w800,
                  color: onCard,
                ),
              ),

            const SizedBox(height: 12),

            // Pills
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _pill('N°', factura.nFactura, onCard, onMuted),
                _pill('Fecha',
                   VariosHelpers.formatYYYYmmDDhhMM(factura.fechaHoraTrans),
                    onCard, onMuted),
                if ((factura.email ?? '').isNotEmpty)
                  _pill('Email', factura.email!, onCard, onMuted),
                _pill('Km', '${factura.kilometraje}', onCard, onMuted),
                _pill('Placa', '${factura.nPlaca}', onCard, onMuted),
                _pill(
                  'Impuesto',
                  NumberFormat.currency(symbol: '¢')
                      .format(factura.totalImpuesto ?? 0),
                  onCard, onMuted,
                ),
                _pill(factura.plazo == 0 ? 'Contado' : 'Crédito', '', onCard, onMuted),
                if (factura.isDevolucion)
                  _pill('Tipo', 'Nota de Crédito', onCard, onMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, Color onCard, Color onMuted) {
    final onlyLabel = value.isEmpty;
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
                  TextSpan(text: value,     style: TextStyle(color: onCard,  fontWeight: FontWeight.w900)),
                ],
              ),
            ),
    );
  }
}

class _DocTypeChip extends StatelessWidget {
  final Factura factura;
  final Color color;
  const _DocTypeChip({required this.factura, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = factura.isDevolucion
        ? 'Nota de Crédito'
        : (factura.isFactura ? 'Factura Electrónica' : 'Ticket Electrónico');

    final hsl = HSLColor.fromColor(color);
    final readable = hsl.withLightness((hsl.lightness - .22).clamp(0.0, 1.0)).toColor();

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
          fontWeight: FontWeight.w800,
          color: readable,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
