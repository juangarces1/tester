import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/form_pago_v2.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_actividad_select.dart';
import 'package:tester/Components/show_client.dart';
import 'package:tester/Components/show_email.dart';
import 'package:tester/Components/transacciones_sheet.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

// ignore: must_be_immutable
class CheaOutScreen extends StatefulWidget {
  final int index;

  const CheaOutScreen({
    super.key,
    required this.index,
  });

  @override
  State<CheaOutScreen> createState() => _CheaOutScreenState();
}

class _CheaOutScreenState extends State<CheaOutScreen> {
  bool _showLoader = false;

  late final ExpansibleController _pagoCtrl;
  // Solo UI controllers (estado efÃ­mero)
  late TextEditingController kms;
  late TextEditingController obser;
  late TextEditingController placa;

  final GlobalKey<FormPagoV2State> formPagoKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double? _lastInvoiceTotal;
  bool _refreshScheduled = false;

  bool _shouldResetForm(Invoice factura) {
    final form = factura.formPago;
    if (form == null) return false;
    final double settled = (factura.total - factura.saldo).abs();
    const double epsilon = 0.001;
    return settled > epsilon;
  }

  void callGoRefresh() {
    formPagoKey.currentState?.goRefresh(); // solo UI refresh del hijo
  }

  @override
  void initState() {
    super.initState();
    _pagoCtrl = ExpansibleController();
    // Inicializa desde la fuente de verdad (Provider) UNA SOLA VEZ.
    final inv = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
    _lastInvoiceTotal = inv.total;

    kms = TextEditingController(text: inv.kms.toString());
    obser = TextEditingController(text: inv.observaciones.toString());
    placa = TextEditingController(text: inv.placa.toString());
  }

  @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    placa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ÃšNICA FUENTE DE VERDAD (reactiva)
    final Invoice factura = Provider.of<FacturasProvider>(context, listen: true)
        .getInvoiceByIndex(widget.index);

    final double currentTotal = factura.total;
    if (_lastInvoiceTotal == null) {
      _lastInvoiceTotal = currentTotal;
    } else if (currentTotal != _lastInvoiceTotal && !_refreshScheduled) {
      final bool shouldReset = _shouldResetForm(factura);
      _refreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _refreshScheduled = false;
          return;
        }
        if (shouldReset) {
          callGoRefresh();
          _pagoCtrl.expand();
          FocusScope.of(context).unfocus();
        }
        setState(() {
          _lastInvoiceTotal = currentTotal;
          _refreshScheduled = false;
        });
      });
    }

    // Auto-colapsar cuando saldo == 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (factura.saldo == 0 && _pagoCtrl.isExpanded) {
        _pagoCtrl.collapse();
        FocusScope.of(context).unfocus();
      }
    });

    SizeConfig().init(context);

    // Color para Contado (igual que en FacturacionPageV2)
    const contadoColor = Color(0xFFF97316); // Orange

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF12151A),
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ═══════════════════════════════════════════════════════════════
                // SLIVER APP BAR - Moderno con floating + snap
                // ═══════════════════════════════════════════════════════════════
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 80,
                  collapsedHeight: 80,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          contadoColor.withOpacity(0.9),
                          contadoColor.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: contadoColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Botón Back
                          GestureDetector(
                            onTap: () {
                              FacturaService.updateFactura(context, factura);
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Título y badge productos
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${factura.numeroProductos} items',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Saldo - solo mostrar si hay productos
                          if (factura.total > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: factura.saldo == 0
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: factura.saldo == 0
                                      ? Colors.greenAccent.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    factura.saldo == 0 ? '✓ Pagado' : 'Saldo',
                                    style: TextStyle(
                                      color: factura.saldo == 0
                                          ? Colors.greenAccent
                                          : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    VariosHelpers.formattedToCurrencyValue(
                                      factura.saldo.toString(),
                                    ),
                                    style: TextStyle(
                                      color: factura.saldo == 0
                                          ? Colors.greenAccent
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════════════════════════
                // CONTENIDO PRINCIPAL
                // ═══════════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      callGoRefresh();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          CartInlineCompact(
                            index: widget.index,
                            onAddTransactions: () => TransaccionesSheet.open(
                              context: context,
                              zona: factura.cierre!.idzona!,
                              onItemSelected: (p) {
                                final prov = context.read<FacturasProvider>();
                                final inv =
                                    prov.getInvoiceByIndex(widget.index);
                                inv.detail ??= [];
                                inv.detail!.add(p);
                                FacturaService.updateFactura(context, inv);
                              },
                              showPrintIcon: true,
                              onPrintTap: (p) {/* ... */},
                            ),
                            onAddProducts: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductsPage(index: widget.index)));
                            },
                          ),

                          const SizedBox(height: 8),
                          FormPagoV2(
                            key: formPagoKey,
                            index: widget.index,
                            fontColor: kNewtextPri,
                            ruta: 'Contado',
                            expansibleController: _pagoCtrl,
                          ),

                          const SizedBox(height: 8),
                          signUpForm(factura),
                          const SizedBox(height: 8),
                          factura.total > 0 ? showTotal(factura) : Container(),

                          // Espacio para el botón flotante
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ═══════════════════════════════════════════════════════════════
            // BOTÓN FACTURAR (flotante, aparece cuando saldo == 0)
            // ═══════════════════════════════════════════════════════════════
            if (factura.saldo == 0 && (factura.detail?.isNotEmpty == true))
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF97316),
                          Color(0xFFEA580C)
                        ], // Orange
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => goFact(factura),
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Facturar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Loader
            if (_showLoader)
              const LoaderComponent(loadingText: "Creando Factura..."),
          ],
        ),
      ),
    );
  }

  void onItemSelected(Product product) {
    final prov = context.read<FacturasProvider>();
    final inv = prov.getInvoiceByIndex(widget.index);

    // MutaciÃ³n sobre la instancia del provider:
    inv.detail ??= <Product>[];
    inv.detail!.add(product);

    // Centraliza el notify y cÃ¡lculos
    FacturaService.updateFactura(context, inv);
  }

  // Pasa la factura del Provider para pintar y mutar vÃ­a servicio
  Widget signUpForm(Invoice factura) {
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: kNewsurfaceHi,
      labelStyle: const TextStyle(
        color: kNewtextPri,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: kNewtextMut),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewborder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewgreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
      suffixIconColor: kNewtextSec,
    );

    final theme = Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
      canvasColor: Colors.transparent,
      inputDecorationTheme: inputTheme,
    );

    return Theme(
      data: theme,
      child: Container(
        decoration: BoxDecoration(
          color: kNewsurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kNewborder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          title: const Text(
            'Cliente y Otros Campos',
            style: TextStyle(
              color: kNewtextPri,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconColor: kNewtextPri,
          collapsedIconColor: kNewtextPri,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF111825), Color(0xFF0B101B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  ShowClient(
                    tipo: ClienteTipo.contado,
                    factura: factura, // â† provider
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),

                  if (factura.formPago!.clienteFactura.nombre.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ShowEmail(
                        email: factura.formPago!.clienteFactura.email,
                        backgroundColor: kNewsurfaceHi,
                      ),
                    ),
                  if (factura.tieneCodigoActividad)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ShowActividadSelect(
                        actividad: factura
                            .formPago!.clienteFactura.actividadSeleccionada!,
                      ),
                    ),
                  const SizedBox(height: 10),
                  //  Padding(
                  //   padding:const EdgeInsets.symmetric(horizontal: 20),
                  //   child: ClientPoints(factura: factura, ruta: 'Contado'),
                  // ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.more_horiz, color: kNewtextPri),
                    label: const Text('Otros Campos  ',
                        style: TextStyle(
                            color: kNewtextPri, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kNewborder),
                      backgroundColor: kNewsurfaceHi,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openOtrosCamposModal(factura),
                  ),

                  // _otrosCamposSummary(factura),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showTotal(Invoice factura) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF97316).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            VariosHelpers.formattedToCurrencyValue(factura.total.toString()),
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFFF97316), // Orange
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Campos: mutan SIEMPRE la del provider (vÃ­a servicio)
  Widget showkms(Invoice factura) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: TextField(
        style: const TextStyle(
          color: kNewtextPri,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: kNewgreen,
        controller: kms,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        decoration: const InputDecoration(
          hintText: 'Ingrese los kms',
          labelText: 'Kms',
          suffixIcon: Icon(Icons.car_repair_rounded),
        ),
        onChanged: (value) {
          // Nada de setState para negocio
          final inv =
              context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
          inv.kms = (value.isEmpty) ? 0 : int.parse(value);
          FacturaService.updateFactura(context, inv);
        },
      ),
    );
  }

  Widget showObser(Invoice factura) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: TextField(
        style: const TextStyle(
          color: kNewtextPri,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: kNewgreen,
        controller: obser,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          labelText: 'Observaciones',
          hintText: 'Ingrese las Observaciones',
          suffixIcon: Icon(Icons.sms_outlined),
        ),
        onChanged: (value) {
          final inv =
              context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
          inv.observaciones = value;
          FacturaService.updateFactura(context, inv);
        },
      ),
    );
  }

  Widget showPlaca(Invoice factura) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: TextField(
        style: const TextStyle(
          color: kNewtextPri,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: kNewgreen,
        controller: placa,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          labelText: 'Placa',
          hintText: 'Ingrese la Placa',
          suffixIcon: Icon(Icons.sms_outlined),
        ),
        onChanged: (value) {
          final inv =
              context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
          inv.placa = value;
          FacturaService.updateFactura(context, inv);
        },
      ),
    );
  }

  Widget appBar1(Invoice facturaApp) {
    return Container(
      color: kNewredPressed,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: getProportionateScreenHeight(38),
              width: getProportionateScreenWidth(38),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60),
                  ),
                  backgroundColor: kNewtextPri,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  // Opcional: persistir antes de salir
                  FacturaService.updateFactura(context, facturaApp);
                  Navigator.pop(context);
                },
                child: SvgPicture.asset(
                  "assets/Back ICon.svg",
                  height: 15,
                  // ignore: deprecated_member_use
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            //   decoration: BoxDecoration(
            //     color: kNewred.withValues(alpha: .18),
            //     borderRadius: BorderRadius.circular(10),
            //     border: Border.all(color: kContrateFondoOscuro, width: 1),
            //   ),
            //   child: const Text(
            //     "CONTADO",
            //     style: TextStyle(
            //       color: kNewtextPri,
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            const Text(
              'Contado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kNewtextPri,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 8, right: 5),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Saldo: ${VariosHelpers.formattedToCurrencyValue(facturaApp.saldo.toString())}",
                    style: const TextStyle(
                      color: kNewtextPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> goFact(Invoice facturaApp) async {
    // Chequea SIEMPRE con la del provider (no variable local)
    if (facturaApp.saldo != 0) {
      Fluttertoast.showToast(
        msg: "La factura aun tiene saldo.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 70, 19, 15),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      _showLoader = true;
    });

    final request = {
      'products': facturaApp.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre': facturaApp.cierre!.idcierre,
      'cedualaUsuario': facturaApp.empleado!.cedulaEmpleado.toString(),
      'clienteFactura': facturaApp.formPago!.clienteFactura.toJson(),
      'totalEfectivo': facturaApp.formPago!.totalEfectivo,
      'totalBac': facturaApp.formPago!.totalBac,
      'totalDav': facturaApp.formPago!.totalDav,
      'totalBn': facturaApp.formPago!.totalBn,
      'totalSctia': facturaApp.formPago!.totalSctia,
      'totalSinpe': facturaApp.formPago!.totalSinpe,
      'totalDollars': facturaApp.formPago!.totalDollars,
      'totalCheques': facturaApp.formPago!.totalCheques,
      'totalCupones': facturaApp.formPago!.totalCupones,
      'totalPuntos': facturaApp.formPago!.totalPuntos,
      'totalTransfer': facturaApp.formPago!.totalTransfer,
      'saldo': facturaApp.saldo,
      'clientePuntos': facturaApp.formPago!.clientePuntos.toJson(),
      'Transferencia': facturaApp.formPago!.transfer.toJson(),
      'kms': kms.text.isEmpty ? '0' : kms.text,
      'placa': placa.text.isEmpty ? '' : placa.text,
      'sinpe': facturaApp.formPago!.sinpe.toJson(),
      'observaciones': obser.text.isEmpty ? '' : obser.text,
      'isticket': false,
      'isCredit': false,
      'plazo': 0,
      'isContado': true,
    };

    final Response response =
        await ApiHelper.post("Api/Facturacion/FacturaSp", request);

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(response.message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    final decodedJson = jsonDecode(response.result);
    final Factura resdocFactura = Factura.fromJson(decodedJson);
    resdocFactura.usuario = facturaApp.empleado?.nombreCompleto;

    if (facturaApp.acumulaPuntos) {
      await _handleAcumulaPuntosPrint(
        facturaApp,
        facturaApp.empleado?.nombreCompleto ?? '',
      );
    }

    if (facturaApp.tieneTransferencia) {
      await _handleTransferenciaPrint(facturaApp);
    }

    if (facturaApp.canjeaPuntos) {
      await _handleCanjeaPuntosPrint(facturaApp);
    }

    if (facturaApp.tieneSinpe) {
      await _handleSinpePrint(facturaApp);
    }

    if (!mounted) return;

    final bool shouldPrint = await _confirmPrintFactura();
    if (shouldPrint) {
      await _handleFacturaPrint(resdocFactura);
    }

    await _goHomeSuccess(facturaApp);
  }

  Future<bool> _confirmPrintFactura() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Imprimir factura'),
          content: const Text('Desea imprimir la factura?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Si'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleFacturaPrint(Factura factura) async {
    const String tipoDocumento = 'CONTADO';

    const String tipoCliente = 'CONTADO';

    try {
      final tp = TestPrint(totalChars: 32);
      Fluttertoast.showToast(msg: 'Factura enviada a impresion');
      await tp.printFactura(factura, tipoDocumento, tipoCliente);
    } catch (err, st) {
      debugPrint('handleFacturaPrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir la factura');
    }
  }

  Future<void> _handleAcumulaPuntosPrint(
    Invoice facturaC,
    String pistero,
  ) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printPuntosAcumulados(
        facturaC.formPago!.clientePuntos.nombre,
        pistero,
        facturaC.formPago!.clientePuntos.documento,
        facturaC.detail!,
      );
    } catch (err, st) {
      debugPrint('handleAcumulaPuntosPrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir los puntos acumulados');
    }
  }

  Future<void> _handleCanjeaPuntosPrint(
    Invoice facturaC,
  ) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printPuntosCanje(
        facturaC.formPago!.clientePuntos.nombre,
        facturaC.empleado!.nombreCompleto,
        facturaC.formPago!.clientePuntos.puntos,
        facturaC.formPago!.clientePuntos.documento,
        facturaC.formPago!.totalPuntos,
      );
    } catch (err, st) {
      debugPrint('handleCanjeaPuntosPrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir los puntos canjeados');
    }
  }

  Future<void> _handleSinpePrint(
    Invoice facturaC,
  ) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printSinpe(
        facturaC.formPago!.sinpe,
        facturaC.empleado!.nombreCompleto,
      );
    } catch (err, st) {
      debugPrint('handleSinpePrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir el SINPE');
    }
  }

  Future<void> _handleTransferenciaPrint(Invoice facturaC) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printTransferencia(
        facturaC.formPago!.transfer,
        facturaC.empleado!.nombreCompleto,
      );
    } catch (err, st) {
      debugPrint('handleTransferenciaPrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir la transferencia');
    }
  }

  Future<void> _goHomeSuccess(Invoice facturaC) async {
    // Centraliza la eliminaciÃ³n en el servicio (notificarÃ¡ al provider)
    FacturaService.eliminarFactura(context, facturaC);
    if (mounted) Navigator.pop(context);
  }

  void _openOtrosCamposModal(Invoice factura) async {
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: kNewsurfaceHi,
      labelStyle: const TextStyle(
        color: kNewtextPri,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: kNewtextMut),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewborder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewgreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNewred),
      ),
      suffixIconColor: kNewtextSec,
    );

    final theme = Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
      canvasColor: Colors.transparent,
      inputDecorationTheme: inputTheme,
    );

    FocusScope.of(context).unfocus(); // cierra teclado en la pantalla base
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: BoxDecoration(
              color: kNewsurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: kNewborder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: kNewborder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Otros campos de la factura',
                    style: TextStyle(
                      color: kNewtextPri,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // KMS
                  Theme(
                    data: theme,
                    child: TextField(
                      style: const TextStyle(
                          color: kNewtextPri, fontWeight: FontWeight.w600),
                      cursorColor: kNewgreen,
                      controller: kms,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Ingrese los kms',
                        labelText: 'Kms',
                        suffixIcon: Icon(Icons.car_repair_rounded),
                      ),
                      onChanged: (value) {
                        final inv = context
                            .read<FacturasProvider>()
                            .getInvoiceByIndex(widget.index);
                        inv.kms = (value.isEmpty) ? 0 : int.parse(value);
                        FacturaService.updateFactura(context, inv);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // PLACA
                  Theme(
                    data: theme,
                    child: TextField(
                      style: const TextStyle(
                          color: kNewtextPri, fontWeight: FontWeight.w600),
                      cursorColor: kNewgreen,
                      controller: placa,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Placa',
                        hintText: 'Ingrese la Placa',
                        suffixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      onChanged: (value) {
                        final inv = context
                            .read<FacturasProvider>()
                            .getInvoiceByIndex(widget.index);
                        inv.placa = value;
                        FacturaService.updateFactura(context, inv);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // OBSERVACIONES
                  Theme(
                    data: theme,
                    child: TextField(
                      style: const TextStyle(
                          color: kNewtextPri, fontWeight: FontWeight.w600),
                      cursorColor: kNewgreen,
                      controller: obser,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        hintText: 'Ingrese las Observaciones',
                        suffixIcon: Icon(Icons.notes_outlined),
                      ),
                      onChanged: (value) {
                        final inv = context
                            .read<FacturasProvider>()
                            .getInvoiceByIndex(widget.index);
                        inv.observaciones = value;
                        FacturaService.updateFactura(context, inv);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kNewborder),
                            foregroundColor: kNewtextPri,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Asegura última sincronía con Provider
                            final inv = context
                                .read<FacturasProvider>()
                                .getInvoiceByIndex(widget.index);
                            inv.kms =
                                (kms.text.isEmpty) ? 0 : int.parse(kms.text);
                            inv.placa = placa.text;
                            inv.observaciones = obser.text;
                            FacturaService.updateFactura(context, inv);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _otrosCamposSummary(Invoice f) {
  //   final chips = <Widget>[];
  //   if ((f.kms ?? 0) > 0) {
  //     chips.add(_miniChip('Kms: ${f.kms}'));
  //   }
  //   if ((f.placa ?? '').trim().isNotEmpty) {
  //     chips.add(_miniChip('Placa: ${f.placa!.toUpperCase()}'));
  //   }
  //   if ((f.observaciones ?? '').trim().isNotEmpty) {
  //     chips.add(_miniChip('Obs.'));
  //   }
  //   if (chips.isEmpty) {
  //     return const SizedBox.shrink();
  //   }
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Wrap(spacing: 8, runSpacing: 6, children: chips),
  //   );
  // }

  // Widget _miniChip(String text) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: kNewsurfaceHi,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: kNewborder),
  //     ),
  //     child: Text(text,
  //         style:
  //             const TextStyle(color: kNewtextSec, fontWeight: FontWeight.w600)),
  //   );
  // }
}
