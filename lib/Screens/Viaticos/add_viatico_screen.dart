import 'dart:math'; // Importación añadida para la función min

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Components/show_client.dart';

import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';

import 'package:tester/Models/response.dart';
import 'package:tester/Models/viatico.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';

import 'package:tester/Screens/Viaticos/viaticos_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';
import 'package:provider/provider.dart';

// Definición de darkDecoration basado en EntregaEfectivoScreen
InputDecoration darkDecoration({
  required String label,
  required String hint,
  String? errorText,
  Widget? suffixIcon,
}) {
  const borderColor = kNewborder;
  const errorBorderColor = kNewred;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: kNewtextPri),
    hintStyle: const TextStyle(color: kNewtextMut),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: kNewsurfaceHi,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: borderColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kNewgreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorBorderColor, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorBorderColor, width: 2),
    ),
  );
}

class AddViaticoScreen extends StatefulWidget {
  
  // ignore: use_key_in_widget_constructors
  const AddViaticoScreen();

  @override
  State<AddViaticoScreen> createState() => _AddViaticoScreenState();
}

class _AddViaticoScreenState extends State<AddViaticoScreen> {
  bool _showLoader = false;
  String monto = '';
  String lote = '';
  String montoError = '';
  bool montoShowError = false;
  String loteError = '';
  bool loteShowError = false;
  TextEditingController montoController = TextEditingController();
  TextEditingController loteController = TextEditingController();
  String datafonoNombre = '';
  String bancoTypeIdError = '';
  bool bancoTypeIdShowError = false;
  List<Viatico> viaticos = [];

  bool placaTypeIdShowError = false;
  String placaTypeIdError = '';
  String placa = '';
  late Invoice invoice;
 

  @override

  void initState() {

    var cierre = context.read<CierreActivoProvider>().cierreFinal;
    var usuario = context.read<CierreActivoProvider>().usuario;

    invoice = Invoice.createInitializedInvoice(cierre!, usuario!);

    super.initState();
  }

  @override
  void dispose() {
    montoController.dispose();
    loteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          title: 'Nuevo Viático',
          automaticallyImplyLeading: true,
          foreColor: kNewtextPri,
          backgroundColor: kNewbg,
        
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
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar Viático',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.w700,
                      color: kNewtextPri,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completa los campos para registrar el viático.',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(14),
                      color: kNewtextMut,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kNewsurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kNewborder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x59000000),
                          blurRadius: 24,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ShowClient(factura: invoice,
                          tipo: ClienteTipo.credito,                         
                          padding: EdgeInsets
                              .zero, // Ajustar padding si ShowClientCredito tiene padding interno
                        ),
                        const SizedBox(height: 20),
                        _buildPlacaSelector(invoice),
                        const SizedBox(height: 20),
                        _buildMontoField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goViatico,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: kNewgreen,
                        foregroundColor: kNewtextPri,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Crear Viático',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showLoader)
              const LoaderComponent(
                loadingText: 'Por favor espere...',
                backgroundColor: kNewsurface,
                borderColor: kNewborder,
              ),
          ],
        ),
      ),
    );
  }

  // --- Widgets de Estilo Reutilizados de EntregaEfectivoScreen ---

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

  Widget _buildPlacaSelector(Invoice facturaC) {

     // final List<String> placas = facturaC.formPago!.clienteFactura.placas;
    final List<String> placas = ['ABC123', 'XYZ789', 'LMN456']; // Ejemplo de placas
    facturaC.formPago!.clienteFactura.placas = placas;
  
    if (facturaC.formPago!.clienteFactura.nombre.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Selecciona un cliente para ver las placas...',
          style: TextStyle(color: kNewtextMut),
        ),
      );
    }
    if (placas.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'El cliente no tiene placas asociadas.',
          style: TextStyle(color: kNewtextMut),
        ),
      );
    }

    return _buildSelectorTile(
      label: 'Placa',
      value: placa,
      placeholder: 'Selecciona una placa',
      errorText: placaTypeIdShowError ? placaTypeIdError : null,
      onTap: () => _onSelectPlaca(placas),
    );
  }

  Future<void> _onSelectPlaca(List<String> placas) async {
    if (placas.isEmpty) {
      return;
    }

    final selected = await _showSelectionSheet<String>(
      title: 'Selecciona una placa',
      options: placas,
      labelBuilder: (p) => p,
      isSelected: (p) => p == placa,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      placa = selected;
      placaTypeIdShowError = false;
    });
  }

  Widget _buildMontoField() {
    return TextField(
      controller: montoController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: kNewtextPri,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: kNewred,
      decoration: darkDecoration(
        label: 'Monto',
        hint: 'Ingresa el monto',
        errorText: montoShowError ? montoError : null,
        suffixIcon: const Icon(Icons.attach_money_rounded, color: kNewtextSec),
      ),
      onChanged: (value) {
        monto = value;
        setState(() {
          montoShowError = false;
        });
      },
    );
  }

  // --- Lógica del Viático ---

  void _goViatico() async {
    if (!_validateFields()) {
      return;
    }

    _addViatico();
  }

  bool _validateFields() {
    bool isValid = true;

    // Client validation (Toast in original, keep as is but re-evaluate isValid)
    if (invoice.formPago!.clienteFactura.nombre.isEmpty) {
      Fluttertoast.showToast(
          msg: " Seleccione un cliente",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      isValid = false;
    }

    if (monto.isEmpty) {
      isValid = false;
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }

    if (placa.isEmpty) {
      isValid = false;
      placaTypeIdShowError = true;
      placaTypeIdError = 'Debes seleccionar una Placa.';
    } else {
      placaTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  void _addViatico() async {
    if (_validateFields() == false) {
      return;
    }

    setState(() {
      _showLoader = true;
    });

     final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
    

    Viatico viatico = Viatico(
      idviatico: 0,
      monto: int.parse(monto),
      fecha: "2023-07-11T00:00:00",
      cedulaempleado: cierreActPro.usuario!.cedulaEmpleado,
      idcierre: cierreActPro.cierreFinal!.idcierre,
      placa: placa,
      estado: 'PENDIENTE',
      idcliente: int.parse(invoice.formPago!.clienteFactura.codigo),
    );

    Map<String, dynamic> request = viatico.toJson();

    Response response = await ApiHelper.post(
      'api/Viaticos/',
      request,
    );

    if (!mounted) return;

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

    Fluttertoast.showToast(
        msg: "Viatico Creado Correctamente.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 20, 91, 22),
        textColor: Colors.white,
        fontSize: 16.0);

    // ignore: use_build_context_synchronously
    if (!mounted) {
      return;
    }
    FacturaService.eliminarFactura(context, invoice);
    Navigator.pop(context);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const ViaticosScreen()));
  }
}