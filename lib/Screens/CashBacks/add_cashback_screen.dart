import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/bank.dart';
import 'package:tester/Models/cashback.dart';
import 'package:tester/Models/response.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class AddCashbackScreen extends StatefulWidget {
  const AddCashbackScreen({super.key});

  @override
  State<AddCashbackScreen> createState() => _AddCashbackScreenState();
}

class _AddCashbackScreenState extends State<AddCashbackScreen> {
  bool _showLoader = false;

  // Estado
  final TextEditingController _montoController = TextEditingController();
  String montoError = '';
  bool montoShowError = false;

  int idbanco = 0;
  String bancoTypeIdError = '';
  bool bancoTypeIdShowError = false;

  List<Bank> banks = [];

  @override
  void initState() {
    super.initState();
    _getBanks();
  }

  @override
  void dispose() {
    _montoController.dispose();
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
          title: 'Nuevo Cashback',
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
                    'Registrar cashback',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.w700,
                      color: kNewtextPri,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completa los campos para crear el registro.',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(14),
                      color: kNewtextMut,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card de formulario (mismo patrón que EntregaEfectivoScreen)
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
                        _buildBankSelector(),
                        const SizedBox(height: 20),
                        _buildMontoField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goCashback,
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
                        'Crear cashback',
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

  // ==========================
  // Controles (mismo patrón)
  // ==========================

  Widget _buildBankSelector() {
    if (banks.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Cargando bancos...', style: TextStyle(color: kNewtextMut)),
      );
    }

    final selectedBank =
        banks.firstWhere((b) => (b.idbanco ?? 0) == idbanco, orElse: () => Bank());

    return _buildSelectorTile(
      label: 'Banco',
      value: selectedBank.nombre ?? '',
      placeholder: 'Selecciona un banco',
      errorText: bancoTypeIdShowError ? bancoTypeIdError : null,
      onTap: _onSelectBank,
    );
  }

  Widget _buildMontoField() {
    return TextField(
      controller: _montoController,
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
      onChanged: (_) {
        montoShowError = false;
      },
    );
  }

  // Tile genérico de selección (igual que EntregaEfectivoScreen)
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

  // BottomSheet de selección (mismo patrón)
  Future<void> _onSelectBank() async {
    if (banks.isEmpty) return;

    final selected = await _showSelectionSheet<Bank>(
      title: 'Selecciona un banco',
      options: banks,
      labelBuilder: (bank) => bank.nombre ?? '',
      isSelected: (bank) => (bank.idbanco ?? 0) == idbanco,
    );

    if (selected == null) return;

    setState(() {
      idbanco = selected.idbanco ?? 0;
      bancoTypeIdShowError = false;
    });
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
    required bool Function(T) isSelected,
  }) {
    if (options.isEmpty) return Future<T?>.value(null);

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

  // ==========================
  // Lógica de datos
  // ==========================

  Future<void> _getBanks() async {
    setState(() => _showLoader = true);

    final Response response = await ApiHelper.getBanks();

    if (!mounted) return;

    setState(() => _showLoader = false);

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    setState(() {
      banks = response.result;
    });
  }

  void _goCashback() async {
    if (!_validateFields()) return;
    await _addCashback();
  }

  bool _validateFields() {
    bool isValid = true;

    final montoValue = _montoController.text.trim();
    if (montoValue.isEmpty) {
      isValid = false;
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }

    if (idbanco == 0) {
      isValid = false;
      bancoTypeIdShowError = true;
      bancoTypeIdError = 'Debes seleccionar un banco.';
    } else {
      bancoTypeIdShowError = false;
    }

    setState(() {});
    return isValid;
    }

  Future<void> _addCashback() async {
    setState(() => _showLoader = true);

    final cierreActPro =
        Provider.of<CierreActivoProvider>(context, listen: false);

    final Cashback cashback = Cashback(
      idcashback: 0,
      // mantengo tu mismo formato/valor para no romper backend
      fechacashback: "2023-07-11T00:00:00",
      monto: int.tryParse(_montoController.text.trim()) ?? 0,
      cedulaempleado: cierreActPro.usuario!.cedulaEmpleado,
      idbanco: idbanco,
      idcierre: cierreActPro.cierreFinal!.idcierre,
    );

    final Response response =
        await ApiHelper.post('api/Cashbacks/', cashback.toJson());

    if (!mounted) return;
    setState(() => _showLoader = false);

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    await Fluttertoast.showToast(
      msg: "Cashback Creado Correctamente.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 20, 91, 22),
      textColor: Colors.white,
      fontSize: 16.0,
    );

    if (!mounted) return;
    Navigator.pop(context, 'yes');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
