import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/FuelRed/all_fact.dart';
import 'package:tester/Models/LogIn/estado_login.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/new_home_screen.dart';
import 'package:tester/Screens/logIn/invent_screen.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  String _password = '';
  String _passwordError = '';
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordShow = false;
  bool _showLoader = false;
  LogInEstado login = LogInEstado();
  int _selectedZone = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
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
          // Sutil acento rojo arriba
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFC0102).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
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
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: SlideTransition(
                              position: _slideAnim,
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: _buildFormCard(context),
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

  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 44),
          // Zona selector
          Text(
            'ZONA DE TRABAJO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          _ZoneCardSelector(
            selected: _selectedZone,
            onSelect: (z) => setState(() => _selectedZone = z),
          ),
          const SizedBox(height: 36),
          _buildPassword(),
          const SizedBox(height: 40),
          _loginButton(),
          const SizedBox(height: 24),
          Text(
            'Acceso restringido a personal autorizado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          keyboardType: TextInputType.number,
          obscureText: !_passwordShow,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          cursorColor: const Color(0xFFFC0102),
          decoration: InputDecoration(
            labelText: 'Cedula',
            labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
            prefixIcon: const Icon(Icons.badge_outlined,
                color: Color(0xFFFC0102), size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordShow
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _passwordShow = !_passwordShow),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFC0102), width: 1.5),
            ),
          ),
          onChanged: (v) => _password = v,
        ),
        if (_passwordError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              _passwordError,
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _loginButton() {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFC0102), Color(0xFFD50000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFC0102).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _login,
          child: const Text(
            'INICIAR SESION',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /* ================= LOGIN ================= */
  Future<void> _login() async {
    if (_selectedZone == 0) {
      Fluttertoast.showToast(
          gravity: ToastGravity.TOP, msg: 'Selecciona la Zona');
      return;
    }

    if (_password.isEmpty) {
      setState(() => _passwordError = 'Digita la Cedula');
      return;
    }

    int cedula;
    try {
      cedula = int.parse(_password);
    } catch (_) {
      setState(() => _passwordError = 'La cedula debe ser numerica');
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

    final AllFact factura = response.result;

    if (factura.cierreActivo!.cierreFinal.estado!.isEmpty) {
      setState(() => _showLoader = false);
      return goInvent(factura.cierreActivo!.cajero.cedulaEmpleado);
    }

    if (!mounted) return;
    final clienteProv = context.read<ClienteProvider>();
    clienteProv.loadClientesBy(ClienteTipo.contado);
    clienteProv.loadClientesBy(ClienteTipo.credito);

    if (!mounted) return;
    context.read<CierreActivoProvider>().setFrom(factura.cierreActivo!);

    context.read<MapProvider>().connect();

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
}

/* ================= HEADER ================= */
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFC0102).withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFC0102).withValues(alpha: 0.15),
                width: 1.5),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              color: Color(0xFFFC0102), size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'FuelRed',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SISTEMA DE DESPACHO',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

/* ================= ZONE CARD SELECTOR ================= */
class _ZoneCardSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _ZoneCardSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _zoneCard(1, Icons.looks_one_outlined, 'Zona 1')),
        const SizedBox(width: 12),
        Expanded(child: _zoneCard(2, Icons.looks_two_outlined, 'Zona 2')),
      ],
    );
  }

  Widget _zoneCard(int zone, IconData icon, String label) {
    final isSelected = selected == zone;
    return GestureDetector(
      onTap: () => onSelect(zone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC0102).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFC0102).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color(0xFFFC0102)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
