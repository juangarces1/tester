import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/ConsoleModels/console_user.dart';
import 'package:tester/Models/LogIn/estado_login.dart';
import 'package:tester/Models/FuelRed/all_fact.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/usuario_provider.dart';

import 'package:tester/Screens/NewHome/new_home_screen.dart';
import 'package:tester/Screens/logIn/invent_screen.dart';
import 'package:tester/Screens/logIn/nfc_test.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------------- NUEVO: email ----------------
  final TextEditingController _emailCtrl = TextEditingController();
  String _emailError = '';

  // ---------------- Actual (cédula como "password") ----------------
  String _password = '';
  String _passwordError = '';

  bool _passwordShow = false;
  bool _showLoader = false;
  LogInEstado login = LogInEstado();
  int _selectedZone = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: kContrateFondoOscuro,
      body: Stack(
        children: [
          // BG image
          Positioned.fill(
            child: Image.asset(
              'assets/BgLogin.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                const _Header(),
                                const SizedBox(height: 24),

                                _ZoneSelector(
                                  selected: _selectedZone,
                                  onSelect: (z) => setState(() => _selectedZone = z),
                                ),

                                const SizedBox(height: 24),

                                // Correo (opcional por ahora)
                                // _buildEmail(),
                                // const SizedBox(height: 16),

                                _buildPassword(),
                                const SizedBox(height: 24),

                                DefaultButton(
                                  text:  'ENTRAR',
                                  press: _showLoader ? null : _login,
                                  color: kPrimaryColor,
                                  gradient: kPrimaryGradientColor,
                                ),

                                const SizedBox(height: 24),
                                   DefaultButton(
                                  text: 'NFC',
                                  press: _showLoader ? null : _goNNfc,
                                  color: kPrimaryColor,
                                  gradient: kPrimaryGradientColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_showLoader) const LoaderComponent(loadingText: 'Cargando...'),
        ],
      ),
    );
  }

  /* ================= NUEVO: EMAIL ================= */
  Widget _buildEmail() {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: kNewtextPri),
      cursorColor: kPrimaryColor,
      decoration: darkDecoration(
        hint: 'Correo electrónico',
        errorText: _emailError.isEmpty ? null : _emailError,
        suffixIcon: const Icon(Icons.alternate_email, color: kNewtextSec),
      ),
      onChanged: (_) {
        if (_emailError.isNotEmpty) setState(() => _emailError = '');
      },
    );
  }

  /* ================= PASSWORD (Cédula) ================= */
  Widget _buildPassword() {
    return TextField(
      keyboardType: TextInputType.number,
      obscureText: !_passwordShow,
      style: const TextStyle(color: kNewtextPri),
      cursorColor: kPrimaryColor,
      decoration: darkDecoration(
        hint: 'Ingrese la Cédula',
        errorText: _passwordError.isEmpty ? null : _passwordError,
        suffixIcon: IconButton(
          icon: Icon(_passwordShow ? Icons.visibility : Icons.visibility_off, color: kNewtextSec),
          onPressed: () => setState(() => _passwordShow = !_passwordShow),
        ),
      ),
      onChanged: (v) => _password = v,
    );
  }

  Future<void> _goNNfc() async {
       Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NfcTestPage(),
      ),
    );
  }

  /* ================= LOGIN ================= */
  Future<void> _login() async {
    // Validaciones comunes
    if (_selectedZone == 0) {
      Fluttertoast.showToast(msg: 'Selecciona la Zona');
      return;
    }

    if (_password.isEmpty) {
      setState(() => _passwordError = 'Digita la Cédula');
      return;
    }

    int cedula;
    try {
      cedula = int.parse(_password);
    } catch (_) {
      setState(() => _passwordError = 'La cédula debe ser numérica');
      return;
    }

    setState(() => _showLoader = true);

    final response = await ApiHelper.getLogInNuevo(_selectedZone, cedula);

    if (!response.isSuccess) {
      setState(() => _showLoader = false);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    // Login en UsuarioProvider (mock por ahora)
    final usuarioProv = context.read<UsuarioProvider>();
    const ConsoleUser user = ConsoleUser(
      identifier: 'B32809EE018B2811',
      email: 'sebastian.garces23@gmail.com',
      rol: UserRole.operador,
      verificado: true,
    );
    await usuarioProv.signIn(user);

    // Precarga mapa
    final mapProv = context.read<MapProvider>();
    try {
      await mapProv.loadMap();
    } catch (e) {
      setState(() => _showLoader = false);
      Fluttertoast.showToast(
        msg: 'No se pudo cargar la configuración de la estación: $e',
      );
      return;
    }

    // Manejo de factura
    final AllFact factura = response.result;

    if (factura.cierreActivo!.cierreFinal.estado!.isEmpty) {
      setState(() => _showLoader = false);
      return goInvent(factura.cierreActivo!.cajero.cedulaEmpleado);
    }

    final clienteProv = context.read<ClienteProvider>();
    await clienteProv.loadClientesBy(ClienteTipo.contado);
    await clienteProv.loadClientesBy(ClienteTipo.credito);

    if (!mounted) return;
    context.read<CierreActivoProvider>().setFrom(factura.cierreActivo!);

    setState(() => _showLoader = false);
    goHome();
  }

  /* ================= NAVIGATION ================= */
  void goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NewHomeScreen()),
    );
  }

  void goInvent(int cedulaUser) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InventScreen(cedulaEmpleado: cedulaUser, zona: _selectedZone),
      ),
    );
  }

 
}

/* ================= WIDGETS AUX ================= */
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'FuelRed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.blueAccent.withOpacity(0.6),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Controla tu estación al instante',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.lightBlueAccent.shade100,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ZoneSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _ZoneSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('Zona 1', 1),
        const SizedBox(width: 12),
        _chip('Zona 2', 2),
      ],
    );
  }

  Widget _chip(String label, int value) {
    final bool isSelected = selected == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: kPrimaryColor,
      backgroundColor: kNewtextPri,
      elevation: 2,
      pressElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
