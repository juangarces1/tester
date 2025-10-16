import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/NewHome/Components/admin_drawer.dart';
import 'package:tester/Screens/NewHome/Components/facturacion_page.dart';
import 'package:tester/Screens/NewHome/Components/first_page.dart';


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
      const FirstPage(),
      // DispensersDashboard(
      //   key: const PageStorageKey('dispensers'),
      //   isActive: _selectedIndex == 1,
      // ),
      const FacturacionPage(),
    ];
    return SafeArea(
      child: Scaffold(
        appBar: _buildCustomAppBar(),
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: kNewborder,
                color: Colors.white,
                tabs: const [
                  GButton(
                    icon: Icons.ev_station,
                    text: 'Despachos',
                  ),
                  // GButton(
                  //   icon: Icons.ev_station,
                  //   text: 'Estado',
                  // ),
                  GButton(
                    icon: Icons.receipt_long,
                    text: 'Facturación',
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
        drawer: const AdminDrawer(),
      ),
    );
  }

 PreferredSizeWidget _buildCustomAppBar() {
  final cierreActivo = context.read<CierreActivoProvider>();
  final usuario = cierreActivo.usuario;
  final cierreFinal = cierreActivo.cierreFinal;
  return AppBar(
    // Deja que el AppBar gestione el leading (hamburguesa del Drawer)
    automaticallyImplyLeading: false,
    centerTitle: false,

    // Un pelín más alto para que se vea “centrado” y con aire
    toolbarHeight: 64,

    // Asegura espacio después del ícono del drawer para que no se “pegue”
    leadingWidth: 56,
    titleSpacing: 8,

    // Colores de íconos del AppBar (hamburguesa, back, etc.)
    iconTheme: const IconThemeData(color: kContrateFondoOscuro),

    // Fondo transparente porque lo pintamos con el gradient en flexibleSpace
    backgroundColor: Colors.transparent,
    elevation: 3,
    shadowColor: Colors.white,
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
        const SizedBox(width: 10,),
        Container(
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
          text: 'Cierre: ${cierreFinal!.idcierre.toString()}',  // <-- tu subtítulo aquí
          style: const TextStyle(
            color: kContrateFondoOscuro,
            fontWeight: FontWeight.w600,
            fontSize: 13,   // más pequeño
            height: 1.2,    // un pelín más de altura para separar
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
            width: 30, height: 30, fit: BoxFit.cover,
          ),
        ),
      ),
    ],
  );
}



}
