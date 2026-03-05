import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/empleado_info_card.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/NewHome/Components/admin_hub_screen.dart';
// import 'package:tester/Screens/NewHome/Components/facturacion_page.dart';
import 'package:tester/Screens/NewHome/Components/facturacion_page_v2.dart';
// import 'package:tester/Screens/NewHome/PagesWizard/first_page.dart';
import 'package:tester/Screens/NewHome/PagesWizard/first_page_v2.dart';
import 'package:tester/fuelred/fuelred_page.dart';

import '../../constans.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({
    super.key,
  });

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  double aspectRetio = 1.02;
  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextStyle baseStyle = const TextStyle(
    fontStyle: FontStyle.normal,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FirstPageV2(), // Cambio a V2 con Action Hub
      const FuelRedPage(), // FuelRed P4S — órdenes de flotillas
      const FacturacionPageV2(), // Cambio a V2 (Sin FABs, Con Hub)
      const AdminCenterPage(),
    ];
    return SafeArea(
      child: Scaffold(
        appBar: _buildCustomAppBarV2(),
        key: _scaffoldKey,
        backgroundColor: kColorFondoOscuro,
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: kNewborder,
                color: Colors.white,
                tabs: const [
                  GButton(
                    iconSize: 25,
                    icon: Icons.ev_station,
                    text: 'Desp',
                  ),
                  GButton(
                    iconSize: 25,
                    icon: Icons.local_shipping_rounded,
                    text: 'P4S',
                  ),
                  GButton(
                    iconSize: 25,
                    icon: Icons.receipt_long,
                    text: 'Fact',
                  ),
                  GButton(
                    iconSize: 25,
                    icon: Icons.settings_applications,
                    text: 'Admin',
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
        //  drawer: const AdminDrawer(),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    final cierreActivo = context.read<CierreActivoProvider>();
    final usuario = cierreActivo.usuario;
    final cierreFinal = cierreActivo.cierreFinal;
    return AppBar(
      // Deja que el AppBar gestione el leading (hamburguesa del Drawer)
      automaticallyImplyLeading: true,
      centerTitle: false,

      // Un pelín más alto para que se vea “centrado” y con aire
      toolbarHeight: 56,

      // Asegura espacio después del ícono del drawer para que no se “pegue”
      leadingWidth: 56,
      titleSpacing: 8,

      // Colores de íconos del AppBar (hamburguesa, back, etc.)
      iconTheme: const IconThemeData(color: kContrateFondoOscuro),

      // Fondo transparente porque lo pintamos con el gradient en flexibleSpace
      backgroundColor: Colors.transparent,
      elevation: 3,
      shadowColor: kPrimaryColor,
      // Fondo con gradient y sombra SIN fijar alto
      flexibleSpace: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: kGradientHome,
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor,
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ),

      // Contenido principal del AppBar
      title: Row(
        children: [
          // Avatar/SVG
          const SizedBox(
            width: 10,
          ),
          InkWell(
            onTap: _showEmpleadoModal,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: kContrateFondoOscuro,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                "assets/User Icon.svg",
                // ignore: deprecated_member_use
                color: kTextColorBlack,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nombre — más grande y con elipsis
          Expanded(
            child: Text.rich(
              TextSpan(
                text: usuario?.nombreCompleto ?? '—',
                style: const TextStyle(
                  color: kContrateFondoOscuro,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  height: 1.05, // compacta la primera línea
                ),
                children: [
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text:
                        'Cierre: ${cierreFinal!.idcierre.toString()}', // <-- tu subtítulo aquí
                    style: const TextStyle(
                      color: kContrateFondoOscuro,
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // más pequeño
                      height: 1.2, // un pelín más de altura para separar
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          )
        ],
      ),

      // Actions a la derecha
      actions: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ClipOval(
            child: Image(
              image: AssetImage('assets/splash.png'),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // V2 - APPBAR MODERNO CON GLASSMORPHISM Y DISEÑO 2025
  // ═══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildCustomAppBarV2() {
    final cierreActivo = context.read<CierreActivoProvider>();
    final usuario = cierreActivo.usuario;
    final cierreFinal = cierreActivo.cierreFinal;

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: kGradientHome,
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // ─────────────────────────────────────────────────────────────
                // AVATAR CON GLOW
                // ─────────────────────────────────────────────────────────────
                GestureDetector(
                  onTap: _showEmpleadoModal,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(usuario?.nombreCompleto ?? 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ─────────────────────────────────────────────────────────────
                // NOMBRE + CHIP DE CIERRE
                // ─────────────────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        usuario?.nombreCompleto ?? '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Chip de Cierre
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '#${cierreFinal?.idcierre ?? '—'} • Zona ${cierreFinal?.idzona ?? '—'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────────────────────────────────────────
                // LOGO
                // ─────────────────────────────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/splash.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showEmpleadoModal() {
    final cierreActivo = context.read<CierreActivoProvider>();
    final cajero = cierreActivo.cajero;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: EmpleadoInfoCard(
            empleado: cajero!,
            onTap: () => print('Tapped!'),
            showAttendantId: true,
          ),
        );
      },
    );
  }
}
