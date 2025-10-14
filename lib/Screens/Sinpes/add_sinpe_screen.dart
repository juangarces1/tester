import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

class AddSinpeScreen extends StatefulWidget {
  const AddSinpeScreen({super.key, });

  
  @override
  State<AddSinpeScreen> createState() => _AddSinpeScreenState();
}

class _AddSinpeScreenState extends State<AddSinpeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showLoader = false;

  final TextEditingController comprobanteController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  final TextEditingController notaController = TextEditingController();

  @override
  void dispose() {
    comprobanteController.dispose();
    montoController.dispose();
    notaController.dispose();
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
          title: 'Nuevo sinpe',
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
                  const Text(
                    'Registrar sinpe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kNewtextPri,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa los campos para registrar un nuevo movimiento SINPE.',
                    style: TextStyle(
                      fontSize: 14,
                      color: kNewtextMut,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kNewsurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kNewborder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: comprobanteController,
                            label: 'Número de comprobante',
                            hint: 'Ingresa el número de comprobante',
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el núfdmero de comprobante';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: montoController,
                            label: 'Monto',
                            hint: 'Ingresa el monto del sinpe',
                            textInputAction: TextInputAction.next,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Ingresa un monto v�lido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: notaController,
                            label: 'Nota (opcional)',
                            hint: 'Ingresa una nota',
                            textInputAction: TextInputAction.done,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kNewgreen,
                                foregroundColor: kNewtextPri,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _createSinpe,
                              child: const Text(
                                'Registrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
       style: const TextStyle(
        color: kNewtextPri,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: Colors.white,
      decoration: darkDecoration(
        label: label,
        hint: hint,
        fillColor: kNewsurfaceHi,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          color: kNewtextSec,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: kNewtextMut,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Future<void> _createSinpe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _showLoader = true;
    });

    var cierreFinal = Provider.of<CierreActivoProvider>(context, listen: false).cierreFinal!;
    var empleado = Provider.of<CierreActivoProvider>(context, listen: false).cajero!;

    final sinpe = Sinpe(
      id: 0,
      numComprobante: comprobanteController.text.trim(),
      nota: notaController.text.trim(),
      idCierre: cierreFinal.idcierre ?? 0,
      nombreEmpleado:
          '${empleado.nombre} ${empleado.apellido1}',
      fecha: DateTime.now(),
      numFact: '',
      activo: 0,
      monto: double.tryParse(montoController.text.trim()) ?? 0,
    );

    final Response response = await ApiHelper.post(
      'api/Sinpes/',
      sinpe.toJson(),
    );

    if (!mounted) return;

    setState(() {
      _showLoader = false;
    });

    if (!response.isSuccess) {
      _showErrorDialog(response.message);
      return;
    }

    await Fluttertoast.showToast(
      msg: 'Sinpe creado correctamente.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
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
