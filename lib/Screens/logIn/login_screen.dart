import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';                    // sin alias ahora
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/ConsoleModels/console_user.dart';
import 'package:tester/Models/LogIn/estado_login.dart';
import 'package:tester/Models/FuelRed/all_fact.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/map_provider.dart';         // <-- mapa clásico
import 'package:tester/Providers/usuario_provider.dart';
import 'package:tester/Screens/NewHome/new_home_screen.dart';
import 'package:tester/Screens/logIn/invent_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/sizeconfig.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ---------------- NUEVO: email ----------------
  final TextEditingController _emailCtrl = TextEditingController();
  String _emailError = '';

  // ---------------- Actual (cédula como "password") ----------------
  String _password = '';
  final String _passwordError = '';

  bool _passwordShow = false;
  bool _showLoader = false;
  LogInEstado login = LogInEstado();
  int _selectedZone = 0;
  
 
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/BgLogin.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: SizeConfig.screenHeight * 0.07),
                  buildWelcomeText(),
                  const SizedBox(height: 20),

                  _showZoneButtons(),
                  const SizedBox(height: 20),

                  // ---------- NUEVO: Campo Email (comentado por ahora) ----------
                  // _showEmail(),
                  // const SizedBox(height: 16),

                  // ---------- Actual: Campo Cédula ----------
                  _showPassword(),

                  const SizedBox(height: 20),
                  DefaultButton(
                    text: "ENTRAR",
                    press: _login,
                    color: kPrimaryColor,
                    gradient: kPrimaryGradientColor,
                  ),

                 
                ],
              ),
            ),
          ),
          _showLoader
              ? const LoaderComponent(loadingText: 'Cargando...')
              : Container(),
        ],
      ),
    );
  }

  Widget buildWelcomeText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Título FuelRed
        Text(
          "FuelRed",
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

        // Subtítulo
        Text(
          "Controla tu estación al instante",
          style: TextStyle(
            fontSize: 18,
            color: Colors.lightBlueAccent.shade100,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /* ================= ZONA ================= */
  void _selectZone(int zone) {
    setState(() => _selectedZone = zone);
  }

  Widget _showZoneButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: _selectedZone == 1 ? Colors.white : Colors.black,
            backgroundColor: _selectedZone == 1 ? kPrimaryColor : kNewtextPri,
          ),
          onPressed: () => _selectZone(1),
          child: const Text('Zona 1',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: _selectedZone == 2 ? Colors.white : Colors.black,
            backgroundColor: _selectedZone == 2 ? kPrimaryColor : kNewtextPri,
          ),
          onPressed: () => _selectZone(2),
          child: const Text('Zona 2',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  /* ================= NUEVO: EMAIL ================= */
  Widget _showEmail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TextField(
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
      ),
    );
  }

  /* ================= PASSWORD (Cédula) ================= */
  Widget _showPassword() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: TextField(
        keyboardType: TextInputType.number,
        obscureText: !_passwordShow,
        style: const TextStyle(color: kNewtextPri),
        cursorColor: kPrimaryColor,
        decoration: darkDecoration(
          hint: 'Ingrese la Cédula',
          errorText: _passwordError.isEmpty ? null : _passwordError,
          suffixIcon: IconButton(
            icon: _passwordShow
                ? const Icon(Icons.visibility, color: kNewtextSec)
                : const Icon(Icons.visibility_off, color: kNewtextSec),
            onPressed: () => setState(() => _passwordShow = !_passwordShow),
          ),
        ),
        onChanged: (v) => _password = v,
      ),
    );
  }

  /* ================= LOGIN ================= */
  Future<void> _login() async {
    // ---------- Validaciones comunes ----------
    if (_selectedZone == 0) {
      Fluttertoast.showToast(msg: 'Selecciona la Zona');
      return;
    }
    // final email = _emailCtrl.text.trim();
    // if (email.isEmpty || !email.contains('@')) {
    //   setState(() => _emailError = 'Ingresa un correo válido');
    //   return;
    // }

    setState(() => _showLoader = true);

    // ========== LÓGICA ANTERIOR (CONSERVADA) ==========
    if (_password.isEmpty) {
      Fluttertoast.showToast(msg: 'Digita la Cédula');
      setState(() => _showLoader = false);
      return;
    }

    final response =
        await ApiHelper.getLogInNuevo(_selectedZone, int.parse(_password));

    if (!response.isSuccess) {
      setState(() => _showLoader = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'))
          ],
        ),
      );
      return;
    }

    final usuarioProv = Provider.of<UsuarioProvider>(context, listen: false);
    ConsoleUser user = const ConsoleUser(
        identifier: 'B32809EE018B2811',
        email: 'sebastian.garces23@gmail.com',
        rol: UserRole.operador,
        verificado: true);
    await usuarioProv.signIn(user);

    // Precarga mapa (clásico)
    final mapProv = Provider.of<MapProvider>(context, listen: false);
    try {
      await mapProv.loadMap(); // clásico: carga manual
    } catch (e) {
      setState(() => _showLoader = false);
      Fluttertoast.showToast(
          msg: 'No se pudo cargar la configuración de la estación: $e');
      return;
    }

    // Manejo de factura
    final AllFact factura = response.result;

    if (factura.cierreActivo!.cierreFinal.estado!.isEmpty) {
      setState(() => _showLoader = false);
      return goInvent(factura.cierreActivo!.cajero.cedulaEmpleado);
    }

    final clienteProv = Provider.of<ClienteProvider>(context, listen: false);
    await clienteProv.loadClientesBy(ClienteTipo.contado);
    await clienteProv.loadClientesBy(ClienteTipo.credito);

    setState(() => _showLoader = false);
    if (!mounted) return;
    context.read<CierreActivoProvider>().setFrom(factura.cierreActivo!);
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
              InventScreen(cedulaEmpleado: cedulaUser, zona: _selectedZone)),
    );
  }
}
