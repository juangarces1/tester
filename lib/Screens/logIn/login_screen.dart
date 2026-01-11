import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

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
  final TextEditingController _passwordController = TextEditingController();

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
      body: Stack(
        children: [
          // FIXED BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF02050A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 40),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildFormCard(context),
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
    return _glassTextField(
      controller: _emailCtrl,
      hint: 'Correo electrónico',
      icon: Icons.alternate_email,
      keyboardType: TextInputType.emailAddress,
      errorText: _emailError.isEmpty ? null : _emailError,
      onChanged: (_) {
        if (_emailError.isNotEmpty) setState(() => _emailError = '');
      },
    );
  }

  /* ================= PASSWORD (Cédula) ================= */
  Widget _buildPassword() {
    return _glassTextField(
      controller: _passwordController, // Usando el controller correcto
      hint: 'Cédula',
      icon: Icons.badge_outlined,
      keyboardType: TextInputType.number,
      obscureText: !_passwordShow,
      errorText: _passwordError.isEmpty
          ? null
          : _passwordError, // Usando _passwordError
      onChanged: (v) => _password = v,
      suffixIcon: IconButton(
        icon: Icon(
          _passwordShow
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: Colors.white70,
        ),
        onPressed: () => setState(() => _passwordShow = !_passwordShow),
      ),
    );
  }

  // Helper para inputs estilo Glass
  Widget _glassTextField({
    TextEditingController? controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          cursorColor: const Color(0xFFFC0102),
          decoration: InputDecoration(
            labelText: hint,
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(icon, color: const Color(0xFFFC0102)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Color(0xFFFC0102), width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              errorText,
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
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
      Fluttertoast.showToast(
          gravity: ToastGravity.TOP, msg: 'Selecciona la Zona');
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
    clienteProv.loadClientesBy(ClienteTipo.contado);
    clienteProv.loadClientesBy(ClienteTipo.credito);

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
        builder: (_) =>
            InventScreen(cedulaEmpleado: cedulaUser, zona: _selectedZone),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 56),
          const Text(
            'ZONA DE TRABAJO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          _ZoneSelector(
            selected: _selectedZone,
            onSelect: (z) => setState(() => _selectedZone = z),
          ),
          const SizedBox(height: 48),
          _buildPassword(),
          const SizedBox(height: 56),
          _m3LoginButton(),
          const SizedBox(height: 32),
          const Text(
            'Acceso restringido a personal autorizado.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _m3LoginButton() {
    return SizedBox(
      height: 64,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFC0102),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: _login,
        child: const Text(
          'INICIAR SESIÓN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
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
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFC0102).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFC0102).withValues(alpha: 0.2),
                width: 2),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              color: Color(0xFFFC0102), size: 54),
        ),
        const SizedBox(height: 28),
        const Text(
          'FuelRed',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BIENVENIDO DE NUEVO',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
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
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
            value: 1, label: Text('ZONA 1'), icon: Icon(Icons.map_outlined)),
        ButtonSegment(
            value: 2, label: Text('ZONA 2'), icon: Icon(Icons.map_rounded)),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onSelect(set.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedBackgroundColor: const Color(0xFFFC0102),
        selectedForegroundColor: Colors.white,
        foregroundColor: Colors.white70,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
