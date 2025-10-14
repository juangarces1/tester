// ==============================================
// lib/Components/transacciones_sheet.dart
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

class TransaccionesSheet {
  static Future<void> open({
    required BuildContext context,
    required int zona,
    required Function(Product) onItemSelected,
    bool showPrintIcon = false,
    void Function(Product)? onPrintTap,
  }) async {
    // --- 1) Carga inicial antes de mostrar el modal
    Future<List<Product>> fetch() async {
      final rs = await ApiHelper.getTransaccionesAsProduct(zona);
      if (!rs.isSuccess) {
        final msg = (rs.message.isNotEmpty == true)
            ? rs.message
            : 'No se pudieron cargar transacciones';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return <Product>[];
      }

      final List<Product> items = rs.result;
      final facturas = context.read<FacturasProvider>().facturas;
      return _filtrarProductosNoEnFacturas(items, facturas);
    }

    List<Product> initial = await fetch();

    // --- 2) Mostrar el modal (con estado interno para refrescar)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.85;
        final bottomPad = 16.0 + MediaQuery.of(ctx).padding.bottom;

        return StatefulBuilder(
          builder: (ctx, setState) {
            List<Product> transacciones = initial;
            bool showLoader = false;

            Future<void> refresh() async {
              setState(() => showLoader = true);
              final updated = await fetch();
              setState(() {
                initial = updated;        // persistimos para próximos rebuilds
                showLoader = false;
              });
            }

            Widget noTr() {
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
                          onTap: refresh,
                          child: Ink(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withValues(alpha: 0.5),
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
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final Widget content = transacciones.isEmpty
                ? noTr()
                : Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad),
                    child: RefreshIndicator(
                      onRefresh: refresh,
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
                            lista: 'zona-$zona',
                            onItemSelected: (prod) {
                              onItemSelected(prod);
                              Navigator.of(context).pop();
                            },
                            showPrintIcon: showPrintIcon,
                            onPrint: onPrintTap == null ? null : () => onPrintTap(p),
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
                      color: Colors.black.withValues(alpha: 0.4),
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
                              onPressed: refresh,
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
                            color: Colors.black.withValues(alpha: 0.15),
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
      },
    );
  }

  // --- Utilidad de filtrado (misma lógica que tu botón)
  static List<Product> _filtrarProductosNoEnFacturas(
    List<Product> productosABuscar,
    List<Invoice> facturas,
  ) {
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
