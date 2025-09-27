import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

// OJO: Quitamos el client_card simple para evitar confusión de nombres
// import 'package:tester/Components/client_card.dart';
import 'package:tester/Components/color_button.dart';
import 'package:tester/Components/custom_surfix_icon.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/helpers/api_helper.dart';

import 'package:tester/Screens/clientes/cliente_card.dart' as ClienteUI; // ← usamos el ClienteCard completo

import '../../constans.dart';
import '../../sizeconfig.dart';

class ClietesAddScreen extends StatefulWidget {
  final Invoice factura;
  final String ruta;

  const ClietesAddScreen({
    super.key,
    required this.factura,
    required this.ruta,
  });

  @override
  State<ClietesAddScreen> createState() => _ClietesAddScreenState();
}

class _ClietesAddScreenState extends State<ClietesAddScreen> {
  // Formularios
  final _docFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();

  // Estado
  bool _loading = false;
  String _loaderText = 'Procesando…';
  Cliente? _cliente; // tras consultar

  // Controllers
  final _docCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Focus
  final _docFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _docCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _docFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  bool get _hasCliente => _cliente != null;

  @override
  Widget build(BuildContext context) {
    final step = _hasCliente ? 2 : 1;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: kPrimaryColor,
          title: const Text(
            "Nuevo Cliente",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image.asset('assets/splash.png', width: 30, height: 30, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(16), vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepHeader(current: step),
                    const SizedBox(height: 12),

                    // Paso 1 – Documento
                    _SectionCard(
                      title: "Consultar Cliente (Hacienda)",
                    
                      child: _buildDocForm(),
                    ),

                    // Resultado y Paso 2 – Detalles
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: !_hasCliente
                          ? const SizedBox.shrink()
                          : Column(
                              key: const ValueKey('details'),
                              children: [
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: "Resultado",
                                  subtitle: "Verifica que el contribuyente sea el correcto.",
                                  // Usamos el ClienteCard completo con actividades visibles (solo lectura)
                                  child: ClienteUI.ClienteCard(
                                    cliente: _cliente!,
                                    factura: widget.factura,
                                    index: 0,
                                    showEmails: false,
                                    showActividades: true,
                                    showSelectButton: false,
                                    readOnly: true,
                                    // Fondo del card acorde al tema; el propio card ajusta contraste
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: "Completar datos",
                                  subtitle: "Ingresa email y teléfono para terminar el registro.",
                                  child: _buildDetailsForm(),
                                ),
                                const SizedBox(height: 8),
                                DefaultButton(
                                  text: "Crear",
                                  press: _createClient,
                                  color: kPrimaryColor,
                                  gradient: kPrimaryGradientColor,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            if (_loading) LoaderComponent(loadingText: _loaderText),
          ],
        ),
      ),
    );
  }

  // =========================
  // Paso 1: Documento
  // =========================
  Widget _buildDocForm() {
    return Form(
      key: _docFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _docCtrl,
            focusNode: _docFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Ingresa un documento…',
              labelText: 'Documento',
              helperText: 'Al menos 9 dígitos.',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Pegar',
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      final text = (data?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (text.isNotEmpty) {
                        setState(() => _docCtrl.text = text);
                      }
                    },
                  ),
                  if (_docCtrl.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _docCtrl.clear()),
                    ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) => setState(() {}), // para refrescar suffix
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Debes ingresar un documento.';
              if (value.length < 9) return 'Debes ingresar un documento de al menos 9 dígitos.';
              return null;
            },
            onFieldSubmitted: (_) => _getClient(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ColorButton(
                  text: "Buscar Cliente",
                  ancho: double.infinity,
                  color: kPrimaryColor,
                  press: _getClient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // Paso 2: Email + Teléfono
  // =========================
  Widget _buildDetailsForm() {
    return Form(
      key: _detailsFormKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Ingresa el email…',
              labelText: 'Email',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: const CustomSurffixIcon(svgIcon: 'assets/Mail.svg'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Debes ingresar un email.';
              if (!EmailValidator.validate(value)) return 'Debes ingresar un email válido.';
              return null;
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          const SizedBox(height: 12),

          // Teléfono
          TextFormField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Teléfono',
              hintText: 'Ej. 88888888',
              prefixIcon: const Icon(Icons.phone_iphone),
              suffixIcon: const CustomSurffixIcon(svgIcon: 'assets/User.svg'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Por favor digita el teléfono.';
              if (value.length < 8) return 'El teléfono debe tener al menos 8 dígitos.';
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _createClient(),
          ),
        ],
      ),
    );
  }

  // =========================
  // Acciones
  // =========================
  Future<void> _getClient() async {
    _hideKeyboard();
    if (!_docFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _loaderText = 'Consultando…';
    });

    final Response response = await ApiHelper.getClienteFromHacienda(_docCtrl.text.trim());

    setState(() => _loading = false);

    if (!response.isSuccess) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [TextButton(child: const Text('Aceptar'), onPressed: () => Navigator.of(ctx).pop())],
        ),
      );
      return;
    }

    final cli = response.result as Cliente;
    setState(() {
      _cliente = cli;
      // El backend no trae email/teléfono; déjalos vacíos para forzar captura
      _emailCtrl.text = '';
      _phoneCtrl.text = '';
    });

    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) _emailFocus.requestFocus();
  }

  Future<void> _createClient() async {
    _hideKeyboard();

    if (_cliente == null) {
      Fluttertoast.showToast(
        msg: "Primero consulta el documento.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    if (!_detailsFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _loaderText = 'Creando…';
    });

    final documento = _cliente!.documento.isNotEmpty ? _cliente!.documento : _docCtrl.text.trim();
    _cliente!.documento=documento;
    _cliente!.tipo='Contado';
    _cliente!.email =_emailCtrl.text.trim();
    _cliente!.telefono = _phoneCtrl.text.trim();
       // Backend: NumeroDocumento + Email (+ opcional teléfono/tipoPago…)
    // final req = {
    //   'numeroDocumento': documento,
    //   'email': _emailCtrl.text.trim(),
    //   'telefono': _phoneCtrl.text.trim(), // si tu API lo acepta
    //   // 'tipoCliente': 'CONTADO',
    //   // 'tipoPago': 'EFECTIVO',
    // };

    final Response response = await ApiHelper.post('api/clientes/crear', _cliente!.toJson());

    setState(() => _loading = false);

    if (!response.isSuccess) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [TextButton(child: const Text('Aceptar'), onPressed: () => Navigator.of(ctx).pop())],
        ),
      );
      return;
    }

    final created = response.result is Cliente
        ? response.result as Cliente
        : _cliente!.copyWith(
            email: _emailCtrl.text.trim(),
            telefono: _phoneCtrl.text.trim(),
          );

    Fluttertoast.showToast(
      msg: "Cliente creado correctamente",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pop(context, created);
  }
}

/// Encabezado de pasos (1/2) con estilo suave
class _StepHeader extends StatelessWidget {
  final int current; // 1 o 2
  const _StepHeader({required this.current});

  @override
  Widget build(BuildContext context) {
    active(int n) => current >= n;
    Color dot(bool a) => a ? kPrimaryColor : Colors.grey.shade400;

    return Row(
      children: [
        _Dot(label: 'Documento', color: dot(active(1))),
        _Line(),
        _Dot(label: 'Completar', color: dot(active(2))),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final Color color;
  const _Dot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 8, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.white24),
    );
  }
}

/// Card reutilizable para secciones con contraste automático
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? backgroundColor; // opcional

  const _SectionCard({required this.title, this.subtitle, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? kContrateFondoOscuro;
    final isDark = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark;
    final on = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white70 : Colors.black54;

    return Card(
      color: bg,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: on),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: on)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(fontSize: 13, color: onMuted)),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
