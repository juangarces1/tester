import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/bank.dart';
import 'package:tester/Models/cheque.dart';

import 'package:tester/Models/deposito.dart';
import 'package:tester/Models/dollar.dart';
import 'package:tester/Models/money.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class EntregaEfectivoScreen extends StatefulWidget {
 
  const EntregaEfectivoScreen({super.key,});

  @override
  State<EntregaEfectivoScreen> createState() => _EntregaEfectivoScreenState();
}

class _EntregaEfectivoScreenState extends State<EntregaEfectivoScreen> {
  bool _showLoader = false;

  String moneda = '';
  int idbank = 0;

  bool showDollar = false;
  bool showCheque = false;

  String moneyTypeIdError = '';
  bool moneyTypeIdShowError = false;
  String bankError = '';
  bool bankShowError = false;
  String montoError = '';
  bool montoShowError = false;
  String cantDollarError = '';
  bool cantDollarShowError = false;
  String precioDollarError = '';
  bool precioDollarShowError = false;
  String idChequeError = '';
  bool idChequeShowError = false;

  final TextEditingController montoController = TextEditingController();
  final TextEditingController cantDollarController = TextEditingController();
  final TextEditingController cambioDollarController = TextEditingController();
  final TextEditingController idChequeController = TextEditingController();

  List<Money> moneys = [];
  List<Bank> banks = [];

  @override
  void initState() {
    super.initState();
    _getMoneys();
    _getBanks();
  }

  @override
  void dispose() {
    montoController.dispose();
    cantDollarController.dispose();
    cambioDollarController.dispose();
    idChequeController.dispose();
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
          title: 'Nuevo deposito',
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
                    'Registrar deposito',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.w700,
                      color: kNewtextPri,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completa los campos segun la forma de entrega seleccionada.',
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
                        _buildMoneySelector(),
                        if (showCheque) ...[
                          const SizedBox(height: 20),
                          _buildBankSelector(),
                          const SizedBox(height: 20),
                          _buildChequeField(),
                        ],
                        if (showDollar) ...[
                          const SizedBox(height: 20),
                          _buildDollarQuantityField(),
                          const SizedBox(height: 20),
                          _buildDollarRateField(),
                        ],
                        const SizedBox(height: 20),
                        _buildMontoField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goDeposito,
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
                        'Crear deposito',
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

  Widget _buildMoneySelector() {
    if (moneys.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Cargando monedas...',
          style: TextStyle(color: kNewtextMut),
        ),
      );
    }

    return _buildSelectorTile(
      label: 'Moneda',
      value: moneda,
      placeholder: 'Selecciona una moneda',
      errorText: moneyTypeIdShowError ? moneyTypeIdError : null,
      onTap: _onSelectMoney,
    );
  }

  Widget _buildBankSelector() {
    if (banks.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Cargando bancos...',
          style: TextStyle(color: kNewtextMut),
        ),
      );
    }

    final selectedBank = banks.firstWhere((b) => (b.idbanco ?? 0) == idbank,
        orElse: () => Bank());

    return _buildSelectorTile(
      label: 'Banco',
      value: selectedBank.nombre ?? '',
      placeholder: 'Selecciona un banco',
      errorText: bankShowError ? bankError : null,
      onTap: _onSelectBank,
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

  Future<void> _onSelectMoney() async {
    if (moneys.isEmpty) {
      return;
    }

    final selected = await _showSelectionSheet<Money>(
      title: 'Selecciona una moneda',
      options: moneys,
      labelBuilder: (money) => money.nombre ?? '',
      isSelected: (money) => (money.nombre ?? '') == moneda,
    );

    if (selected == null) {
      return;
    }

    final selectedName = (selected.nombre ?? '').trim();
    setState(() {
      moneda = selectedName;
      moneyTypeIdShowError = false;



      showDollar = selectedName.contains('DÓLAR') || selectedName.contains('DOLAR');
      showCheque = selectedName.contains('CHEQUE');

      if (!showDollar) {
        cantDollarController.clear();
        cambioDollarController.clear();
        cantDollarShowError = false;
        precioDollarShowError = false;
      }

      if (!showCheque) {
        idbank = 0;
        idChequeController.clear();
        bankShowError = false;
        idChequeShowError = false;
      }
    });
  }

  Future<void> _onSelectBank() async {
    if (banks.isEmpty) {
      return;
    }

    final selected = await _showSelectionSheet<Bank>(
      title: 'Selecciona un banco',
      options: banks,
      labelBuilder: (bank) => bank.nombre ?? '',
      isSelected: (bank) => (bank.idbanco ?? 0) == idbank,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      idbank = selected.idbanco ?? 0;
      bankShowError = false;
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
        montoShowError = false;
      },
    );
  }

  Widget _buildChequeField() {
    return TextField(
      controller: idChequeController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: kNewtextPri,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: kNewred,
      decoration: darkDecoration(
        label: 'Cheque #',
        hint: 'Ingresa el numero del cheque',
        errorText: idChequeShowError ? idChequeError : null,
        suffixIcon: const Icon(Icons.numbers, color: kNewtextSec),
      ),
      onChanged: (_) {
        idChequeShowError = false;
      },
    );
  }

  Widget _buildDollarQuantityField() {
    return TextField(
      controller: cantDollarController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: kNewtextPri,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: kNewred,
      decoration: darkDecoration(
        label: 'Cantidad en dolares',
        hint: 'Ingresa la cantidad',
        errorText: cantDollarShowError ? cantDollarError : null,
        suffixIcon: const Icon(Icons.attach_money_outlined, color: kNewtextSec),
      ),
      onChanged: (_) {
        cantDollarShowError = false;
      },
    );
  }

  Widget _buildDollarRateField() {
    return TextField(
      controller: cambioDollarController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: kNewtextPri,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: kNewred,
      decoration: darkDecoration(
        label: 'Tipo de cambio',
        hint: 'Ingresa el valor por dolar',
        errorText: precioDollarShowError ? precioDollarError : null,
        suffixIcon: const Icon(Icons.paid_outlined, color: kNewtextSec),
      ),
      onChanged: (_) {
        precioDollarShowError = false;
      },
    );
  }

  Future<void> _getMoneys() async {
    setState(() {
      _showLoader = true;
    });

    final Response response = await ApiHelper.getMoneys();

    if (!mounted) return;

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    setState(() {
      moneys = response.result;
    });
  }

  Future<void> _getBanks() async {
    setState(() {
      _showLoader = true;
    });

    final Response response = await ApiHelper.getBanks();

    if (!mounted) return;

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    setState(() {
      banks = response.result;
    });
  }

  void _goDeposito() async {
    if (!_validateFields()) {
      return;
    }

    await _addDeposito();
  }

  bool _validateFields() {
    bool isValid = true;

    final montoValue = montoController.text.trim();
    if (montoValue.isEmpty) {
      isValid = false;
      montoShowError = true;
      montoError = 'Debes ingresar el monto.';
    } else {
      montoShowError = false;
    }

    if (moneda.isEmpty) {
      isValid = false;
      moneyTypeIdShowError = true;
      moneyTypeIdError = 'Debes seleccionar una moneda.';
    } else {
      moneyTypeIdShowError = false;
    }

    if (showDollar) {
      if (cantDollarController.text.trim().isEmpty) {
        isValid = false;
        cantDollarShowError = true;
        cantDollarError = 'Debes ingresar la cantidad en dolares.';
      } else {
        cantDollarShowError = false;
      }

      if (cambioDollarController.text.trim().isEmpty) {
        isValid = false;
        precioDollarShowError = true;
        precioDollarError = 'Debes ingresar el tipo de cambio.';
      } else {
        precioDollarShowError = false;
      }
    }

    if (showCheque) {
      if (idbank == 0) {
        isValid = false;
        bankShowError = true;
        bankError = 'Debes seleccionar un banco.';
      } else {
        bankShowError = false;
      }

      if (idChequeController.text.trim().isEmpty) {
        isValid = false;
        idChequeShowError = true;
        idChequeError = 'Debes ingresar el numero de cheque.';
      } else {
        idChequeShowError = false;
      }
    }

    setState(() {});
    return isValid;
  }

  Future<void> _addDeposito() async {
    setState(() {
      _showLoader = true;
    });
    
    final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
    

    final Deposito deposito = Deposito(
      iddeposito: 0,
      monto: int.tryParse(montoController.text.trim()) ?? 0,
      cedulaempleado: cierreActPro.usuario!.cedulaEmpleado,
      idcierre: cierreActPro.cierreFinal!.idcierre,
      moneda: moneda,
    );

    final Map<String, dynamic> request = deposito.toJson();
    final Response response = await ApiHelper.post(
      'api/Depositos/',
      request,
    );

    Response responseDollar = Response(isSuccess: true);
    if (showDollar) {
      final Dollar dollar = Dollar(
        id: 0,
        cantidad: int.tryParse(cantDollarController.text.trim()) ?? 0,
        preciocambio: int.tryParse(cambioDollarController.text.trim()) ?? 0,
        monto: int.tryParse(montoController.text.trim()) ?? 0,
        idcierre: cierreActPro.cierreFinal!.idcierre,
      );
      responseDollar = await ApiHelper.post(
        'api/Cierres/PostDollar',
        dollar.toJson(),
      );
    }

    Response responseCheque = Response(isSuccess: true);
    if (showCheque) {
      final Cheque cheque = Cheque(
        idcheque: int.tryParse(idChequeController.text.trim()) ?? 0,
        idbanco: idbank,
        cedulaempleado: cierreActPro.usuario!.cedulaEmpleado,
        monto: int.tryParse(montoController.text.trim()) ?? 0,
        idcierre: cierreActPro.cierreFinal!.idcierre,
      );
      responseCheque = await ApiHelper.post(
        'api/Cierres/PostCheque',
        cheque.toJson(),
      );
    }

    if (!mounted) return;

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    if (!responseDollar.isSuccess) {
      _showErrorDialog(responseDollar.message);
      return;
    }

    if (!responseCheque.isSuccess) {
      _showErrorDialog(responseCheque.message);
      return;
    }

    await Fluttertoast.showToast(
      msg: "Deposito creado correctamente.",
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
