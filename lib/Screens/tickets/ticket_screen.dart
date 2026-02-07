import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/form_pago_v2.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/transacciones_sheet.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/factura.dart';

import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/Screens/test_print/testprint.dart';
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
  final GlobalKey<FormPagoV2State> formPagoKey = GlobalKey<FormPagoV2State>();
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
    final inv = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
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
    final factura =
        context.watch<FacturasProvider>().getInvoiceByIndex(widget.index);

    // Color para Ticket (Green)
    const ticketColor = Color(0xFF22C55E); // Green-500

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
        backgroundColor: const Color(0xFF12151A),
        body: Stack(
          children: <Widget>[
            RefreshIndicator(
              onRefresh: () async => callGoRefresh(),
              child: CustomScrollView(
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
                            ticketColor.withOpacity(0.9),
                            ticketColor.withOpacity(0.6),
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
                            color: ticketColor.withOpacity(0.4),
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
                                    'Ticket',
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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

                            // Saldo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: factura.saldo == 0
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    factura.saldo == 0 ? '✓ Pagado' : 'Saldo',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    VariosHelpers.formattedToCurrencyValue(
                                      factura.saldo.toString(),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
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
                                final inv =
                                    prov.getInvoiceByIndex(widget.index);
                                inv.detail ??= [];
                                inv.detail!.add(p);
                                FacturaService.updateFactura(context, inv);
                              },
                              showPrintIcon: true,
                              onPrintTap: null,
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
                          FormPagoV2(
                            key: formPagoKey,
                            index: widget.index,
                            fontColor: kNewtextPri,
                            ruta: 'Ticket',
                            expansibleController: _pagoCtrl,
                          ),
                          const SizedBox(height: 10),
                          _infoTicketSection(factura),
                          const SizedBox(height: 10),

                          // Total de la factura
                          if (factura.total > 0) showTotal(factura),

                          // Espacio para el botón flotante
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════════════════
            // BOTÓN FACTURAR (flotante, aparece cuando saldo = 0 y hay items)
            // ═══════════════════════════════════════════════════════════════
            if ((factura.detail?.isNotEmpty ?? false) && factura.saldo == 0)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _goTicket(factura),
                      borderRadius: BorderRadius.circular(18),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Crear Ticket',
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

            if (_showLoader)
              const LoaderComponent(loadingText: "Creando Ticket..."),
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
          color: const Color(0xFF22C55E).withOpacity(0.3),
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
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Método _appBar ya no se usa pero lo dejamos por compatibilidad
  Widget _appBar(Invoice factura) {
    return SafeArea(
      child: Container(
        color: const Color.fromARGB(255, 53, 130, 55),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Row(
            children: [
              SizedBox(
                height: getProportionateScreenHeight(38),
                width: getProportionateScreenWidth(38),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60)),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
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

  Future<void> _handleTicketPrint(Factura ticket) async {
    const String tipoDocumento = 'TICKET';

    const String tipoCliente = 'CONTADO';

    try {
      final tp = TestPrint(totalChars: 32);
      Fluttertoast.showToast(msg: 'Ticket enviada a impresion');
      await tp.printFactura(ticket, tipoDocumento, tipoCliente);
    } catch (err, st) {
      debugPrint('handleTicketPrint error: $err\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir el ticket');
    }
  }

  Future<bool> _confirmPrintTicket() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Imprimir ticket'),
          content: const Text('Desea imprimir el ticket?'),
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
          final inv =
              context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
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
      'clienteFactura': factura.formPago!.clienteFactura.toJson(),
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
      'clientePuntos': factura.formPago!.clientePuntos.toJson(),
      'Transferencia': factura.formPago!.transfer.toJson(),
      'observaciones': factura.observaciones ?? '',
      'placa': '',
      'isTicket': true,
      'isContado': false,
      'isCredit': false,
    };

    final Response response =
        await ApiHelper.post("Api/Facturacion/FacturaSp", request);

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

    if (factura.acumulaPuntos) {
      await _handleAcumulaPuntosPrint(
        factura,
        factura.empleado?.nombreCompleto ?? '',
      );
    }

    if (factura.tieneTransferencia) {
      await _handleTransferenciaPrint(factura);
    }

    if (factura.canjeaPuntos) {
      await _handleCanjeaPuntosPrint(factura);
    }

    if (factura.tieneSinpe) {
      await _handleSinpePrint(factura);
    }

    final bool shouldPrint = await _confirmPrintTicket();
    if (shouldPrint) {
      await _handleTicketPrint(resdocFactura);
    }

    // Limpia y vuelve
    _goHomeSuccess();
  }

  Future<void> _goHomeSuccess() async {
    final factura =
        context.read<FacturasProvider>().getInvoiceByIndex(widget.index);
    FacturaService.eliminarFactura(context, factura);
    if (mounted) Navigator.pop(context);
  }
}
