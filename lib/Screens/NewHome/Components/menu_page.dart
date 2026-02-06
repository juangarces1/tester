import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/experimental/alt_despachos_provider.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';
import 'package:tester/Providers/dispatch_control.dart' show DispatchStage;
import 'package:tester/Providers/despachos_provider.dart' show HoseStatus;
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';
import 'package:tester/Screens/NewHome/PagesWizard/faces_list_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  bool _canDelete(AltDispatchControl d) {
    return d.hoseStatusEnum != HoseStatus.authorized;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<AltDespachosProvider>(context);
    final despachos = despachosProv.despachos;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        appBar: AppBar(
          title: const Text(
            'Despachos Activos',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.black,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.deepPurpleAccent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _startNewFlow(context),
                  splashColor: Colors.white24,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: despachos.isEmpty
            ? const Center(
                child: Text(
                  'No hay despachos activos',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: despachos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final d = despachos[i];
                  return Dismissible(
                    key: ValueKey(d.id),
                    direction: _canDelete(d)
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    confirmDismiss: (direction) async {
                      if (!_canDelete(d)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No se puede eliminar un despacho autorizado')),
                        );
                        return false;
                      }
                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar despacho'),
                          content: const Text(
                              '¿Seguro que deseas eliminar este despacho?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      return confirmed == true;
                    },
                    onDismissed: (_) {
                      despachosProv.removeDispatch(d);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Despacho eliminado')),
                      );
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Handle tap si necesitas abrir o ver detalles
                      },
                      child: DispatchCard(d: d),
                    ),
                  );
                },
              ),
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
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => FacesListPage(dispatchId: dispatch.id),
      ),
    );
  }
}
