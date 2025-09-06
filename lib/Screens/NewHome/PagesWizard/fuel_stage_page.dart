// lib/Screens/Dispatch/fuel_step_page.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Screens/NewHome/Components/fuel_grid.dart';
import 'package:tester/Screens/NewHome/PagesWizard/hose_step_page.dart';

class FuelStepPage extends StatelessWidget {
  final String dispatchId;
  const FuelStepPage({required this.dispatchId, super.key});

  @override
  Widget build(BuildContext context) {
    final despachosProv = context.read<DespachosProvider>();
    final mapProv       = context.watch<MapProvider>();

    final dispatch = despachosProv.getById(dispatchId)!;
    final map      = mapProv.stationMap;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('1. Elige Combustible',
            style: TextStyle(color: Colors.white)),
      ),
      body: map == null
          ? _mapLoader(context, mapProv)           // ← aquí blindamos
          : FuelTypeGrid(
              stationMap: map,
              onSelected: (fuel) {
                dispatch.fuel = fuel;
                despachosProv.refresh();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HoseStepPage(dispatchId: dispatch.id!),
                  ),
                );
              },
            ),
    );
  }

  /// Loader con retry y toast de error (solo una vez).
  Widget _mapLoader(BuildContext ctx, MapProvider prov) {
    // Lanza el toast SOLAMENTE si ya intentaste cargar y falló
    if (prov.isError && !prov.toastShown) {
      if (prov.isError && !prov.toastShown) {
          prov.markToastShown();         // ✔️ actualiza el flag
          // … resto del código para el toast
        }                    // flag interno
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Fluttertoast.showToast(
          msg: 'No se pudo cargar el mapa 😖',
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 3,
        );
      });
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: prov.loadMap,        // tu método de carga
          ),
        ],
      ),
    );
  }
}
