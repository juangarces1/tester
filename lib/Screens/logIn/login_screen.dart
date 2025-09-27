import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';                    // sin alias ahora
import 'package:tester/Components/default_button.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/ConsoleModels/console_user.dart';
import 'package:tester/Models/LogIn/estado_login.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/cart.dart';
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildWelcomeText(),
                    const SizedBox(height: 20),

                    _showZoneButtons(),
                    const SizedBox(height: 20),

                    // ---------- NUEVO: Campo Email ----------
                    // _showEmail(),

                    // const SizedBox(height: 16),

                    // ---------- Actual: Campo Cédula (lo conservamos) ----------
                   _showPassword(), // sigue visible para pruebas / transición

                    const SizedBox(height: 30),
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
          ),
          _showLoader ? const LoaderComponent(loadingText: 'Cargando...') : Container(),
        ],
      ),
    );
  }

  Widget buildWelcomeText() {
    return  Column(
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
        const SizedBox(height: 24),

        // Texto de bienvenida
        // Text(
        //   "Bienvenido 👋\nInicia sesión para gestionar\n"
        //   "tus despachos y facturación",
        //   textAlign: TextAlign.center,
        //   style: TextStyle(
        //     fontSize: 15,
        //     color: Colors.blueGrey.shade200,
        //     height: 1.4,
        //   ),
        // ),
        const SizedBox(height: 32),
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
          child: const Text('Zona 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: _selectedZone == 2 ? Colors.white : Colors.black,
            backgroundColor: _selectedZone == 2 ? kPrimaryColor : kNewtextPri,
          ),
          onPressed: () => _selectZone(2),
          child: const Text('Zona 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

    // ========== NUEVA LÓGICA: "login" sin password ==========
    // try {
    //   final auth = AuthService(ConsoleApiHelper());
    //   final user = await auth.loginWithEmailOnly(email);

    //   final usuarioProv = Provider.of<UsuarioProvider>(context, listen: false);
    //   await usuarioProv.signIn(user);

    //   // 2) Precargar mapa (como ya lo haces)
    //   final mapProv = Provider.of<MapProvider>(context, listen: false);
    //   await mapProv.loadMap();

    //   if (!mounted) return;
    //   setState(() => _showLoader = false);

    //   // 3) Por ahora, mostramos confirmación y dejamos TODO de navegación.
    
    //   // ================== TODO de Integración ==================
    //   // Aquí, cuando tengas el backend de login real que devuelve AllFact,
    //   // puedes reutilizar la navegación que ya tienes abajo (comentada).
    //   // Por ejemplo:
    //   // goHome(factura);  // o goInvent(...)
    //   // =========================================================

    // } catch (e) {
    //   if (!mounted) return;
    //   setState(() => _showLoader = false);
    //   showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //       title: const Text('Error'),
    //       content: Text('No fue posible autenticar con el email.\n$e'),
    //       actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar'))],
    //     ),
    //   );
    // }



    // ========== LÓGICA ANTERIOR (CONSERVADA / COMENTADA) ==========
    
    if (_password.isEmpty) {
      Fluttertoast.showToast(msg: 'Digita la Cédula');
      return;
    }

    setState(() => _showLoader = true);

    final response = await ApiHelper.getLogInNuevo(
        _selectedZone, int.parse(_password));

    if (!response.isSuccess) {
      setState(() => _showLoader = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar'))],
        ),
      );
      return;
    }

    final usuarioProv = Provider.of<UsuarioProvider>(context, listen: false);
    ConsoleUser user = const ConsoleUser(
      identifier: 'B32809EE018B2811', email: 'sebastian.garces23@gmail.com', rol: UserRole.operador, verificado: true
    );
    await usuarioProv.signIn(user);

    // Precarga mapa (clásico)
    final mapProv = Provider.of<MapProvider>(context, listen: false);
    try {
      await mapProv.loadMap(); // clásico: carga manual
    } catch (e) {
      setState(() => _showLoader = false);
      Fluttertoast.showToast(msg: 'No se pudo cargar la configuración de la estación: $e');
      return;
    }
   

    // Manejo de factura
    final AllFact factura = response.result;

    if (factura.cierreActivo!.cierreFinal.estado!.isEmpty) {
      return goInvent(factura.cierreActivo!.cajero.cedulaEmpleado);
    }

     final clienteProv = Provider.of<ClienteProvider>(context, listen: false);


       final responseClienteContado = await ApiHelper.getClienteContado();
       if (responseClienteContado.isSuccess){
           clienteProv.setClientesContado(responseClienteContado.result);
        
       }

       
       final responseClienteCredito = await ApiHelper.getClienteCredito();
       if (responseClienteCredito.isSuccess){
           clienteProv.setClientesCredito(responseClienteCredito.result);
        
       }

    setState(() => _showLoader = false);
    // Inicializar datos locales
    factura.cart = Cart(products: [], numOfItem: 0);
    factura.placa = '';
    factura.kms = 0;
    factura.lasTr = 0;

    if (factura.transacciones.isNotEmpty) {
      factura.transacciones.sort((b, a) => a.transaccion.compareTo(b.transaccion));
      factura.lasTr = factura.transacciones.first.transaccion;
    }



    // Clientes (usando provider clásico)
   
   

    

   if (!mounted) return;
    context.read<CierreActivoProvider>().setFrom(factura.cierreActivo!);
    goHome(factura);
    
  }

 

  /* ================= NAVIGATION ================= */
  void goHome(AllFact factura) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => NewHomeScreen(factura: factura)),
    );
  }

  void goInvent(int cedulaUser) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => InventScreen(cedulaEmpleado: cedulaUser, zona: _selectedZone)),
    );
  }
}
