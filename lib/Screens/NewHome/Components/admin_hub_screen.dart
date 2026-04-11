import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pantallas reales
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
import 'package:tester/Screens/NewHome/Components/show_process.dart'; // Import ShowProcessMenu

// Provider de transacciones (ajusta el path si lo tienes distinto)
import 'package:tester/Providers/tranascciones_provider.dart';
import 'package:tester/Screens/logIn/nfc_test.dart';

import 'package:tester/helpers/reset_helper.dart'; // <- ojo a la ortografía del archivo en tu proyecto

class AdminCenterPage extends StatefulWidget {
  const AdminCenterPage({super.key});
  @override
  State<AdminCenterPage> createState() => _AdminCenterPageState();
}

class _AdminCenterPageState extends State<AdminCenterPage> {
  _AdminFilter _filter = _AdminFilter.ops;

  @override
  Widget build(BuildContext context) {
    // Colores DARK fijos para asegurar el look aunque el tema global cambie

    const bgGradA = Color(0xFF0B1220);
    const bgGradB = Color(0xFF111827);

    final actions = _filteredActions(context);

    return Scaffold(
      backgroundColor: bgGradB,
      body: CustomScrollView(
        slivers: [
          // // Header más compacto (sin expanded)
          // SliverAppBar(
          //   pinned: true,
          //   elevation: 0,
          //   toolbarHeight: 50,
          //   title: const Text('Centro Administrativo' , style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          //   centerTitle: false,
          //   flexibleSpace: Container(
          //     decoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [Color.fromARGB(255, 23, 49, 103), appbarGradB],
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //       ),
          //     ),
          //   ),
          //   backgroundColor: Colors.transparent,
          // ),

          // Fondo oscuro con gradiente sutil
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgGradA, bgGradB],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Chips de filtro
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final f in _AdminFilter.values) ...[
                          ChoiceChip(
                            checkmarkColor: Colors.white,
                            label: Text(
                              _filterLabel(f),
                              style: TextStyle(
                                color: _filter == f
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: _filter == f
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: _filter == f,
                            backgroundColor: const Color(0xFF1A2130),
                            selectedColor: const Color(0xFF2A3550),
                            onSelected: (_) => setState(() => _filter = f),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          if (f != _AdminFilter.values.last)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),

          // Lista únicamente (sin modo grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            sliver: SliverList.separated(
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ActionTile(action: actions[i]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // Construye y filtra (sin caché global)
  List<_AdminAction> _filteredActions(BuildContext context) {
    final actions = _buildActions(context);
    final base = actions.where((a) => a.filter == _filter).toList();
    base.sort((a, b) => a.title.compareTo(b.title));
    return base;
  }

  String _filterLabel(_AdminFilter f) {
    switch (f) {
      case _AdminFilter.cash:
        return 'Caja y cierres';
      case _AdminFilter.ops:
        return 'Operaciones';
      case _AdminFilter.billing:
        return 'Facturación';
      case _AdminFilter.session:
        return 'Sesión';
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _AdminAction action;

  @override
  Widget build(BuildContext context) {
    final count = _safeCount(context, action.counter);

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: _IconWithBadge(
            icon: action.icon, color: action.color, count: count),
        title: Text(
          action.title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        subtitle: action.subtitle == null
            ? null
            : Text(action.subtitle!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.85)),
        onTap: action.onTap,
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge(
      {required this.icon, required this.color, required this.count});
  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.55),
                color.withValues(alpha: 0.2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

/// ===== Modelo de acción + filtros =====

typedef CounterFn = int Function(BuildContext);

enum _AdminFilter { ops, cash, billing, session }

class _AdminAction {
  const _AdminAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.filter,
    this.subtitle,
    this.counter, // <- contador opcional
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final _AdminFilter filter;
  final CounterFn? counter;
  final VoidCallback onTap;
}

// Seguridad: si el provider no está, devolvemos 0
int _safeCount(BuildContext context, CounterFn? fn) {
  if (fn == null) return 0;
  try {
    return fn(context);
  } catch (_) {
    return 0;
  }
}

// ===== Lista de acciones (con badges) =====

List<_AdminAction> _buildActions(BuildContext context) {
  void open(Widget page, {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => page);
    if (replace) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).push(route);
    }
  }

  Future<void> logout(BuildContext context) async {
    ResetHelper.resetAll(context); // ✅ limpia todo

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // Contadores reales (ejemplo: Transacciones pendientes)
  transPendientes() {
    // Opción A: si el provider expone "unpaid"
    return context.select<TransaccionesProvider, int>(
      (p) => p.items.length,
    );

    // Opción B: si expones items y flags:
    // return context.select<TransaccionesProvider, int>(
    //   (p) => p.items.where((t) => t.isUnpaid && !t.isFacturada).length,
    // );
  }

  return [
    // Caja y cierres
    _AdminAction(
      title: 'Depósitos',
      subtitle: 'Registra y controla depósitos',
      icon: Icons.savings_outlined,
      color: const Color(0xFF22C55E),
      filter: _AdminFilter.cash,
      onTap: () => open(const DepositosScreen()),
    ),
    _AdminAction(
      title: 'Cierre Datáfonos',
      subtitle: 'Conciliación POS',
      icon: Icons.point_of_sale_outlined,
      color: const Color(0xFF6366F1),
      filter: _AdminFilter.cash,
      onTap: () => open(const CierreDatafonosScreen()),
    ),
    _AdminAction(
      title: 'CashBacks',
      subtitle: 'Devoluciones a clientes',
      icon: Icons.cached_rounded,
      color: const Color(0xFF06B6D4),
      filter: _AdminFilter.cash,
      onTap: () => open(const CashbarksScreen()),
    ),
    _AdminAction(
      title: 'Viáticos',
      subtitle: 'Gastos operativos',
      icon: Icons.local_taxi_outlined,
      color: const Color(0xFFF59E0B),
      filter: _AdminFilter.cash,
      onTap: () => open(const ViaticosScreen()),
    ),
    _AdminAction(
      title: 'Resumen de Cierre',
      subtitle: 'Totales del turno',
      icon: Icons.fact_check_outlined,
      color: const Color(0xFF38BDF8),
      filter: _AdminFilter.cash,
      onTap: () => open(const ResumenCierre()),
    ),

    // Operaciones
    _AdminAction(
      title: 'Peddlers',
      subtitle: 'Despachos a peddlers',
      icon: Icons.fire_truck,
      color: const Color(0xFFF43F5E),
      filter: _AdminFilter.ops,
      onTap: () => open(const PeddlersScreen()),
    ),
    _AdminAction(
      title: 'Procesar Surtidor',
      subtitle: 'Gestionar dispensadores',
      icon: Icons.ev_station, // Mismo icono
      color: const Color(0xFF2196F3), // Mismo azul del FAB
      filter: _AdminFilter.ops,
      onTap: () => open(const ShowProcessMenu()),
    ),
    _AdminAction(
      title: 'Transacciones',
      subtitle: 'Historial y estado',
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF10B981),
      filter: _AdminFilter.ops,
      counter: (_) => transPendientes(), // <- badge real desde provider
      onTap: () => open(const TransaccionesScreen()),
    ),
    _AdminAction(
      title: 'Transferencias',
      subtitle: 'Pagos via transferencia',
      icon: Icons.transform_outlined,
      color: const Color(0xFF8B5CF6),
      filter: _AdminFilter.ops,
      onTap: () => open(const TransferenciasScreen()),
    ),
    _AdminAction(
      title: 'Sinpes',
      subtitle: 'Pagos y comprobantes',
      icon: Icons.account_balance_outlined,
      color: const Color(0xFF60A5FA),
      filter: _AdminFilter.ops,
      onTap: () => open(const SinpesScreen()),
    ),

    // Facturación
    _AdminAction(
      title: 'Facturas Contado',
      subtitle: 'Emisión inmediata',
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFFF97316),
      filter: _AdminFilter.billing,
      onTap: () => open(const FacturasScreen(tipo: 'Contado')),
    ),
    _AdminAction(
      title: 'Facturas Crédito',
      subtitle: 'Cuentas por cobrar',
      icon: Icons.receipt_outlined,
      color: const Color(0xFF60A5FA),
      filter: _AdminFilter.billing,
      onTap: () => open(const FacturasScreen(tipo: 'Credito')),
    ),

    // Sesión
    _AdminAction(
      title: 'NFC',
      subtitle: 'Config Nfc Tags',
      icon: Icons.wifi_tethering_outlined,
      color: const Color(0xFFEF4444),
      filter: _AdminFilter.session,
      onTap: () => open(const NfcTestPage()),
    ),

    _AdminAction(
      title: 'Cerrar sesión',
      subtitle: 'Volver a iniciar',
      icon: Icons.logout_rounded,
      color: const Color(0xFFEF4444),
      filter: _AdminFilter.session,
      onTap: () => logout(context),
    ),
  ];
}
