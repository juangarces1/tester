import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/loader_component.dart';
import 'package:tester/ConsoleModels/console_user.dart';

import 'package:tester/Models/FuelRed/all_fact.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/usuario_provider.dart';

import 'package:tester/Screens/NewHome/new_home_screen.dart';
import 'package:tester/Screens/logIn/invent_screen.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/card_auth_api.dart';
import 'package:tester/sizeconfig.dart';

/* ====================== LOGIN NFC (mezcla de ambas) ====================== */
class LoginNfcScreen extends StatefulWidget {
  const LoginNfcScreen({super.key});

  @override
  State<LoginNfcScreen> createState() => _LoginNfcScreenState();
}

class _LoginNfcScreenState extends State<LoginNfcScreen> {
  bool _showLoader = false;

  // NFC
  bool _scanning = false;
  String? _lastUid;

  // Zona (igual que en tu LoginScreen)
  int _selectedZone = 0;

  String _fmtUid(String? raw) =>
      (raw ?? '').replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();

  /* ===================== FLUJO PRINCIPAL: ESCANEAR + LOGIN ===================== */
  Future<void> _scanAndLogin() async {
    if (_scanning || _showLoader) return;

    // 1) Validación zona como en tu LoginScreen
    if (_selectedZone == 0) {
      Fluttertoast.showToast(msg: 'Selecciona la Zona');
      return;
    }

    setState(() {
      _scanning = true;
      _showLoader = true;
    });

    try {
      // 2) Leer NFC
      final ava = await FlutterNfcKit.nfcAvailability;
      if (ava != NFCAvailability.available) {
        Fluttertoast.showToast(msg: 'NFC no disponible: $ava');
        setState(() {
          _scanning = false;
          _showLoader = false;
        });
        return;
      }

      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        androidPlatformSound: true,
        iosMultipleTagMessage: 'Detecté varias tarjetas, separa una sola.',
      );
      final uid = _fmtUid(tag.id);
      _lastUid = uid;
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
      await FlutterNfcKit.finish();

      if (uid.isEmpty) {
        Fluttertoast.showToast(msg: 'Tag leído sin UID');
        setState(() {
          _scanning = false;
          _showLoader = false;
        });
        return;
      }

      // 3) Backend CardAuth: resolver empleado por tarjeta
      final api = CardAuthApi();

      // Si tu CardAuthApi.loginByCard devuelve Map { empleado: {...} }
      final userfuelRed = await api.loginByCard(uid: uid);

      final int cedula = userfuelRed.cedulaEmpleado;

      // (opcional) Guardar el empleado “Fuel” en tu provider
      // Si tu UsuarioProvider ya tiene signInFuel(Empleado):

      if (mounted == false) return;

      final usuarioProv = context.read<UsuarioProvider>();
      // Descomenta si tienes ese método:
      await usuarioProv.signInFuel(userfuelRed);

      // 4) Continuar tu flujo normal con ApiHelper.getLogInNuevo(zona, cedula)
      final response = await ApiHelper.getLogInNuevo(_selectedZone, cedula);

      if (!response.isSuccess) {
        setState(() {
          _scanning = false;
          _showLoader = false;
        });
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

      // 5) Login de consola (como en tu LoginScreen actual, de momento mock)
      const ConsoleUser mockUser = ConsoleUser(
        identifier: 'B32809EE018B2811',
        email: 'sebastian.garces23@gmail.com',
        rol: UserRole.operador,
        verificado: true,
      );
      await usuarioProv.signIn(mockUser);
      if (!mounted) return;
      // 6) Cargar mapa
      final mapProv = context.read<MapProvider>();
      try {
        await mapProv.loadMap();
      } catch (e) {
        setState(() {
          _scanning = false;
          _showLoader = false;
        });
        Fluttertoast.showToast(
          msg: 'No se pudo cargar la configuración de la estación: $e',
        );
        return;
      }

      // 7) Manejo de facturación como en tu LoginScreen
      final AllFact factura = response.result;

      if (factura.cierreActivo!.cierreFinal.estado!.isEmpty) {
        setState(() {
          _scanning = false;
          _showLoader = false;
        });
        return goInvent(factura.cierreActivo!.cajero.cedulaEmpleado);
      }

      if (!mounted) return;

      final clienteProv = context.read<ClienteProvider>();
      await clienteProv.loadClientesBy(ClienteTipo.contado);
      await clienteProv.loadClientesBy(ClienteTipo.credito);

      if (!mounted) return;
      context.read<CierreActivoProvider>().setFrom(factura.cierreActivo!);

      setState(() {
        _scanning = false;
        _showLoader = false;
      });

      goHome();
    } catch (e) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
      setState(() {
        _scanning = false;
        _showLoader = false;
      });
      Fluttertoast.showToast(msg: 'Error login por tarjeta: $e');
    }
  }

  /* ===================== NAV ===================== */
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

  /* ===================== UI ===================== */
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final uid = _lastUid ?? '—';

    return Scaffold(
      backgroundColor: kContrateFondoOscuro,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/BgLogin.png', fit: BoxFit.cover),
          ),
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
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                const _Header(),
                                const SizedBox(height: 24),

                                _ZoneSelector(
                                  selected: _selectedZone,
                                  onSelect: (z) =>
                                      setState(() => _selectedZone = z),
                                ),

                                const SizedBox(height: 24),

                                // --- Bloque NFC (reemplaza la cédula manual) ---
                                Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.nfc),
                                    title: const Text('Acerca tu tarjeta'),
                                    subtitle: Text(
                                      uid,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    trailing: _scanning
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.play_arrow),
                                            onPressed: _scanAndLogin,
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // DefaultButton(
                                //   text: 'ENTRAR CON TARJETA',
                                //   press: _showLoader ? null : _scanAndLogin,
                                //   color: kPrimaryColor,
                                //   gradient: kPrimaryGradientColor,
                                // ),
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
}

/* ================= WIDGETS AUX (igual que tu LoginScreen) ================= */
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
