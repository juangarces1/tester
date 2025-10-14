import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_actividad_select.dart';
import 'package:tester/Components/show_client.dart';
import 'package:tester/Components/show_email.dart';
import 'package:tester/Components/transacciones_sheet.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/factura.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';

import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
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

  final GlobalKey<FormPagoState> formPagoKey = GlobalKey();
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
    // final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    // final bool isKeyboardVisible = keyboardInset > 0;
    // const double bottomOffset = 15;

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: appBar1(factura),
        ),
        body: Container(
          color: kNewborder,
          child: Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: () async {
                  callGoRefresh(); // refresco visual de FormPago si lo necesitas
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 10),
                        CartInlineCompact(
                          index: widget.index,
                          onAddTransactions: () => TransaccionesSheet.open(
                            context: context,
                            zona: factura.cierre!.idzona!,
                            onItemSelected: (p) {
                              final prov = context.read<FacturasProvider>();
                              final inv = prov.getInvoiceByIndex(widget.index);
                              inv.detail ??= [];
                              inv.detail!.add(p);
                              FacturaService.updateFactura(context, inv);
                            },
                            // opcionales:
                            showPrintIcon: false,
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

                        const SizedBox(height: 10),
                        // Pasa SIEMPRE la del provider
                         FormPago(
                          key: formPagoKey,
                          index: widget.index,
                          fontColor: kNewtextPri,
                          ruta: 'Contado',
                          expansibleController: _pagoCtrl, // ðŸ‘ˆ pÃ¡salo
                        ),
                        
                       
                        const SizedBox(height: 10),
                        signUpForm(factura),
                        const SizedBox(height: 5),

                        // Elegibilidad del CTA SIEMPRE con la del provider
                        (factura.detail?.isNotEmpty == true) &&
                                factura.saldo == 0 &&
                                factura
                                    .formPago!.clienteFactura.nombre.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    left: 50.0, right: 50, bottom: 15),
                                child: DefaultButton(
                                  text: "Facturar",
                                  press: () => goFact(factura),
                                  gradient: kPrimaryGradientColor,
                                  color: kPrimaryColor,
                                ),
                              )
                            : Container(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
              // if (!isKeyboardVisible)
              //   Positioned(
              //     bottom: bottomOffset,
              //     left: 80,
              //     child: SizedBox(
              //       height: 56,
              //       width: 56,
              //       child: GestureDetector(
              //         onTap: () => Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) =>
              //                 ProductsPage(index: widget.index),
              //           ),
              //         ),
              //         child: ClipRRect(
              //           borderRadius: BorderRadius.circular(10),
              //           child: Image.asset(
              //             'assets/AceiteNoFondo.png',
              //             fit: BoxFit.fill,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // if (!isKeyboardVisible)
              //   Positioned(
              //     bottom: bottomOffset,
              //     left: 10,
              //     child: BotonTransacciones(
              //       imagePath: 'assets/AddTr.png',
              //       onItemSelected: onItemSelected, // ver abajo
              //       zona: factura.cierre!.idzona!,
              //     ),
              //   ),
              _showLoader
                  ? const LoaderComponent(loadingText: "Creando Factura...")
                  : Container(),
            ],
          ),
        ),
        // floatingActionButton: isKeyboardVisible
        //     ? null
        //     : FloatingButtonWithModal(index: widget.index),
      ),
    );
  }

  // â† MutaciÃ³n SOLO vÃ­a Provider/Service (sin setState de negocio)
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

    return Container(
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
      child: Theme(
        data: theme,
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          title: const Text(
            'Información de la Factura',
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
                    Padding(
                      padding:const EdgeInsets.symmetric(horizontal: 20),
                      child: ClientPoints(factura: factura, ruta: 'Contado'),
                    ),
                  const SizedBox(height: 15),
                  ShowClient(
                    tipo: ClienteTipo.contado,
                    factura: factura, // â† provider
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 8),
                  if (factura.formPago!.clienteFactura.nombre.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ShowEmail(
                        email: factura.formPago!.clienteFactura.email,
                        backgroundColor: kNewsurfaceHi,
                      ),
                    ),
                  if (factura.formPago!.clienteFactura.actividadSeleccionada !=
                      null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ShowActividadSelect(
                        actividad: factura
                            .formPago!.clienteFactura.actividadSeleccionada!,
                      ),
                    ),
                  const SizedBox(height: 20),
                  showkms(factura),
                  const SizedBox(height: 18),
                  showPlaca(factura),
                  const SizedBox(height: 18),
                  showObser(factura),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
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
              height: getProportionateScreenHeight(35),
              width: getProportionateScreenWidth(35),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kNewred.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kContrateFondoOscuro, width: 1),
              ),
              child: const Text(
                "CONTADO",
                style: TextStyle(
                  color: kNewtextPri,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                    "Total:${NumberFormat("###,###", "en_US").format(facturaApp.total.toInt())}",
                    style: const TextStyle(
                      color: kNewtextPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "Saldo:${NumberFormat("###,###", "en_US").format(facturaApp.saldo)}",
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
    };

    final Response response =
        await ApiHelper.post("Api/Facturacion/PostFactura", request);

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
    resdocFactura.usuario = facturaApp.empleado!.nombreCompleto;

    _goHomeSuccess(facturaApp);
  }

  Future<void> _goHomeSuccess(Invoice facturaC) async {
    // Centraliza la eliminaciÃ³n en el servicio (notificarÃ¡ al provider)
    FacturaService.eliminarFactura(context, facturaC);
    if (mounted) Navigator.pop(context);
  }
}
