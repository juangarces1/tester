import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/transacciones_sheet.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/factura.dart';

import 'package:tester/Models/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

// ignore: must_be_immutable
class TicketScreen extends StatefulWidget {
  final int index;

  const TicketScreen({super.key, required this.index});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  // UI state
  late final ExpansibleController _pagoCtrl;
  final GlobalKey<FormPagoState> formPagoKey = GlobalKey<FormPagoState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _obserCtrl;

  bool _showLoader = false;
  double? _lastInvoiceTotal;
  bool _refreshScheduled = false;

  bool _shouldResetForm(Invoice factura) {
    final form = factura.formPago;
    if (form == null) return false;
    final double settled = (factura.total - factura.saldo).abs();
    const double epsilon = 0.001;
    return settled > epsilon;
  }

  @override
  void initState() {
    super.initState();
    _pagoCtrl = ExpansibleController();
    // Observaciones iniciales desde provider (solo para pintar/capturar texto)
    final inv =
        Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    _obserCtrl = TextEditingController(text: inv.observaciones ?? '');
    _lastInvoiceTotal = inv.total;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _obserCtrl.dispose();
    super.dispose();
  }

  void callGoRefresh() => formPagoKey.currentState?.goRefresh();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    // Factura reactiva SIEMPRE desde el provider
    final factura = context.watch<FacturasProvider>().getInvoiceByIndex(widget.index);

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

    // Si el saldo llegó a 0 y el acordeón está abierto, colapsarlo.
    if (factura.saldo == 0 && _pagoCtrl.isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pagoCtrl.collapse());
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: _appBar(factura),
        ),
        body: Stack(
          children: <Widget>[
            RefreshIndicator(
              onRefresh: () async => callGoRefresh(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 10),
                     
                     CartInlineCompact(
                          index: widget.index,
                          onAddTransactions: () => TransaccionesSheet.open(
                              context: context,
                              zona: factura.cierre!.idzona!,
                              onItemSelected: (p) {
                                final prov = context.read<FacturasProvider>();
                                final inv  = prov.getInvoiceByIndex(widget.index);
                                inv.detail ??= [];
                                inv.detail!.add(p);
                                FacturaService.updateFactura(context, inv);
                              },
                              // opcionales:
                              showPrintIcon: false,
                              onPrintTap: (p) { /* ... */ },
                            ),
                          onAddProducts: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ProductsPage(index: widget.index)));
                          },
                        ),
                      const SizedBox(height: 15),
                        FormPago(
                        key: formPagoKey,
                        index: widget.index,
                        fontColor: kNewtextPri,
                        ruta: 'Ticket',
                        expansibleController: _pagoCtrl,
                      ),
        
                      const SizedBox(height: 15),
                      ClientPoints(factura: factura, ruta: 'Contado'),
                      const SizedBox(height: 15),
        
                      // FormPago con controller externo
                    
                      _infoTicketSection(factura),
                      const SizedBox(height: 15),

                       SizedBox(height: SizeConfig.screenHeight * 0.02),
                    factura.total > 0 ? showTotal(factura) : Container(),
                  
        
                      // CTA facturar solo si hay items y saldo 0
                      // if ((factura.detail?.isNotEmpty ?? false) && factura.saldo == 0)
                      //   Padding(
                      //     padding:
                      //         const EdgeInsets.only(left: 50.0, right: 50, bottom: 15),
                      //     child: DefaultButton(
                      //       text: "Facturar",
                      //       press: () => _goTicket(factura),
                      //       color: const Color.fromARGB(255, 17, 50, 19),
                      //       gradient: kGreenGradient,
                      //     ),
                      //   ),
        
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
        
            // Atajos flotantes
            // Positioned(
            //   bottom: 15,
            //   left: 80,
            //   child: GestureDetector(
            //     onTap: () => Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ProductsPage(index: widget.index),
            //       ),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(10),
            //       child:  SizedBox(
            //         height: 56,
            //         width: 56,
            //         child: Image.asset('assets/Aceite1.png'),
            //       ),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   bottom: 15,
            //   left: 10,
            //   child: BotonTransacciones(
            //     imagePath: 'assets/AddTr.png',
            //     zona: factura.cierre!.idzona!,
            //     onItemSelected: _onItemSelected,
            //   ),
            // ),
        
            if (_showLoader)
              const LoaderComponent(loadingText: "Creando Ticket..."),
          ],
        ),
       // floatingActionButton: const FloatingButtonWithModal(index: 0),
      ),
    );
  }

   Widget showTotal(Invoice factura) {
 return SafeArea(
  child: Padding(
    padding:
        EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
    child:
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(           
            
            TextSpan(
              
              text: "Total:\n",
                style: const TextStyle(fontSize: 22, color: kNewtextPri, fontWeight: FontWeight.bold ),
              children: [
                TextSpan(
                  text: " ${VariosHelpers.formattedToCurrencyValue(factura.total.toString())}",
                  style: const TextStyle(fontSize: 22, color: kNewtextPri, fontWeight: FontWeight.bold ),
                ),
              ],
            ),
          ),

            factura.detail!.isNotEmpty && factura.saldo == 0 ? 
                        SizedBox(
                           width: getProportionateScreenWidth(150),
                          child: DefaultButton(
                          text: "Facturar",
                          press: () => _goTicket(factura), 
                          gradient:  kGreenGradient,  
                          color:  const Color.fromARGB(255, 17, 50, 19),         
                          ),
                        )                
                        : Container(),
        ],
      ),
    ),
  );
}

 
  // ------- UI parts -------

  Widget _appBar(Invoice factura) {
    return SafeArea(
      child: Container(
        color: const Color.fromARGB(255, 53, 130, 55),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Row(
            children: [
              SizedBox(
                height: getProportionateScreenHeight(45),
                width: getProportionateScreenWidth(45),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    // Persistimos por las dudas antes de salir
                    FacturaService.updateFactura(context, factura);
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 17, 50, 19),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Ticket',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kNewtextPri,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Total: ${VariosHelpers.formattedToCurrencyValue(factura.total.toString())}",
                      style: const TextStyle(
                        color: kNewtextPri,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Saldo: ${VariosHelpers.formattedToCurrencyValue(factura.saldo.toString())}",
                      style: const TextStyle(
                        color: kNewtextPri,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTicketSection(Invoice factura) {
    return Container(
      padding: const EdgeInsets.only(top: 15),
      decoration: const BoxDecoration(
        color: kNewsurfaceHi,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Información Ticket',
            style: TextStyle(
              color: kNewtextPri,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),
          _obserField(factura),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _obserField(Invoice factura) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: _obserCtrl,
        keyboardType: TextInputType.text,
        maxLines: 2,
        style: const TextStyle(color: kNewtextPri, fontSize: 19),
        cursorColor: Colors.green,
        decoration: darkDecoration(
          label: 'Observaciones',
          hint: 'Ingrese las Observaciones',
          enabledBorder: darkBorder(color: Colors.green),
          focusedBorder: darkBorder(color: Colors.green, width: 1.8),
          errorBorder: darkBorder(color: Colors.green, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.green, width: 1.8),
          suffixIcon: const Icon(Icons.sms_outlined, color: kNewtextSec),
        ),
        onChanged: (v) {
          final inv = context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
          inv.observaciones = v;
          FacturaService.updateFactura(context, inv);
        },
      ),
    );
  }

  // ------- Acción principal -------

  Future<void> _goTicket(Invoice factura) async {
    // Usa SIEMPRE la del provider (no variables locales)
    
    if (factura.saldo != 0) {
      Fluttertoast.showToast(
        msg: "La factura aun tiene saldo.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() => _showLoader = true);

    final Map<String, dynamic> request = {
      'products': factura.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre': factura.cierre!.idcierre,
      'cedualaUsuario': factura.empleado!.cedulaEmpleado.toString(),
      'cedulaClienteFactura': factura.formPago!.clienteFactura.documento,
      'totalEfectivo': factura.formPago!.totalEfectivo,
      'totalBac': factura.formPago!.totalBac,
      'totalDav': factura.formPago!.totalDav,
      'totalBn': factura.formPago!.totalBn,
      'totalSctia': factura.formPago!.totalSctia,
      'totalDollars': factura.formPago!.totalDollars,
      'totalCheques': factura.formPago!.totalCheques,
      'totalCupones': factura.formPago!.totalCupones,
      'totalPuntos': factura.formPago!.totalPuntos,
      'totalTransfer': factura.formPago!.totalTransfer,
      'saldo': factura.saldo,
      'clientePaid': factura.formPago!.clientePuntos.toJson(),
      'Transferencia': factura.formPago!.transfer.toJson(),
      'observaciones': factura.observaciones ?? '',
      'ticketMedioPago': 'Efectivo',
      'placa': '',
    };

    final Response response =
        await ApiHelper.post("Api/Facturacion/Ticket", request);

    setState(() => _showLoader = false);

    if (!response.isSuccess) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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

    final decodedJson = jsonDecode(response.result);
    final Factura resdocFactura = Factura.fromJson(decodedJson)
      ..usuario = factura.empleado!.nombreCompleto;

    // Limpia y vuelve
    _goHomeSuccess();
  }

  Future<void> _goHomeSuccess() async {
    final factura = context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
    FacturaService.eliminarFactura(context, factura);
    if (mounted) Navigator.pop(context);
  }
}
