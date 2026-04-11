import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';
import 'package:tester/Screens/NewHome/PagesWizard/faces_list_page.dart';
import 'package:tester/Providers/experimental/active_dispatch_manager.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';

import 'package:tester/constans.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  void initState() {
    super.initState();
    // Al iniciar FirstPage, ya no forzamos un intervalo aquí.
    // AltDespachosProvider gestionará si arranca (1.5s) o se apaga según haya despachos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Simplemente nos aseguramos de que el motor esté en el estado correcto
      // context.read<AltDespachosProvider>().refresh(); // Podríamos disparar un refresh si quisiéramos
    });
  }

  @override
  void dispose() {
    // Es buena práctica detenerlo si salimos totalmente de esta vista,
    // aunque en este caso FirstPage suele ser persistente.
    // context.read<MapProvider>().stopGlobalPolling();
    super.dispose();
  }

  bool _isVisible(DispatchSession d) {
    return !d.isCompleted;
  }

  bool _canDelete(DispatchSession d) {
    return d.canRetryOrDiscard;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<ActiveDispatchManager>(context);
    final all = despachosProv.activeSessions;
    final despachos = all.where(_isVisible).toList();

    const fabHeight = 56.0;
    const fabMargin = 24.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final extraBottom = fabHeight + fabMargin + bottomInset;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        body: Stack(
          children: [
            Positioned.fill(
              child: despachos.isEmpty
                  ? const Center(
                      child: Text('No hay despachos activos',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(8, 20, 8, extraBottom),
                      itemCount: despachos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (ctx, i) {
                        final d = despachos[i];
                        return Dismissible(
                          key: ObjectKey(d),
                          direction: _canDelete(d)
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Eliminar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            if (!_canDelete(d)) return false;
                            return await showDialog<bool>(
                                  context: ctx,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar despacho'),
                                    content: const Text(
                                        '¿Seguro que quieres eliminar este despacho?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(_, false),
                                          child: const Text('Cancelar')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(_, true),
                                          child: const Text('Eliminar')),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            final prov = Provider.of<ActiveDispatchManager>(ctx,
                                listen: false);
                            prov.finishSession(d.id);
                          },
                          child: GestureDetector(
                            onTap: () {},
                            child: DispatchCard(d: d),
                          ),
                        );
                      },
                    ),
            ),
            Positioned(
              left: 3,
              bottom: 3,
              child: _buildDispatchCounter(all.length),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kBlueColorLogo,
          onPressed: () => _startNewFlow(context),
          child: const Icon(Icons.add, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildDispatchCounter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Despachos: ${total.toString()}',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _startNewFlow(BuildContext ctx) async {
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => const FacesListPage(),
      ),
    );
  }
}
