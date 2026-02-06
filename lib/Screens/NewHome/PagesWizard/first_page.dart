import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';
import 'package:tester/Screens/NewHome/PagesWizard/faces_list_page.dart';
import 'package:tester/Providers/experimental/alt_despachos_provider.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';
import 'package:tester/Providers/dispatch_control.dart' show DispatchStage;
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

  bool _isVisible(AltDispatchControl d) {
    // El card se muestra desde authorizing en adelante.
    return d.stage == DispatchStage.authorizing ||
        d.stage == DispatchStage.authorized ||
        d.stage == DispatchStage.dispatching ||
        d.stage == DispatchStage.unpaid ||
        d.canRetry;
  }

  bool _canDelete(AltDispatchControl d) {
    // Permitir swipe solo cuando ya no interfiere con la operación
    return d.stage == DispatchStage.readyToAuthorize || d.canRetry;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<AltDespachosProvider>(context);
    final all = despachosProv.despachos;
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
                            final prov = Provider.of<AltDespachosProvider>(ctx,
                                listen: false);
                            prov.removeDispatch(d);
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
    final despachosProv = Provider.of<AltDespachosProvider>(ctx, listen: false);
    final dispatchId = DateTime.now().millisecondsSinceEpoch.toString();

    final dispatch = AltDispatchControl(
      id: dispatchId,
      onComplete: () {
        // Remover el despacho cuando se marque como completado
        despachosProv.removeById(dispatchId);
      },
    );

    despachosProv.addDispatch(dispatch);

    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => FacesListPage(dispatchId: dispatch.id),
      ),
    );

    // Stages que mantienen el despacho vivo al volver del wizard
    final keepStages = {
      DispatchStage
          .readyToAuthorize, // ← El usuario configuró todo pero aún no autorizó
      DispatchStage.authorizing,
      DispatchStage.authorized,
      DispatchStage.dispatching,
      DispatchStage.completed,
      DispatchStage.unpaid,
    };

    debugPrint(
        '[FirstPage] Wizard returned. Dispatch stage: ${dispatch.stage}');
    debugPrint('[FirstPage] Keep stages: $keepStages');
    debugPrint('[FirstPage] Will keep: ${keepStages.contains(dispatch.stage)}');

    if (!keepStages.contains(dispatch.stage)) {
      debugPrint('[FirstPage] REMOVING dispatch ${dispatch.id}');
      despachosProv.removeById(dispatch.id);
    }
  }
}
