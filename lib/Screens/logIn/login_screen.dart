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
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordShow = false;
  bool _showLoader = false;
  LogInEstado login = LogInEstado();
  int _selectedZone = 0;

  static Widget _buildAuroraBlob(Color color,
      {double size = 300, double opacity = 0.6}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }

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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF02050A), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Ambient Blobs
          Positioned(
            top: -100,
            left: -100,
            child: _buildAuroraBlob(kPrimaryColor, size: 400, opacity: 0.4),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildAuroraBlob(const Color(0xFF3B82F6),
                size: 350, opacity: 0.3),
          ),
          Positioned(
            top: 200,
            right: -150,
            child:
                _buildAuroraBlob(Colors.purpleAccent, size: 250, opacity: 0.2),
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
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 24),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildFormCard(context)),
                                ],
                              ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
          ),
          errorText: errorText,
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        onChanged: onChanged,
      ),
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
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: _Header()),
              const SizedBox(height: 40),
              Center(
                child: _ZoneSelector(
                  selected: _selectedZone,
                  onSelect: (z) => setState(() => _selectedZone = z),
                ),
              ),
              const SizedBox(height: 40),
              _buildPassword(),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _login,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'INGRESAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Acceso restringido a personal autorizado.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
                color: Colors.blueAccent.withValues(alpha: 0.6),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige una zona e inicia sesión para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
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
      checkmarkColor: Colors.white,
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
