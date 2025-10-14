import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Models/viatico.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/Viaticos/add_viatico_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class ViaticosScreen extends StatefulWidget {
  const ViaticosScreen({super.key});

  @override
  State<ViaticosScreen> createState() => _ViaticosScreenState();
}

class _ViaticosScreenState extends State<ViaticosScreen> {
  List<Viatico> viaticos = [];
  bool showLoader = false;
  double total = 0;

  @override
  void initState() {
    super.initState();
    _getViaticos();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          title: 'Viaticos',
          elevation: 4,
          shadowColor: kPrimaryColor,
          automaticallyImplyLeading: true,
          foreColor: kNewtextPri,
          backgroundColor: kNewbg,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image.asset(
                  'assets/splash.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        body: showLoader
            ? const LoaderComponent(
                loadingText: 'Cargando...',
                backgroundColor: kNewsurface,
                borderColor: kNewborder,
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kNewbg, Color(0xFF10151C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: viaticos.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('viaticos-list'),
                            itemCount: viaticos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final viatico = viaticos[index];
                              return Dismissible(
                                key: ValueKey<int>(
                                    viatico.idviatico ?? index),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) =>
                                    _confirmDelete(index, viatico),
                                child: _viaticoTile(viatico),
                              );
                            },
                          ),
                  ),
                ),
              ),
        bottomNavigationBar: _totalBar(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kNewgreen,
          foregroundColor: kNewtextPri,
          elevation: 0,
          onPressed: _goAdd,
          icon: const Icon(Icons.add),
          label: const Text(
            'Nuevo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(int index, Viatico viatico) async {
    final bool? shouldDelete = await _showDeleteDialog(viatico);

    if (shouldDelete != true) {
      return false;
    }

    final deleted = await _goDelete(viatico.idviatico ?? 0);
    if (!deleted || !mounted) return false;
    setState(() {
      viaticos.removeAt(index);
      total = viaticos.fold<double>(
        0,
        (previousValue, element) =>
            previousValue + (element.monto ?? 0).toDouble(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viatico eliminado correctamente.')),
    );

    return true;
  }

  Future<bool?> _showDeleteDialog(Viatico viatico) {
    final String montoFormatted = VariosHelpers.formattedToCurrencyValue(
      (viatico.monto ?? 0).toString(),
    );
    final String fecha = viatico.fecha?.split('T').first ?? 'Sin fecha registrada';
    final String cliente = viatico.clienteNombre ?? 'Cliente sin nombre';
    final String placa = (viatico.placa ?? '').isEmpty ? '--' : viatico.placa!;
    final String id = (viatico.idviatico ?? 0).toString();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kNewsurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Eliminar viatico',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: kNewtextPri,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta accion no se puede deshacer. Deseas continuar?',
                style: TextStyle(color: kNewtextSec),
              ),
              const SizedBox(height: 12),
              Text(
                'ID: $id',
                style: const TextStyle(
                  color: kNewtextPri,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cliente: $cliente',
                style: const TextStyle(color: kNewtextMut),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: $fecha',
                style: const TextStyle(color: kNewtextMut),
              ),
              const SizedBox(height: 4),
              Text(
                'Placa: $placa',
                style: const TextStyle(color: kNewtextMut),
              ),
              const SizedBox(height: 4),
              Text(
                'Monto: $montoFormatted',
                style: const TextStyle(color: kNewtextMut),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: kNewtextSec, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNewred,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Eliminar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _viaticoTile(Viatico v) {
    final montoFormatted =
        VariosHelpers.formattedToCurrencyValue((v.monto ?? 0).toString());
    final fecha = v.fecha?.split('T').first ?? 'Sin fecha registrada';
    final cliente = v.clienteNombre ?? 'Sin cliente';
    final placa = v.placa ?? 'Sin placa';
   
    return Container(
      decoration: BoxDecoration(
        color: kNewsurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kNewborder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset('assets/viaticos.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente,
                  style: const TextStyle(
                      color: kNewtextPri,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(fecha,
                    style: const TextStyle(color: kNewtextSec, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Placa: $placa',
                    style: const TextStyle(color: kNewtextSec, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kNewgreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: kNewgreen),
                ),
                child: Text(
                  montoFormatted,
                  style: const TextStyle(
                      color: kNewgreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () => onPrintPressed(v),
                icon: const Icon(Icons.print_outlined, color: kNewtextSec),
                tooltip: 'Imprimir',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dismissBackground() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [kNewred, kNewredPressed],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      );

  Widget _emptyState() => Center(
        key: const ValueKey('viaticos-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: kNewsurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kNewborder),
              ),
              child: const Icon(Icons.directions_car_filled_outlined,
                  color: kNewtextSec, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Aun no hay viaticos',
                style: TextStyle(
                    color: kNewtextPri,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Agrega un nuevo viatico para comenzar.',
                style: TextStyle(color: kNewtextMut, fontSize: 14)),
          ],
        ),
      );

  Widget _totalBar() => Container(
        color: kNewsurface,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total acumulado',
                style: TextStyle(
                    color: kNewtextSec,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            Text(
              VariosHelpers.formattedToCurrencyValue(total.toString()),
              style: const TextStyle(
                  color: kNewtextPri,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Future<void> _getViaticos() async {
    setState(() {
      showLoader = true;
    });

    final cierreActPro =
        Provider.of<CierreActivoProvider>(context, listen: false);

    Response response = await ApiHelper.getViaticosByCierre(
        cierreActPro.cierreFinal!.idcierre ?? 0);

    setState(() {
      showLoader = false;
    });

    if (!response.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(response.message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    setState(() {
      viaticos = response.result;
      total = viaticos.fold<double>(
        0,
        (previousValue, element) =>
            previousValue + (element.monto ?? 0).toDouble(),
      );
    });
  }

  Future<bool> _goDelete(int id) async {
    setState(() {
      showLoader = true;
    });

    Response response =
        await ApiHelper.delete('/api/Viaticos/', id.toString());

    setState(() {
      showLoader = false;
    });

    if (!response.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(response.message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return false;
    }
    return true;
  }

  void _goAdd() async {
    String? result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const AddViaticoScreen()),
    );
    if (result == 'yes') {
      _getViaticos();
    }
  }

  void onPrintPressed(Viatico viatico) {
    //  final printerProv = context.read<PrinterProvider>();
    // final device = printerProv.device;
    // if (device == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Selecciona antes un dispositivo')),
    //   );
    //   return;
    // }

    // // Llamas a tu clase de impresión
    // final testPrint = TestPrint(device: device);  
    // testPrint.printViatico(viatico, widget.factura.cierreActivo!.cajero.nombreCompleto);
  }
}
