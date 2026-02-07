import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/default_button.dart';
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
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class ProceeeCreditScreen extends StatefulWidget {
  final int index;
  // ignore: use_key_in_widget_constructors
  const ProceeeCreditScreen({
    required this.index,
  });
  @override
  State<ProceeeCreditScreen> createState() => _ProceeeCreditScreen();
}

class _ProceeeCreditScreen extends State<ProceeeCreditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;
  bool placaTypeIdShowError = false;
  String placaTypeIdError = '';
  String placa = '';
  late TextEditingController kms;
  late TextEditingController obser;
  final String _codigoError = '';
  final bool _codigoShowError = false;
  late Invoice factura;

  @override
  void initState() {
    super.initState();
    // Obtener la factura inicial sin escuchar cambios
    factura = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
    kms = TextEditingController(text: factura.kms.toString());
    obser = TextEditingController(text: factura.observaciones.toString());
  }

  @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Invoice facturaC =
        Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);
    SizeConfig().init(context);

    // Color para Crédito (igual que en FacturacionPageV2)
    const creditoColor = Color(0xFF3B82F6); // Blue

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF12151A),
        body: Stack(
          children: [
            CustomScrollView(
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
                          creditoColor.withOpacity(0.9),
                          creditoColor.withOpacity(0.6),
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
                          color: creditoColor.withOpacity(0.4),
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
                              FacturaService.updateFactura(context, facturaC);
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
                                  'Crédito',
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
                                        '${facturaC.numeroProductos} items',
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

                          // Total
                          if (facturaC.total > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    VariosHelpers.formattedToCurrencyValue(
                                      facturaC.total.toString(),
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
                    padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(20)),
                    child: Column(
                      children: [
                        SizedBox(height: SizeConfig.screenHeight * 0.02),
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

                        SizedBox(height: SizeConfig.screenHeight * 0.02),
                        ShowClient(
                          tipo: ClienteTipo.credito,
                          factura: factura,
                          padding: const EdgeInsets.only(left: 10.0, right: 10),
                        ),

                        factura.formPago!.clienteFactura.nombre.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: ShowEmail(
                                  email: factura.formPago!.clienteFactura.email,
                                  backgroundColor: kNewsurfaceHi,
                                ),
                              )
                            : Container(),

                        if (factura.tieneCodigoActividad)
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: ShowActividadSelect(
                              actividad: factura.formPago!.clienteFactura
                                  .actividadSeleccionada!,
                            ),
                          ),
                        facturaC.formPago!.clienteCredito.nombre.isNotEmpty
                            ? ShowEmail(
                                email: facturaC.formPago!.clienteCredito.email)
                            : Container(),
                        SizedBox(height: SizeConfig.screenHeight * 0.01),
                        signUpForm(),
                        SizedBox(height: SizeConfig.screenHeight * 0.02),

                        // Espacio para el botón flotante
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ═══════════════════════════════════════════════════════════════
            // BOTÓN FACTURAR (flotante, aparece cuando hay cliente y productos)
            // ═══════════════════════════════════════════════════════════════
            if (factura.detail!.isNotEmpty &&
                factura.formPago!.clienteFactura.nombre.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _goFact(),
                      borderRadius: BorderRadius.circular(18),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Facturar Crédito',
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

            // Loader
            if (_showLoader) const LoaderComponent(loadingText: 'Creando...'),
          ],
        ),
      ),
    );
  }

  // Método appBar1 ya no se usa pero lo dejamos por si acaso
  Widget appBar1(Invoice facturaApp) {
    return SafeArea(
      child: Container(
        color: const Color.fromARGB(247, 16, 40, 86),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: getProportionateScreenHeight(45),
                width: getProportionateScreenWidth(45),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    FacturaService.updateFactura(context, facturaApp);
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 15,
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 11, 30, 53),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Text.rich(
                TextSpan(
                  text: "Factura Credito",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kNewtextPri,
                  ),
                ),
              ),
              const Spacer(),
              Container()
            ],
          ),
        ),
      ),
    );
  }

  void onItemSelected(Product product) {
    setState(() {
      factura.detail!.add(product);
    });
  }

  Widget signUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          showPlaca(),
          showkms(),
          showObser(),
        ],
      ),
    );
  }

  Widget showkms() {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        decoration: darkDecoration(
          label: 'Kms',
          hint: 'Ingresa los kms',
          errorText: _codigoShowError ? _codigoError : null,
          suffixIcon: const Icon(Icons.car_repair_rounded, color: kNewtextSec),
          enabledBorder: darkBorder(color: Colors.blue),
          focusedBorder: darkBorder(color: Colors.blue, width: 1.8),
          errorBorder: darkBorder(color: Colors.blue, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.blue, width: 1.8),
        ),
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.blue,
        onChanged: (value) {
          kms.text = value; // tu lógica intacta
        },
      ),
    );
  }

  Widget showObser() {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: TextField(
        controller: obser,
        keyboardType: TextInputType.text,
        maxLines: 3,
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.blue,
        decoration: darkDecoration(
          label: 'Observaciones',
          hint: 'Ingrese las Observaciones',
          enabledBorder: darkBorder(color: Colors.blue),
          focusedBorder: darkBorder(color: Colors.blue, width: 1.8),
          errorBorder: darkBorder(color: Colors.blue, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.blue, width: 1.8),
          suffixIcon: const Icon(Icons.sms_outlined, color: kNewtextSec),
        ),
      ),
    );
  }

  Widget showPlaca() {
    final placasCliente =
        List<String>.from(factura.formPago!.clienteFactura.placas);

    if (placasCliente.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 0, left: 10, right: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kNewsurfaceHi,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kNewborder),
          ),
          child: const Text(
            'Este cliente no tiene placas registradas.',
            style: TextStyle(color: kNewtextMut, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: _buildSelectorTile(
        label: 'Placas',
        value: placa,
        placeholder: 'Seleccione una Placa...',
        errorText: placaTypeIdShowError ? placaTypeIdError : null,
        onTap: () => _onSelectPlaca(placasCliente),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final hasValue = value.trim().isNotEmpty;
    final displayText = hasValue ? value : placeholder;
    final borderColor =
        errorText != null && errorText.isNotEmpty ? kNewred : kNewborder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kNewtextPri,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: kNewsurfaceHi,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: hasValue ? kNewtextPri : kNewtextMut,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: kNewtextSec),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText,
              style: const TextStyle(
                color: kNewred,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onSelectPlaca(List<String> placasCliente) async {
    if (placasCliente.isEmpty) return;

    final selected = await _showSelectionSheet<String>(
      title: 'Selecciona una placa',
      options: placasCliente,
      labelBuilder: (value) => value,
      isSelected: (value) => value == placa,
    );

    if (selected == null) return;

    setState(() {
      placa = selected;
      placaTypeIdShowError = false;
    });
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
    required bool Function(T) isSelected,
  }) {
    if (options.isEmpty) {
      return Future<T?>.value(null);
    }

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double maxHeight = min(
          options.length * 56.0 + 120.0,
          MediaQuery.of(context).size.height * 0.6,
        );

        return Container(
          decoration: const BoxDecoration(
            color: kNewsurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kNewborder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: kNewtextPri,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Divider(color: kNewborder, height: 1),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: kNewborder, height: 1),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final label = labelBuilder(option);
                        final selected = isSelected(option);
                        return ListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              color: kNewtextPri,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: kNewgreen)
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget showTotal(Invoice facturaC) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: "Total:\n",
                style: const TextStyle(
                    fontSize: 22,
                    color: kNewtextPri,
                    fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text:
                        " ${VariosHelpers.formattedToCurrencyValue(facturaC.total.toString())}",
                    style: const TextStyle(
                        fontSize: 22,
                        color: kNewtextPri,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            factura.detail!.isNotEmpty &&
                    factura.formPago!.clienteFactura.nombre.isNotEmpty
                ? SizedBox(
                    width: getProportionateScreenWidth(150),
                    child: DefaultButton(
                      text: "Facturar",
                      press: () => _goFact(),
                      gradient: kBlueGradient,
                      color: kBlueColorLogo,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> _goFact() async {
    setState(() {
      _showLoader = true;
    });
    if (kms.text == '') {
      kms.text = '0';
    }
    Map<String, dynamic> request = {
      'products': factura.detail!.map((e) => e.toApiProducJson()).toList(),
      'idCierre': factura.cierre!.idcierre,
      'cedualaUsuario': factura.empleado!.cedulaEmpleado.toString(),
      'clienteFactura': factura.formPago!.clienteFactura.toJson(),
      'totalEfectivo': factura.total,
      'totalBac': factura.formPago!.totalBac,
      'totalDav': factura.formPago!.totalDav,
      'totalBn': factura.formPago!.totalBn,
      'totalSctia': factura.formPago!.totalSctia,
      'totalDollars': factura.formPago!.totalDollars,
      'totalCheques': factura.formPago!.totalCheques,
      'totalCupones': factura.formPago!.totalCupones,
      'totalPuntos': factura.formPago!.totalPuntos,
      'totalTransfer': factura.formPago!.totalTransfer,
      'saldo': 0,
      'clientePuntos': factura.formPago!.clienteCredito.toJson(),
      'Transferencia': factura.formPago!.transfer.toJson(),
      'kms': kms.text,
      'observaciones': obser.text,
      'placa': placa,
      'isticket': false,
      'isCredit': true,
      'plazo': factura.formPago!.clienteFactura.plazo,
      'isContado': false,
    };
    Response response =
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

    var decodedJson = jsonDecode(response.result);
    Factura resdocFactura = Factura.fromJson(decodedJson);
    resdocFactura.usuario = factura.empleado!.nombreCompleto;
    //  factura.actualizarCantidadProductos();
    //   factura.resetFactura();
    if (!mounted) return;

    final printerProv = context.read<PrinterProvider>();

    if (printerProv.isBound == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impresora desconectada. Por favor, verifique la conexión.')),
      );
      _goHomeSuccess();
      return;
    }
    if (printerProv.busy == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impresora ocupada. Por favor, intente más tarde.')),
      );
      _goHomeSuccess();
      return;
    }
    // Llamas a tu clase de impresión
    final testPrint = TestPrint();
    await testPrint.printFactura(resdocFactura, 'CREDITO', 'CREDITO', true);
    await testPrint.printFactura(resdocFactura, 'CREDITO', 'CREDITO', false);
    _goHomeSuccess();
  }

  Future<void> _goHomeSuccess() async {
    FacturaService.eliminarFactura(context, factura);
    Navigator.pop(context);
  }
}
