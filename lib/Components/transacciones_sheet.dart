// ==============================================
// lib/Components/transacciones_sheet.dart
// ==============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/card_tr_pistero.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/product.dart';
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
    Future<List<Product>> fetch() async {
     
      // final request = {
      //   'lookbackMinutes': 10,
      // };
      // final responseSync = await ApiHelper.post('api/TransaccionesApi/sync-now', request);
      // if (!responseSync.isSuccess) {
      //   final msg = (responseSync.message.isNotEmpty == true)
      //       ? responseSync.message
      //       : 'No se pudo sincronizar transacciones';
      //    if (!context.mounted) return <Product>[];
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      //   return <Product>[];
      // }

      final rs = await ApiHelper.getTransaccionesAsProduct(zona);
      if (!rs.isSuccess) {
        final msg = (rs.message.isNotEmpty == true)
            ? rs.message
            : 'No se pudieron cargar transacciones';
         if (!context.mounted) return <Product>[];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return <Product>[];
      }

      final List<Product> items = rs.result;
       if (!context.mounted) return <Product>[];
      final facturas = context.read<FacturasProvider>().facturas;
      final list = _filtrarProductosNoEnFacturas(items, facturas);

      list.sort((a, b) => b.transaccion.compareTo(a.transaccion)); // DESC
      return list;
    }

    final initial = await fetch();
   
    await showModalBottomSheet(
      
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.85;
        final bottomPad = 16.0 + MediaQuery.of(ctx).padding.bottom;

        return _TransaccionesSheetContent(
          height: height,
          bottomPad: bottomPad,
          initial: initial,
          fetch: fetch,
          zona: zona,
          onItemSelected: onItemSelected,
          showPrintIcon: showPrintIcon,
          onPrintTap: onPrintTap,
        );
      },
    );
  }

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

// ================== Widget interno (estado limpio) ==================

class _TransaccionesSheetContent extends StatefulWidget {
  const _TransaccionesSheetContent({
    required this.height,
    required this.bottomPad,
    required this.initial,
    required this.fetch,
    required this.zona,
    required this.onItemSelected,
    required this.showPrintIcon,
    required this.onPrintTap,
  });

  final double height;
  final double bottomPad;
  final List<Product> initial;
  final Future<List<Product>> Function() fetch;
  final int zona;
  final Function(Product) onItemSelected;
  final bool showPrintIcon;
  final void Function(Product)? onPrintTap;

  @override
  State<_TransaccionesSheetContent> createState() => _TransaccionesSheetContentState();
}

class _TransaccionesSheetContentState extends State<_TransaccionesSheetContent> {
  late List<Product> _items;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _items = List<Product>.from(widget.initial)
      ..sort((a, b) => b.transaccion.compareTo(a.transaccion));
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final updated = await widget.fetch();
    setState(() {
      _items = updated; // ya viene ordenado
      _loading = false;
    });
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
                onTap: _refresh,
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

  @override
  Widget build(BuildContext context) {
    final transacciones = _items;

    final Widget content = transacciones.isEmpty
        ? _noTr()
        : Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, widget.bottomPad),
            child: RefreshIndicator(
              onRefresh: _refresh,
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
                  return CardTrPistero(
                    
                    product: p,
                    lista: 'zona-${widget.zona}',
                    onItemSelected: (prod) {
                      widget.onItemSelected(prod);
                      Navigator.of(context).pop();
                    },
                    showPrintIcon: widget.showPrintIcon,
                    onPrint: widget.onPrintTap == null ? null : () => widget.onPrintTap!(p),
                  );
                },
              ),
            ),
          );

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        height: widget.height,
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
                      onPressed: _refresh,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 52),
              child: content,
            ),
            if (_loading)
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
  }
}
