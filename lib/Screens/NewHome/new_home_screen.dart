import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/NewHome/Components/admin_drawer.dart';
import 'package:tester/Screens/NewHome/Components/facturacion_page.dart';
import 'package:tester/Screens/NewHome/Components/first_page.dart';
import 'package:tester/ViewModels/beache_models.dart';

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
      DispensersDashboard(
        key: const PageStorageKey('dispensers'),
        isActive: _selectedIndex == 1,
      ),
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
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 1, 18, 59),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 28,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.grey[900]!,
                color: Colors.white,
                tabs: const [
                  GButton(
                    icon: Icons.ev_station,
                    text: 'Inicio',
                  ),
                  GButton(
                    icon: Icons.ev_station,
                    text: 'Estado',
                  ),
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
    final usuario = context.read<CierreActivoProvider>().usuario;

    return PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 0, bottom: 0),
          decoration: const BoxDecoration(
            gradient: kGradientHome,
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fuel Red Mobile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    Text(
                      'Usuario: ${usuario!.nombre} ${usuario.apellido1}',
                      style: baseStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
