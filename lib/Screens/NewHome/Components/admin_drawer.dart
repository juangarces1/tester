import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/CashBacks/cashbacks_screen.dart';
import 'package:tester/Screens/CierreDatafonos/cierre_datafonos_screen.dart';
import 'package:tester/Screens/Depositos/depositos_screen.dart';
import 'package:tester/Screens/Facturas/facturas_screen.dart';
import 'package:tester/Screens/Peddlers/peddlers_screen.dart';
import 'package:tester/Screens/ResumenCierre/resumen_cierre.dart';
import 'package:tester/Screens/Sinpes/sinpes_screen.dart';
import 'package:tester/Screens/Transacciones/transacciones_screen.dart';
import 'package:tester/Screens/Transfers/transferencias_screen.dart';
import 'package:tester/Screens/Viaticos/viaticos_screen.dart';
import 'package:tester/Screens/logIn/login_screen.dart';
import 'package:tester/Screens/test_print/print_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, });

  

  @override
  Widget build(BuildContext context) {

    final usuario = context.read<CierreActivoProvider>().usuario;
    
    
    final nameParts = [
      usuario?.nombre ?? '',
      usuario?.apellido1 ?? '',
    ].where((part) => part.isNotEmpty).toList();
    final userName = nameParts.isEmpty ? 'Usuario' : nameParts.join(' ');

    final sections = _buildSections(context);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerHeader(userName: userName),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _DrawerSection(section: sections[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_AdminDrawerSection> _buildSections(BuildContext context) {
    return [
      _AdminDrawerSection(
        title: 'Caja y cierres',
        icon: Icons.account_balance_wallet_outlined,
        items: [
          
          _AdminMenuItem(
            title: 'Depositos',
            asset: 'assets/deposito.png',
            accent: const Color(0xFF34D399),
            onTap: () => _openPage(context, const DepositosScreen()),
          ),
          _AdminMenuItem(
            title: 'Cierre Datafonos',
            asset: 'assets/data.png',
            accent: const Color(0xFF818CF8),
            onTap: () => _openPage(context, const CierreDatafonosScreen()),
          ),
         _AdminMenuItem(
            title: 'CashBacks',
            asset: 'assets/cbs.png',
            accent: const Color(0xFF38BDF8),
            onTap: () => _openPage(context, const CashbarksScreen()),
          ),
          _AdminMenuItem(
            title: 'Viaticos',
            asset: 'assets/viaticos.png',
            accent: const Color(0xFFFBBF24),
            onTap: () => _openPage(context, const ViaticosScreen()),
          ),
           _AdminMenuItem(
            title: 'Resumen Cierre',
            asset: 'assets/cierre1.png',
            accent: const Color(0xFF7DD3FC),
            onTap: () => _openPage(
              context,
              const ResumenCierre(),
            ),
          ),
        ],
      ),
      _AdminDrawerSection(
        title: 'Operaciones',
        icon: Icons.dashboard_customize_outlined,
        items: [
          _AdminMenuItem(
            title: 'Peddlers',
            asset: 'assets/peddler.png',
            accent: const Color(0xFFFB7185),
            onTap: () => _openPage(
              context,
              const PeddlersScreen(),
            ),
          ),
          _AdminMenuItem(
            title: 'Transacciones',
            asset: 'assets/NoTr.png',
            accent: const Color(0xFF4ADE80),
            onTap: () => _openPage(context, const TransaccionesScreen()),
          ),
          _AdminMenuItem(
            title: 'Transferencias',
            asset: 'assets/tr9.png',
            accent: const Color(0xFFA855F7),
            onTap: () => _openPage(
              context,
              const TransferenciasScreen(),
            ),
          ),
          _AdminMenuItem(
            title: 'Sinpes',
            asset: 'assets/sinpe.png',
            accent: Colors.white,
            onTap: () => _openPage(
              context,
              const SinpesScreen(),
            ),
          ),
        ],
      ),
      _AdminDrawerSection(
        title: 'Facturación',
        icon: Icons.receipt_long_outlined,
        items: [
          _AdminMenuItem(
            title: 'Facturas Contado',
            asset: 'assets/factura.png',
            accent: const Color(0xFFF97316),
            onTap: () => _openPage(
              context,
              const FacturasScreen(tipo: 'Contado'),
            ),
          ),
          _AdminMenuItem(
            title: 'Facturas Crédito',
            asset: 'assets/factura.png',
            accent: const Color(0xFF60A5FA),
            onTap: () => _openPage(
              context,
              const FacturasScreen(tipo: 'Credito'),
            ),
          ),
        ],
      ),
      _AdminDrawerSection(
        title: 'Herramientas',
        icon: Icons.settings_outlined,
        items: [
          _AdminMenuItem(
            title: 'Config Impresora',
            asset: 'assets/printer.png',
            accent: const Color(0xFF67E8F9),
            onTap: () => _openPage(context, const PrinterScreen()),
          ),
         
        ],
      ),
      _AdminDrawerSection(
        title: 'Sesión',
        icon: Icons.logout,
        items: [
          _AdminMenuItem(
            title: 'Cerrar Sesión',
            asset: 'assets/salir.png',
            accent: const Color(0xFFEF4444),
            onTap: () =>
                _openPage(context, const LoginScreen(), replace: true),
          ),
        ],
      ),
    ];
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fuel Red Mobile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.section});

  final _AdminDrawerSection section;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey<String>('drawer-${section.title}'),
      maintainState: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      collapsedBackgroundColor: Colors.white.withValues(alpha: 0.02),
      iconColor: Colors.white.withValues(alpha: 0.8),
      collapsedIconColor: Colors.white.withValues(alpha: 0.6),
      leading: Icon(section.icon, color: Colors.white.withValues(alpha: 0.8)),
      title: Text(
        section.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: section.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: _DrawerItemCard(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _DrawerItemCard extends StatelessWidget {
  const _DrawerItemCard({required this.item});

  final _AdminMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: item.accent.withValues(alpha: 0.26)),
            boxShadow: [
              BoxShadow(
                color: item.accent.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      item.accent.withValues(alpha: 0.55),
                      item.accent.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(item.asset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDrawerSection {
  const _AdminDrawerSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_AdminMenuItem> items;
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.title,
    required this.asset,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String asset;
  final Color accent;
  final VoidCallback onTap;
}

void _openPage(BuildContext context, Widget page, {bool replace = false}) {
  Navigator.of(context).pop();
  Future.microtask(() {
    final route = MaterialPageRoute(builder: (_) => page);
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  });
}
