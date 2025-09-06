import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/transactions_provider.dart';
import 'package:tester/Screens/NewHome/Components/dispatch_card.dart';

import 'package:tester/Screens/NewHome/PagesWizard/fuel_stage_page.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/helpers/dispatch_simulator.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  bool _isVisible(DispatchControl d) {
    // El card se muestra desde authorizing en adelante.
    return d.stage == DispatchStage.authorizing ||
           d.stage == DispatchStage.authorized  ||
           d.stage == DispatchStage.dispatching ||
           d.stage == DispatchStage.unpaid ||
           d.canRetry;
  }

  bool _canDelete(DispatchControl d) {
    // Permitir swipe solo cuando ya no interfiere con la operación
    return d.stage == DispatchStage.readyToAuthorize ||           
           d.canRetry;
  }

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<DespachosProvider>(context);
    final all = despachosProv.despachos;
    // Filtramos lo visible
    final despachos = all.where(_isVisible).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        appBar: AppBar(
          title: const Text(
            'Despachos Activos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.black,
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.only(right: 12.0),
          //     child: Material(
          //       elevation: 6,
          //       borderRadius: BorderRadius.circular(12),
          //       color: Colors.deepPurpleAccent,
          //       child: InkWell(
          //         borderRadius: BorderRadius.circular(12),
          //         onTap: () => _startNewFlow(context),
          //         splashColor: Colors.white24,
          //         child: const SizedBox(
          //           width: 44,
          //           height: 44,
          //           child: Center(
          //             child: Icon(Icons.add, size: 26, color: Colors.white),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        ),
       
        body: despachos.isEmpty
            ? const Center(
                child: Text('No hay despachos activos',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: despachos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (ctx, i) {
                  final d = despachos[i];
                  return Dismissible(
                    key: ValueKey(d.id ?? d.selectedHose?.hoseKey ?? 'dispatch_$i'),
                    direction: _canDelete(d)
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    confirmDismiss: (direction) async {
                      if (!_canDelete(d)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Solo puedes eliminar despachos completados o sin pagar')),
                        );
                        return false;
                      }
                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar despacho'),
                          content: const Text('¿Seguro que deseas eliminar este despacho?'),
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
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      //padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Aquí podrías abrir un detalle si lo necesitas
                      },
                      child: DispatchCard(d: d),
                    ),
                  );
                },
              ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _startNewMockDispatch(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _startNewMockDispatch(BuildContext ctx) async {
  final despachosProv = Provider.of<DespachosProvider>(ctx, listen: false);
  final txProv        = Provider.of<TransactionsProvider>(ctx, listen: false);

  final dispatch = DispatchControl(despachosProv);
  dispatch.seedMockAndRegister(
    despachos: despachosProv,
    transactions: txProv,
    useAmount: true,       // o false si prefieres volumen
    amount: 280800,         // si useAmount=true
    liters: 360.0,          // si useAmount=false
    pricePerL: 780.0,
    product: 95,
    nozzle: 1,
    type: InvoiceType.credito,   
  );

  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(content: Text('Despacho mock listo (unpaid)')),
  );
}

  Future<void> _startNewFlow(BuildContext ctx) async {
    final despachosProv = Provider.of<DespachosProvider>(ctx, listen: false);
    final dispatch = DispatchControl(despachosProv)
      ..id = DateTime.now().millisecondsSinceEpoch.toString();
    despachosProv.addDispatch(dispatch);

    // Inicia el wizard de selección (fuel → hose → preset/tanque), el card
    // aparecerá cuando el wizard dispare la autorización (authorizing).
    await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => FuelStepPage(dispatchId: dispatch.id!)),
    );
  }
}
