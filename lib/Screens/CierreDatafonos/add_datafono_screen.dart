import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/datafono.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class DatafonoScreen extends StatefulWidget {
  

  // ignore: use_key_in_widget_constructors
  const DatafonoScreen();

  @override
  State<DatafonoScreen> createState() => _DatafonoScreenState();
}

class _DatafonoScreenState extends State<DatafonoScreen> {
  bool _showLoader = false;
  String monto = '';
  String lote = '';
  String montoError = '';
  bool montoShowError = false;
  String loteError = '';
  bool loteShowError = false;
  final TextEditingController montoController = TextEditingController();
  final TextEditingController loteController = TextEditingController();
  String? datafonoNombre;
  String bancoTypeIdError = '';
  bool bancoTypeIdShowError = false;
  List<Datafono> datafonos = [];

  @override
  void initState() {
    super.initState();
    _getDatafonos();
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
          title: 'Nuevo cierre datafono',
          automaticallyImplyLeading: true,
          foreColor: kNewtextPri,
          backgroundColor: kNewbg,
          actions:  <Widget>[
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
                children: <Widget>[
                  Text(
                    'Registrar cierre de datafono',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.w700,
                      color: kNewtextPri,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completa los datos del deposito, lote y terminal procesada.',
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        datafonos.isEmpty
                            ? const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Cargando datafonos...',
                                  style: TextStyle(color: kNewtextMut),
                                ),
                              )
                            : _buildDatafonoSelector(),
                        const SizedBox(height: 20),
                        _showMonto(),
                        const SizedBox(height: 20),
                        _showLote(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goDatafono,
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
                        'Crear cierre',
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

  Future<void> _getDatafonos() async {
    setState(() {
      _showLoader = true;
    });

    final Response response = await ApiHelper.getDatafonos();

    if (!mounted) {
      return;
    }

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
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
      return;
    }

    setState(() {
      datafonos = response.result;
    });
  }

  Widget _buildDatafonoSelector() {
    if (datafonos.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Cargando datafonos...',
          style: TextStyle(color: kNewtextMut),
        ),
      );
    }

    final selectedName = datafonoNombre?.trim() ?? '';

    return _buildSelectorTile(
      label: 'Datafono',
      value: selectedName,
      placeholder: 'Selecciona un datafono',
      errorText: bancoTypeIdShowError ? bancoTypeIdError : null,
      onTap: _onSelectDatafono,
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final bool hasValue = value.isNotEmpty;
    final String displayText = hasValue ? value : placeholder;
    final Color borderColor =
        (errorText != null && errorText.isNotEmpty) ? kNewred : kNewborder;
    final Color textColor = hasValue ? kNewtextPri : kNewtextMut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kNewtextSec,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: kNewsurfaceHi,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, color: kNewtextSec),
              ],
            ),
          ),
        ),
        if (errorText != null && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: kNewred,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _showMonto() {
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
      },
    );
  }

  Future<void> _onSelectDatafono() async {
    if (datafonos.isEmpty) {
      return;
    }

    final selected = await _showSelectionSheet<Datafono>(
      title: 'Selecciona un datafono',
      options: datafonos,
      labelBuilder: (datafono) => datafono.nombre ?? '',
      isSelected: (datafono) =>
          (datafono.nombre ?? '') == (datafonoNombre ?? ''),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      datafonoNombre = selected.nombre ?? '';
      bancoTypeIdShowError = false;
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
                  const Divider(height: 1, color: kNewborder),
                  Expanded(
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: kNewborder),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final bool selected = isSelected(option);
                        final String label = labelBuilder(option);

                        return ListTile(
                          onTap: () => Navigator.of(context).pop(option),
                          title: Text(
                            label,
                            style: TextStyle(
                              color: kNewtextPri,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check, color: kNewgreen)
                              : null,
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

  Widget _showLote() {
    return TextField(
      controller: loteController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: kNewtextPri,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: kNewred,
      decoration: darkDecoration(
        label: 'Numero de lote',
        hint: 'Ingresa el numero de lote',
        errorText: loteShowError ? loteError : null,
        suffixIcon: const Icon(Icons.numbers_outlined, color: kNewtextSec),
      ),
      onChanged: (value) {
        lote = value;
      },
    );
  }

  void _goDatafono() async {
    if (!_validateFields()) {
      return;
    }

    await _addDatafono();
  }

  bool _validateFields() {
    bool isValid = true;

    monto = montoController.text.trim();
    lote = loteController.text.trim();

    if (monto.isEmpty) {
      isValid = false;
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }

    if (lote.isEmpty) {
      isValid = false;
      loteShowError = true;
      loteError = 'Debes ingresar el lote.';
    } else {
      loteShowError = false;
    }

    if (datafonoNombre == null || datafonoNombre!.isEmpty) {
      isValid = false;
      bancoTypeIdShowError = true;
      bancoTypeIdError = 'Debes seleccionar un datafono.';
    } else {
      bancoTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _addDatafono() async {
    setState(() {
      _showLoader = true;
    });

    final Datafono data = datafonos.firstWhere(
      (element) => element.nombre == datafonoNombre,
    );

    
    final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
    

    final CierreDatafono datafono = CierreDatafono(
      idcierredatafono: int.parse(lote),
      monto: double.parse(monto),
      fechacierre: "2023-07-11T00:00:00",
      cedulaempleado: cierreActPro.usuario!.cedulaEmpleado,
      idbanco: data.idbanco,
      idcierre: cierreActPro.cierreFinal!.idcierre,
      terminal: data.nombre,
      idregistrodatafono: 0,
      banco: data.nombre,
    );

    final Map<String, dynamic> request = datafono.toJson();

    final Response response = await ApiHelper.post(
      'api/CierreDatafonos/',
      request,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
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
      return;
    }

    await Fluttertoast.showToast(
      msg: "Cierre de datafono creado correctamente.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 20, 91, 22),
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context, 'yes');
  }
}


