import 'dart:ui';

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
  final TextEditingController _passwordController = TextEditingController();


  bool _passwordShow = false;
  bool _showLoader = false;
  LogInEstado login = LogInEstado();
  int _selectedZone = 0;

  static Widget _buildAuroraBlob(Color color) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 200,
            spreadRadius: 40,
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
          // BG image
          // Positioned.fill(
          //   child: Image.asset(
          //     'assets/BgLogin.png',
          //     fit: BoxFit.cover,
          //   ),
          // ),
           const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF060C18), Color(0xFF131E32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _buildAuroraBlob(kPrimaryColor),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _buildAuroraBlob(const Color(0x552563EB)),
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
                                // const SizedBox(height: 12),
                               //  const _Header(),
                               //  const SizedBox(height: 10),

                                // _ZoneSelector(
                                //   selected: _selectedZone,
                                //   onSelect: (z) => setState(() => _selectedZone = z),
                                // ),

                                // const SizedBox(height: 24),

                                // // Correo (opcional por ahora)
                                // // _buildEmail(),
                                // // const SizedBox(height: 16),

                                // _buildPassword(),
                                // const SizedBox(height: 24),

                                // DefaultButton(
                                //   text:  'ENTRAR',
                                //   press: _showLoader ? null : _login,
                                //   color: kPrimaryColor,
                                //   gradient: kPrimaryGradientColor,
                                // ),

                                // const SizedBox(height: 24),
                                //    DefaultButton(
                                //   text: 'NFC',
                                //   press: _showLoader ? null : _goNNfc,
                                //   color: kPrimaryColor,
                                //   gradient: kPrimaryGradientColor,
                                // ),

                                 Expanded(child: _buildFormCard(context)),
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

  Widget _buildFormCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 42,
                offset: const Offset(0, 32),
                spreadRadius: -20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

                const _Header(),
              const SizedBox(height: 32),

              // Row(
              //   children: [
              //     Container(
              //       height: 48,
              //       width: 48,
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(16),
              //         gradient: const LinearGradient(
              //           colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              //           begin: Alignment.topLeft,
              //           end: Alignment.bottomRight,
              //         ),
              //       ),
              //       child: const Icon(
              //         Icons.person_outline,
              //         color: Colors.white,
              //       ),
              //     ),
              //     const SizedBox(width: 16),
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Bienvenido',
              //           style:
              //               textTheme.titleMedium?.copyWith(
              //                 color: Colors.white70,
              //                 letterSpacing: 0.2,
              //               ) ??
              //               const TextStyle(
              //                 color: Colors.white70,
              //                 fontSize: 14,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //         ),
              //         const SizedBox(height: 4),
              //         Text(
              //           'Inicia Sesión',
              //           style:
              //               textTheme.titleLarge?.copyWith(
              //                 color: Colors.white,
              //                 fontWeight: FontWeight.w700,
              //               ) ??
              //               const TextStyle(
              //                 color: Colors.white,
              //                 fontSize: 20,
              //                 fontWeight: FontWeight.w700,
              //               ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),

               _ZoneSelector(
                                  selected: _selectedZone,
                                  onSelect: (z) => setState(() => _selectedZone = z),
                                ),

              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                obscureText: !_passwordShow,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Cedula',
                  hintText: 'Digita tu numero de cedula',
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: Colors.white70,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordShow
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordShow = !_passwordShow;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: _passwordShow ? _passwordError : null,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.38),
                    ),
                  ),
                ),
                onChanged: (value) {
                  _password = value;
                  if (_passwordShow) {
                    setState(() {
                      _passwordShow = false;
                    });
                  }
                },
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  onPressed: _login,
                  child: const Text('Ingresar'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'El acceso esta restringido a personal autorizado. Contacta a sistemas para recuperar tus credenciales.',
                style:
                    textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                      height: 1.4,
                    ) ??
                    const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
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
                color: Colors.blueAccent.withOpacity(0.6),
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
            color:Colors.white,
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
