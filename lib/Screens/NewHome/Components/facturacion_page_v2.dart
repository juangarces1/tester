import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Peddlers/peddlers_add_screen.dart';
import 'package:tester/Screens/checkout/checkount.dart';
import 'package:tester/Screens/credito/credit_process_screen.dart';
import 'package:tester/Screens/tickets/ticket_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

class FacturacionPageV2 extends StatefulWidget {
  const FacturacionPageV2({super.key});

  @override
  State<FacturacionPageV2> createState() => _FacturacionPageV2State();
}

class _FacturacionPageV2State extends State<FacturacionPageV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151A), // kNewsurface style match
      body: SafeArea(
        child: Consumer<FacturasProvider>(
          builder: (context, facturasProvider, child) {
            final facturas = facturasProvider.facturas;

            return CustomScrollView(
              slivers: [
                // 1. Header Area (Hub + Titles)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFacturacionHub(context),
                        const SizedBox(height: 24),
                        if (facturas.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                "Comprobantes en Curso",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kNewborder,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  facturas.length.toString(),
                                  style: const TextStyle(
                                    color: kNewtextSec,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ]
                      ],
                    ),
                  ),
                ),

                // 2. Grid Area
                if (facturas.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95, // Adjust for card height
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _crearTarjetaFactura(context, facturas[index]);
                        },
                        childCount: facturas.length,
                      ),
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFacturacionHub(BuildContext context) {
    // Gradient Blue/Purpulish for Billing Identity
    const billingGradient = LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // Blue-600 to Indigo-600
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: billingGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _mostrarMenu(context),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Stack(
            children: [
              // Background Icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 180,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nueva Factura",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Ticket, Contado, Crédito, Peddler",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: kNewsurfaceHi,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                size: 40, color: Colors.greenAccent.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            "Todo facturado",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "No hay comprobantes pendientes",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 100), // Visual offset from center
        ],
      ),
    );
  }

  // --- Logic ported from V1 ---

  Widget _crearTarjetaFactura(BuildContext context, Invoice factura) {
    // 1. Determine Style based on Type
    final style = _getInvoiceStyle(factura);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    style.color.withOpacity(0.8),
                    style.color.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navegarSegunTipoInvoice(context, factura),
                  child: Stack(
                    children: [
                      // Watermark Icon
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          style.icon,
                          size: 90,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header: Icon + Type
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(style.icon,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    factura.tipoInvoice,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Footer: Amount + Client
                            // Details Preview
                            if (factura.detail != null &&
                                factura.detail!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...factura.detail!
                                        .take(2)
                                        .map((prod) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 2.0),
                                              child: Text(
                                                "${prod.cantidad.toStringAsFixed(1)} x ${prod.detalle}",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(
                                                          0.9), // More visible
                                                  fontSize: 13, // Larger font
                                                  height: 1.1,
                                                ),
                                                maxLines: 2, // Allow 2 lines
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                    if (factura.detail!.length > 2)
                                      Text(
                                        "...",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // Footer: Amount + Client
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  VariosHelpers.formattedToCurrencyValue(
                                      factura.total.toString()),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getClientName(factura),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Delete Button (Glassmorphism mini)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _eliminarFactura(context, factura),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getClientName(Invoice factura) {
    if (factura.isTicket == true) return 'Ticket de Venta';
    if (factura.isCredit == true) {
      return factura.formPago?.clienteCredito.obtenerPrimerNombre() ??
          'Cliente';
    }
    if (factura.isPeddler == true) {
      return factura.formPago?.clienteCredito.obtenerPrimerNombre() ??
          'Peddler';
    }
    if (factura.isContado == true) {
      return factura.formPago?.clienteFactura.obtenerPrimerNombre() ??
          'Consumidor Final';
    }
    return 'N/A';
  }

  _InvoiceStyle _getInvoiceStyle(Invoice factura) {
    if (factura.isContado == true) {
      return _InvoiceStyle(
        color: const Color(0xFFF97316), // Orange
        icon: Icons.receipt_long_rounded,
      );
    }
    if (factura.isCredit == true) {
      return _InvoiceStyle(
        color: const Color(0xFF3B82F6), // Blue
        icon: Icons.credit_card_rounded,
      );
    }
    if (factura.isTicket == true) {
      return _InvoiceStyle(
        color: const Color(0xFF10B981), // Green
        icon: Icons.confirmation_number_outlined,
      );
    }
    if (factura.isPeddler == true) {
      return _InvoiceStyle(
        color: const Color(0xFFF59E0B), // Amber
        icon: Icons.local_shipping_rounded,
      );
    }
    // Default
    return _InvoiceStyle(
      color: Colors.grey,
      icon: Icons.description,
    );
  }

  void _navegarSegunTipoInvoice(BuildContext context, Invoice invoice) {
    final facturasProvider =
        Provider.of<FacturasProvider>(context, listen: false);
    final index = facturasProvider.facturas.indexOf(invoice);

    if (invoice.isCredit == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProceeeCreditScreen(index: index)),
      );
    } else if (invoice.isPeddler == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PeddlersAddScreen(index: index)),
      );
    } else if (invoice.isContado == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheaOutScreen(index: index)),
      );
    } else if (invoice.isTicket == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TicketScreen(index: index)),
      );
    }
  }

  void _eliminarFactura(BuildContext context, Invoice facturaActual) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kNewsurface,
          title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          content: Text(
              '¿Estás seguro de que quieres eliminar ${facturaActual.tipoInvoice}?',
              style: const TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white54)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                FacturaService.eliminarFactura(context, facturaActual);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarMenu(BuildContext context) {
    final cierreActivo =
        Provider.of<CierreActivoProvider>(context, listen: false);
    final nuevaFactura = Invoice.createInitializedInvoice(
        cierreActivo.cierreFinal, cierreActivo.usuario);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kNewsurface,
          title: const Center(
            child: Text(
              'Nueva Factura',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _crearBotonOpcion(
                    context, 'Contado', nuevaFactura, kPrimaryColor),
                _crearBotonOpcion(
                    context, 'Ticket', nuevaFactura, Colors.green),
                _crearBotonOpcion(
                    context, 'Credito', nuevaFactura, kBlueColorLogo),
                _crearBotonOpcion(
                  context,
                  'Peddler',
                  nuevaFactura,
                  const Color.fromARGB(255, 196, 177, 5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crearBotonOpcion(
    BuildContext context,
    String texto,
    Invoice invoice,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).pop();

          final facturasProvider =
              Provider.of<FacturasProvider>(context, listen: false);

          final index = facturasProvider.addInvoice(invoice);

          if (texto == 'Contado') {
            invoice.isContado = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => CheaOutScreen(index: index)),
            );
          } else if (texto == 'Ticket') {
            invoice.isTicket = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => TicketScreen(index: index)),
            );
          } else if (texto == 'Credito') {
            invoice.isCredit = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => ProceeeCreditScreen(index: index)),
            );
          } else if (texto == 'Peddler') {
            invoice.isPeddler = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => PeddlersAddScreen(index: index)),
            );
          }
        },
      ),
    );
  }
}

class _InvoiceStyle {
  final Color color;
  final IconData icon;

  _InvoiceStyle({required this.color, required this.icon});
}
