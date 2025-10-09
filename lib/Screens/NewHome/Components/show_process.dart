import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/card_tr.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cierrefinal.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/transaccion.dart';

import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Providers/tranascciones_provider.dart';



import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

import 'package:tester/sizeconfig.dart';

// ---------------------------------------------------------------
//  EXTENSIÓN: Transaccion -> Product  (para flujo de facturación)
// ---------------------------------------------------------------

extension LegacyTxToProduct on Transaccion {
  Product toInvoiceProduct({
    required String codigoArticulo,      // SKU inventario
    String tipoArticulo = 'Combustible',
    String unidad = 'L',
    String? detalle,
    String imageUrl = 'NoImage.jpg',
    int inventario = 0,
    int rateId = 0,
    int taxId = 0,
    String codigoCabys = '',
    double tasaImp = 0,
    double impMonto = 0,
    double precioCompra = 0,
    List<String> images = const [],
    List<Color> colors = const [],
  }) {
    final isExo = estado.toLowerCase().contains('exoner');
    final desc = detalle ??
        (isExo
            ? 'Comb Exonerado'
            : (nombreproducto.isNotEmpty ? nombreproducto : 'Combustible'));

    return Product(
      cantidad: volumen,
   
      codigoArticulo: codigoArticulo,
   
      detalle: desc,
      precioUnit: preciounitario.toDouble(),    
      subtotal: total.toDouble() - impMonto,
      tasaImp: tasaImp,
      impMonto: impMonto,
      total: total.toDouble(),    
      transaccion: idtransaccion,        
      dispensador: dispensador,
      imageUrl: imageUrl,
      inventario: inventario,
      images: images,
      colors: colors,
    );
  }
}

class ShowProcessMenu extends StatefulWidget {
  final CierreFinal cierreFinal;

  const ShowProcessMenu({
    super.key,
    required this.cierreFinal,
  });

  @override
  State<ShowProcessMenu> createState() => _ShowProcessMenuState();
}

class _ShowProcessMenuState extends State<ShowProcessMenu> {
  bool _showLoader = false;
  List<Product> transacciones = [];
  final List<Product> cart = [];

  int _selectedIndex = -1;
  String state = '';

  // ⚠️ Mantengo exactamente tus etiquetas y valores
  final List<String> buttonNames = const [
    'Efectivo', 'Tar BAC','Tar BN','Tar DAV',
    'Tar SCO', 'Cheque','Calibracion', 
    'Exonerado', 'Cupones',  'Dollar', 'Procesar',
  ];

  final List<String> estados = const [
    'Efectivo', 'Tarjeta_Bac','Tarjeta_Bn','Tarjeta_Dav',
    'Tarjeta_Scotia','Cheque',
    'Calibracion', 'Exonerado', 'Cupones',
    'Dollar', 'Procesar',
  ];

  static const int _cols = 4;
  static const double _tileExtent = 74;      // alto fijo de cada tile del grid de pagos
  static const double _gridMainSpacing = 8;  // separación vertical entre filas
  static const double _gridPadTop = 8;
  static const double _gridPadBottom = 12;

  double _paymentPanelHeight() {
    final rows = (buttonNames.length + _cols - 1) ~/ _cols;
    final tilesHeight = rows * _tileExtent + (rows - 1) * _gridMainSpacing;
    // + Divider (1px) y paddings
    return 1 + _gridPadTop + tilesHeight + _gridPadBottom;
  }

  @override
  void initState() {
    super.initState();
    _updateTransactions(); // ahora desde TransaccionesProvider (legacy)
  }

  @override
  Widget build(BuildContext context) {
    final lastIndex = buttonNames.length - 1;
    final double panelH = _paymentPanelHeight();
    return SafeArea(
      child: Scaffold(
        appBar: MyCustomAppBar(
          title: 'Procesar Transacciones',
          elevation: 3,
          shadowColor: kPrimaryColor,
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kBlueColorLogo,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image.asset(
                  'assets/splash.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Contenido principal con espacio reservado para el panel inferior
            Padding(
              padding: EdgeInsets.only(bottom: panelH),
              child: Container(
                color: kNewsurface,
                child: Column(
                  children: <Widget>[
                    // ---- Transacciones (ocupa todo lo disponible) ----
                    Expanded(
                      child: transacciones.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
                              child: RefreshIndicator(
                                onRefresh: () async => _updateTransactions(),
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: transacciones.length,
                                  itemBuilder: (context, indice) {
                                    final p = transacciones[indice];
                                    return CardTr(
                                      product: p,
                                      lista: 'Tr',
                                      onItemSelected: onItemSelected,
                                      selected: p.isFavourite,
                                    );
                                  },
                                ),
                              ),
                            )
                          : _noTr(),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 2, color: kNewtextPri),
                  ],
                ),
              ),
            ),

            // Panel inferior ANCLADO con el grid de métodos (incluye "Procesar" como ÚLTIMO tile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Material(
                  color: kNewsurface,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, _gridPadTop, 8, _gridPadBottom),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: buttonNames.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _cols,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: _gridMainSpacing,
                        mainAxisExtent: _tileExtent,   // asegura altura exacta por fila
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final isProcess = index == lastIndex;
                        if (isProcess) {
                          return _PaymentTile.process(
                            label: buttonNames[index],
                            onTap: _goProcess,
                          );
                        }
                        final selected = _selectedIndex == index;
                        return _PaymentTile.option(
                          label: buttonNames[index],
                          icon: _iconForMethod(buttonNames[index]),
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              state = estados[index];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            if (_showLoader) const LoaderComponent(loadingText: 'Procesando...'),
          ],
        ),
      ),
    );
  }

  // ---------- selección en cards ----------
  void onItemSelected(Product product) {
    setState(() {
      product.isFavourite = !product.isFavourite;
      if (product.isFavourite) {
        cart.add(product);
      } else {
        cart.removeWhere((p) => p.transaccion == product.transaccion);
      }
    });
  }

  Widget _noTr() {
    return Container(
      color: kColorFondoOscuro,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: InkWell(
              onTap: () => _updateTransactions(),
              child: Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(5)),
                height: 100,
                width: 100,
                color: kColorFondoOscuro,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(5)),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Image(
                      image: AssetImage('assets/NoTr.png'),
                      fit: BoxFit.cover,
                      height: 70,
                      width: 70,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'No Hay Transacciones',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(18),
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(height: getProportionateScreenWidth(10)),
        ],
      ),
    );
  }

  // ---------- Cargar desde TransaccionesProvider.unpaid ----------
  Future<void> _updateTransactions() async {
    setState(() => _showLoader = true);

    // 1) Tomar impagas desde el provider (legacy)
    final txProv = Provider.of<TransaccionesProvider>(context, listen: false);
    final List<Transaccion> unpaid = txProv.unpaid;

    // 2) Convertir a Product usando la extensión nueva
    final mapped = unpaid.map((tx) {
      final isExo = tx.estado.toLowerCase().contains('exoner');
      final sku = 'FUEL-${tx.idproducto}';
      final detalle = isExo
          ? 'Comb Exonerado'
          : (tx.nombreproducto.isNotEmpty ? tx.nombreproducto : 'Combustible');

      return tx.toInvoiceProduct(
        codigoArticulo: sku,
        detalle: detalle,
      );
    }).toList();

    // 3) Filtros locales: excluir productos ya en facturas y los del carrito
    List<Invoice> facturas = [];
    if (mounted) {
      facturas = Provider.of<FacturasProvider>(context, listen: false).facturas;
    }
    List<Product> filtrados = filtrarProductosNoEnFacturas(mapped, facturas);

    for (final c in cart) {
      filtrados.removeWhere((p) => p.transaccion == c.transaccion);
    }

    setState(() {
      transacciones = filtrados;
      _showLoader = false;
    });
  }

  List<Product> filtrarProductosNoEnFacturas(List<Product> productosABuscar, List<Invoice> facturas) {
    final List<Product> productosFiltrados = List<Product>.from(productosABuscar);
    for (final factura in facturas) {
      if (factura.detail != null) {
        for (final productoFactura in factura.detail!) {
          productosFiltrados.removeWhere(
            (p) => p.transaccion == productoFactura.transaccion,
          );
        }
      }
    }
    return productosFiltrados;
  }

  // ---------- Procesar ----------
  Future<void> _goProcess() async {
    if (cart.isEmpty) {
      Fluttertoast.showToast(
        msg: "Seleccione transacciones para procesar.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (state.isEmpty || state == 'Procesar') {
      Fluttertoast.showToast(
        msg: "Seleccione el tipo de pago.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validaciones de exonerado
    bool validate = false;
    bool validate2 = false;

    if (state == 'Exonerado') {
      for (var item in cart) {
        if (item.detalle != 'Comb Exonerado') {
          validate = true;
          break;
        }
      }
    } else {
      for (var item in cart) {
        if (item.detalle == 'Comb Exonerado') {
          validate2 = true;
          break;
        }
      }
    }

    if (validate) {
      Fluttertoast.showToast(
        msg: "Todas las transacciones deben ser de Exonerado.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (validate2) {
      Fluttertoast.showToast(
        msg: "La transaccion no corresponde exonerado.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _showLoader = true);

    final Map<String, dynamic> request = {
      'products': cart.map((e) => e.toApiProducJson()).toList(),
      'idCierre': widget.cierreFinal.idcierre,
      'estado': state,
    };

    final Response response = await ApiHelper.post("Api/Facturacion/ProcessTransactions", request);

    setState(() => _showLoader = false);

    if (!response.isSuccess) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    Fluttertoast.showToast(
      msg: "Transacciones Procesadas \n Correctamente",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: const Color.fromARGB(255, 10, 75, 4),
      textColor: Colors.white,
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  // ---------- UI helpers para métodos de pago ----------
  IconData _iconForMethod(String label) {
    final l = label.toLowerCase();
    if (l.contains('efectivo')) return Icons.payments_rounded;
    if (l.contains('cheque')) return Icons.receipt_long_rounded;
    if (l.contains('cupon')) return Icons.local_offer_rounded;
    if (l.contains('calibr')) return Icons.build_circle_rounded;
    if (l.contains('dollar')) return Icons.attach_money_rounded;
    if (l.contains('tar')) return Icons.credit_card_rounded; // Tar BAC/DAV/SCO/BN
    if (l.contains('exo')) return Icons.verified_user_rounded;
    return Icons.payment_rounded;
  }
}

/// Tile para métodos de pago (opción y botón procesar)
class _PaymentTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isProcess;

  const _PaymentTile.option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  })  : isProcess = false;

  const _PaymentTile.process({
    required this.label,
    required this.onTap,
  })  : icon = Icons.send_rounded,
        selected = false,
        isProcess = true;

  @override
  Widget build(BuildContext context) {
    if (isProcess) {
      // Botón "Procesar" destacado
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    // Opción de método
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF243149) : const Color(0xFFE7E8EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF5B8CFF) : const Color(0xFFCBD3E1),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF243149),
                ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF243149),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
