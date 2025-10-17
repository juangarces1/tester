import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/cart_inline_section.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_client.dart';
import 'package:tester/Components/show_email.dart';
import 'package:tester/Components/transacciones_sheet.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/produccts_page.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';

class PeddlersAddScreen extends StatefulWidget {
  final int index;
  const PeddlersAddScreen({super.key, required this.index});

  @override
  State<PeddlersAddScreen> createState() => _PeddlersAddScreenState();
}

class _PeddlersAddScreenState extends State<PeddlersAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;

  // errores
  bool placaTypeIdShowError = false;
  String placaTypeIdError = '';
  bool chShowError = false;
  String chError = "";
  bool obserShowError = false;
  String obserError = "";
  bool orShowError = false;
  String orError = "";
  bool kmShowError = false;
  String kmError = "";

  // estado
  String placa = '';
  late TextEditingController kms;
  late TextEditingController obser;
  late TextEditingController ch;
  late TextEditingController or;
  late Invoice factura;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _kmsFocusNode = FocusNode();
  final FocusNode _choferFocusNode = FocusNode();
  final FocusNode _ordenFocusNode = FocusNode();
  final FocusNode _observacionesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    factura = Provider.of<FacturasProvider>(context, listen: false).getInvoiceByIndex(widget.index);
    // seed de controllers desde la factura
    kms   = TextEditingController(text: (factura.peddler?.km ?? '').toString());
    obser = TextEditingController(text: (factura.peddler?.observaciones ?? '').toString());
    ch    = TextEditingController(text: (factura.peddler?.chofer ?? '').toString());
    or    = TextEditingController(text: (factura.peddler?.orden ?? '').toString());
    // placa inicial (si ya venía)
    placa = (factura.peddler?.placa ?? '').toString();

    _kmsFocusNode.addListener(() => _scrollToAvoidKeyboard(_kmsFocusNode));
    _choferFocusNode.addListener(() => _scrollToAvoidKeyboard(_choferFocusNode));
    _ordenFocusNode.addListener(() => _scrollToAvoidKeyboard(_ordenFocusNode));
    _observacionesFocusNode.addListener(() => _scrollToAvoidKeyboard(_observacionesFocusNode));
  }

  @override
  void dispose() {
    kms.dispose();
    obser.dispose();
    ch.dispose();
    or.dispose();
    _scrollController.dispose();
    _kmsFocusNode.dispose();
    _choferFocusNode.dispose();
    _ordenFocusNode.dispose();
    _observacionesFocusNode.dispose();
    super.dispose();
  }

  void _scrollToAvoidKeyboard(FocusNode focusNode) {
    if (!focusNode.hasFocus) return;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom + 100;
    final renderBox = focusNode.context?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    double textFieldPosition = renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height;
    double screenHeight = MediaQuery.of(context).size.height;
    double offset = textFieldPosition - (screenHeight - keyboardHeight);
    if (offset > 0) {
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kContrateFondoOscuro,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: appBar1(facturaC),
        ),
        body: _body(facturaC),
      ),
    );
  }

  Widget appBar1(Invoice facturaApp) {
    return SafeArea(
      child: Container(
        color: kNewsurfaceHi,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: getProportionateScreenHeight(45),
                width: getProportionateScreenWidth(45),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                    backgroundColor: kNewtextPri,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    FacturaService.updateFactura(context, facturaApp);
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    "assets/Back ICon.svg",
                    height: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text.rich(
                TextSpan(
                  text: "Orden Peddler",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextColorWhite),
                ),
              ),
              const Spacer(),
              Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Invoice facturaC) {
    return Container(
      color: kNewborder,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    CartInlineCompact(
                      showProductsPage: false,
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
                        onPrintTap: (p) {},
                      ),
                      onAddProducts: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsPage(index: widget.index)));
                      },
                    ),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    ShowClient(
                      factura: facturaC,
                      padding: const EdgeInsets.only(left: 0.0, right: 0),
                      tipo: ClienteTipo.peddler,
                    ),
                    facturaC.formPago!.clienteCredito.nombre.isNotEmpty
                        ? ShowEmail(email: facturaC.formPago!.clienteCredito.email)
                        : const SizedBox.shrink(),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    signUpForm(facturaC),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    showTotal(facturaC),
                    const SizedBox(height: 45),
                  ],
                ),
              ),
            ),
          ),
          _showLoader ? const LoaderComponent(loadingText: 'Creando...') : const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ====== FORM ======
  Widget signUpForm(Invoice facturaC) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          showPlaca(facturaC), // NUEVO selector tipo ProceeeCreditScreen
          showkms(facturaC),
          showOrden(facturaC),
          showChofer(facturaC),
          showObser(facturaC),
        ],
      ),
    );
  }

  // === PLACAS (BottomSheet Selector) ===
  Widget showPlaca(Invoice facturaC) {
    // mismas placas que usas en ProceeeCreditScreen, aquí para peddler el cliente es clienteCredito
    final placasCliente = List<String>.from(facturaC.formPago!.clienteFactura.placas);

    if (placasCliente.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final borderColor = (errorText != null && errorText.isNotEmpty) ? kNewred : kNewborder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: kNewtextPri, fontWeight: FontWeight.w600, fontSize: 14),
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
                        fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
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
              style: const TextStyle(color: kNewred, fontSize: 12, fontWeight: FontWeight.w500),
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
      // sincronizar con la factura
      factura.peddler ??= Peddler.empty(); // si tienes un ctor vacío; si no, quita esta línea
      factura.peddler!.placa = placa;
    });
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
    required bool Function(T) isSelected,
  }) {
    if (options.isEmpty) return Future<T?>.value(null);

    final maxHeight = min(
      options.length * 56.0 + 120.0,
      MediaQuery.of(context).size.height * 0.6,
    );

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      decoration: BoxDecoration(color: kNewborder, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      title,
                      style: const TextStyle(color: kNewtextPri, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Divider(color: kNewborder, height: 1),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(color: kNewborder, height: 1),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final label = labelBuilder(option);
                        final selected = isSelected(option);
                        return ListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              color: kNewtextPri,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected ? const Icon(Icons.check_circle, color: kNewgreen) : null,
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

  // === KMS / ORDEN / CHOFER / OBSER ===
  Widget showkms(Invoice facturaC) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextField(
        focusNode: _kmsFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
        decoration: darkDecoration(
          label: 'Kms',
          hint: 'Ingresa los kms',
          suffixIcon: const Icon(Icons.car_repair_rounded, color: kNewtextSec),
          enabledBorder: darkBorder(color: Colors.amber),
          focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
          errorBorder: darkBorder(color: Colors.amber, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
        ),
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.amber,
        onChanged: (value) {
          kms.text = value;
          facturaC.peddler ??= Peddler.empty();
          facturaC.peddler!.km = value;
        },
      ),
    );
  }

  Widget showObser(Invoice facturaC) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextFormField(
        focusNode: _observacionesFocusNode,
        controller: obser,
        keyboardType: TextInputType.text,
        decoration: darkDecoration(
          label: 'Ingresa las Observaciones...',
          hint: 'Observaciones',
          suffixIcon: const Icon(Icons.sms_outlined, color: kNewtextSec),
          enabledBorder: darkBorder(color: Colors.amber),
          focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
          errorBorder: darkBorder(color: Colors.amber, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
        ),
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.amber,
        onChanged: (value) {
          obser.text = value;
          facturaC.peddler ??= Peddler.empty();
          facturaC.peddler!.observaciones = value;
        },
      ),
    );
  }

  Widget showChofer(Invoice facturaC) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextField(
        focusNode: _choferFocusNode,
        controller: ch,
        keyboardType: TextInputType.text,
        decoration: darkDecoration(
          label: 'Ingresa el Nombre...',
          hint: 'Chofer',
          suffixIcon: const Icon(Icons.person, color: kNewtextSec),
          enabledBorder: darkBorder(color: Colors.amber),
          focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
          errorBorder: darkBorder(color: Colors.amber, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
        ),
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.amber,
        onChanged: (value) {
          ch.text = value;
          facturaC.peddler ??= Peddler.empty();
          facturaC.peddler!.chofer = value;
        },
      ),
    );
  }

  Widget showOrden(Invoice facturaC) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextField(
        focusNode: _ordenFocusNode,
        controller: or,
        keyboardType: TextInputType.text,
        decoration: darkDecoration(
          label: 'Ingresa el Numero...',
          hint: 'Orden',
          suffixIcon: const Icon(Icons.confirmation_number, color: kNewtextSec),
          enabledBorder: darkBorder(color: Colors.amber),
          focusedBorder: darkBorder(color: Colors.amber, width: 1.8),
          errorBorder: darkBorder(color: Colors.amber, width: 1.8),
          focusedErrorBorder: darkBorder(color: Colors.amber, width: 1.8),
        ),
        style: const TextStyle(color: kNewtextPri),
        cursorColor: Colors.amber,
        onChanged: (value) {
          or.text = value;
          facturaC.peddler ??= Peddler.empty();
          facturaC.peddler!.orden = value;
        },
      ),
    );
  }

  // ===== TOTAL + SUBMIT =====
  Widget showTotal(Invoice facturaC) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            facturaC.totalLitros > 0
                ? Text.rich(
                    TextSpan(
                      text: "Total Lts:\n",
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                    text: " ${VariosHelpers.formattedToVolumenValue(facturaC.totalLitros.toString())}",
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ) : const SizedBox.shrink(),
            facturaC.formPago!.clienteFactura.nombre.isNotEmpty && (facturaC.detail?.isNotEmpty ?? false)
                ? SizedBox(
                    width: getProportionateScreenWidth(160),
                    child: DefaultButton(
                      text: "Crear Orden",
                      press: () => _goPeddler(facturaC),
                      color: Colors.amber,
                      gradient: kYellowGradient,
                      textColor: Colors.black,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  bool _validateFields() {
    bool isValid = true;

    if (ch.text.isEmpty) {
      chShowError = true;
      chError = "Debes ingresar el nombre";
      isValid = false;
    } else {
      chShowError = false;
    }

    if (kms.text.isEmpty) {
      kmShowError = true;
      kmError = "Debes ingresar el kilometraje";
      isValid = false;
    } else {
      kmShowError = false;
    }

    if (or.text.isEmpty) {
      orShowError = true;
      orError = "Debes ingresar el número de orden";
      isValid = false;
    } else {
      orShowError = false;
    }

    if (placa.isEmpty) {
      placaTypeIdShowError = true;
      placaTypeIdError = "Debes seleccionar la placa";
      isValid = false;
    } else {
      placaTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _goPeddler(Invoice facturaC) async {
    if (!_validateFields()) return;

    setState(() => _showLoader = true);

    // asegurar que la placa quede en la factura antes de enviar
    facturaC.peddler ??= Peddler.empty();
    facturaC.peddler!.placa = placa;

    final pd = Peddler(
      id: 0,
      products: facturaC.detail ?? [],
      idcierre: facturaC.cierre!.idcierre,
      pistero: facturaC.empleado!,
      cliente: facturaC.formPago!.clienteFactura,
      placa: facturaC.peddler!.placa,
      km: facturaC.peddler!.km,
      observaciones: facturaC.peddler!.observaciones,
      chofer: facturaC.peddler!.chofer,
      orden: facturaC.peddler!.orden,
    );

    final response = await ApiHelper.post('Api/Peddler/PostPeddler', pd.toJson());

    setState(() => _showLoader = false);

    if (!mounted) return;

    if (!response.isSuccess) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Peddler creado exitosamente'),
        content: const Text('¿Desea imprimir el Peddler?'),
        actions: [
          TextButton(
            child: const Text('Si'),
            onPressed: () {
              // Aquí tu lógica de impresión si aplica...
              // Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
              _goHomeSuccess();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _goHomeSuccess() async {
    FacturaService.eliminarFactura(context, factura);
    Navigator.pop(context);
  }
}
