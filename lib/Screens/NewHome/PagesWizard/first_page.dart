import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';
import 'package:tester/Screens/NewHome/PagesWizard/faces_list_page.dart';
import 'package:tester/Providers/dispatch_control.dart';
import 'package:tester/constans.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  bool _isVisible(DispatchControl d) {
    // El card se muestra desde authorizing en adelante.
    return d.stage == DispatchStage.authorizing ||
        d.stage == DispatchStage.authorized ||
        d.stage == DispatchStage.dispatching ||
        d.stage == DispatchStage.unpaid ||
        d.canRetry;
  }

  bool _canDelete(DispatchControl d) {
    // Permitir swipe solo cuando ya no interfiere con la operación
    return d.stage == DispatchStage.readyToAuthorize || d.canRetry;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<DespachosProvider>(context);
    final all = despachosProv.despachos;
    final despachos = all.where(_isVisible).toList();

    // FAB normal = 56px alto. Le sumamos margen y el safe area inferior.
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
                      // ← aquí reservamos espacio para el FAB
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
                            final despachosProv =
                                Provider.of<DespachosProvider>(ctx,
                                    listen: false);
                            despachosProv.removeDispatch(d);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Despacho eliminado')),
                            );
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
          onPressed: () => _startNewFlow(context), // _startNewFlow(context),
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
    final map = ctx.read<MapProvider>();
    final despachosProv = Provider.of<DespachosProvider>(ctx, listen: false);
    final dispatch = DispatchControl(despachosProv,
        resolveDispenser: map.positionIndexForNozzle)
      ..id = DateTime.now().millisecondsSinceEpoch.toString();

    despachosProv.addDispatch(dispatch);

    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => FacesListPage(dispatchId: dispatch.id!),
      ),
    );

    if (dispatch.id != null) {
      final keepStages = {
        DispatchStage.authorizing,
        DispatchStage.authorized,
        DispatchStage.dispatching,
        DispatchStage.completed,
        DispatchStage.unpaid,
      };

      if (!keepStages.contains(dispatch.stage)) {
        despachosProv.removeById(dispatch.id!);
      }
    }
  }

  Future<void> _startMockFlow(BuildContext ctx) async {
    final map = ctx.read<MapProvider>();
    final despachosProv = Provider.of<DespachosProvider>(ctx, listen: false);
    final dispatch = DispatchControl(despachosProv,
        resolveDispenser: map.positionIndexForNozzle)
      ..id = DateTime.now().millisecondsSinceEpoch.toString();

    despachosProv.addDispatch(dispatch);
    dispatch.mockUnpaidState();
  }
}
