// ==============================================
// lib/Components/boton_transacciones.dart
// ==============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/card_tr.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class BotonTransacciones extends StatefulWidget {
  final String imagePath;
  final Function(Product) onItemSelected;
  final int zona;

  /// Control global para mostrar u ocultar el icono de imprimir en cada card.
  final bool showPrintIcon;

  /// Callback opcional si se pulsa el icono de imprimir/detalle en una card.
  final void Function(Product)? onPrintTap;

  const BotonTransacciones({
    super.key,
    required this.imagePath,
    required this.onItemSelected,
    required this.zona,
    this.showPrintIcon = false,
    this.onPrintTap,
  });

  @override
  State<BotonTransacciones> createState() => _BotonTransaccionesState();
}

class _BotonTransaccionesState extends State<BotonTransacciones> {
  List<Product> transacciones = [];
  bool showLoader = false;

  @override
  void initState() {
    super.initState();
    _updateTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: AssetImage(widget.imagePath),
          fit: BoxFit.cover,
          child: InkWell(
            onTap: () => _showModal(context),
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
    );
  }

  Future<void> _showModal(BuildContext context) async {
    await _updateTransactions();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // showDragHandle: true, // si tu versión de Flutter lo soporta
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.85;
        final bottomPad = 16.0 + MediaQuery.of(ctx).padding.bottom;

        final Widget content = transacciones.isEmpty
            ? _noTr()
            : Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad),
                child: RefreshIndicator(
                  onRefresh: _updateTransactions,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: transacciones.length,
                    itemBuilder: (context, i) {
                      final p = transacciones[i];
                      return CardTr(
                        product: p,
                        lista: 'zona-${widget.zona}',
                        onItemSelected: (prod) {
                          widget.onItemSelected(prod);
                          Navigator.of(context).pop();
                        },
                        showPrintIcon: widget.showPrintIcon,
                        onPrint: widget.onPrintTap == null
                            ? null
                            : () => widget.onPrintTap!(p),
                      );
                    },
                  ),
                ),
              );

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: kColorFondoOscuro,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Cabecera
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Transacciones (${transacciones.length})',
                          style: TextStyle(
                            color: kContrateFondoOscuro,
                            fontWeight: FontWeight.bold,
                            fontSize: getProportionateScreenWidth(18),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Actualizar',
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                          onPressed: _updateTransactions,
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.only(top: 52),
                  child: content,
                ),

                // Loader overlay
                if (showLoader)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _noTr() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _updateTransactions,
                child: Ink(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                    child: const Image(
                      image: AssetImage('assets/NoTr.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay transacciones',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(18),
                fontWeight: FontWeight.bold,
                color: kContrateFondoOscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca para volver a intentar',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(13),
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTransactions() async {
    try {
      setState(() => showLoader = true);

      final rs = await ApiHelper.getTransaccionesAsProduct(widget.zona);

      List<Invoice> facturas = [];
      if (mounted) {
        facturas = context.read<FacturasProvider>().facturas;
      }

      if (rs.isSuccess) {
        final List<Product> items = rs.result;
        final filtrados = filtrarProductosNoEnFacturas(items, facturas);
        if (mounted) {
          setState(() => transacciones = filtrados);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rs.message.isNotEmpty == true ? rs.message : 'No se pudieron cargar transacciones')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => showLoader = false);
    }
  }

  List<Product> filtrarProductosNoEnFacturas(List<Product> productosABuscar, List<Invoice> facturas) {
    final productosFiltrados = List<Product>.from(productosABuscar);
    for (final factura in facturas) {
      if (factura.detail == null) continue;
      for (final productoFactura in factura.detail!) {
        productosFiltrados.removeWhere(
          (p) => p.transaccion == productoFactura.transaccion,
        );
      }
    }
    return productosFiltrados;
  }
}
        