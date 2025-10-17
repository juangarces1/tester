import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/CierreDatafonos/add_datafono_screen.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class CierreDatafonosScreen extends StatefulWidget {
  

  // ignore: use_key_in_widget_constructors
  const CierreDatafonosScreen();

  @override
  State<CierreDatafonosScreen> createState() => _CierreDatafonosScreenState();
}

class _CierreDatafonosScreenState extends State<CierreDatafonosScreen> {
  List<CierreDatafono> cierres = [];
  bool showLoader = false;
  double total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().init();
      _getCierres();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();
    final isBound = printer.isBound;
    final isBusy = printer.busy;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          title: 'Cierres de Datafonos',
          elevation: 4,
          shadowColor: kPrimaryColor,
          automaticallyImplyLeading: true,
          foreColor: kNewtextPri,
          backgroundColor: kNewbg,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/splash.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isBound ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                ],
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: cierres.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('datafono-list'),
                            itemCount: cierres.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final CierreDatafono cierre = cierres[index];
                              return Dismissible(
                                key: ValueKey<int>(
                                  cierre.idregistrodatafono ?? index,
                                ),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) =>
                                    _confirmDelete(index, cierre),
                                child: _cierreTile(cierre, isBusy, isBound),
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

  Future<void> _getCierres() async {
    setState(() {
      showLoader = true;
    });

    
    final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
    

    final Response response = await ApiHelper.getCierresDatafonos(
      cierreActPro.cierreFinal!.idcierre ?? 0,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      showLoader = false;
    });

    if (!response.isSuccess) {
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
      return;
    }

    final List<CierreDatafono> fetched = response.result;

    setState(() {
      cierres = fetched;
      total = cierres.fold<double>(
        0,
        (previousValue, element) => previousValue + (element.monto ?? 0),
      );
    });
  }

  Future<bool> _confirmDelete(int index, CierreDatafono cierre) async {
    final bool? shouldDelete = await _showDeleteDialog(cierre);

    if (shouldDelete != true) {
      return false;
    }

    final bool deleted = await _goDelete(cierre.idregistrodatafono ?? 0);

    if (!deleted || !mounted) {
      return false;
    }

    setState(() {
      cierres.removeAt(index);
      total = cierres.fold<double>(
        0,
        (previousValue, element) => previousValue + (element.monto ?? 0),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cierre eliminado correctamente.')),
    );

    return true;
  }

  Future<bool?> _showDeleteDialog(CierreDatafono cierre) {
    final String terminal = cierre.terminal ?? 'Terminal sin nombre';
    final String montoFormatted =
        VariosHelpers.formattedToCurrencyValue((cierre.monto ?? 0).toString());
    final String fecha =
        cierre.fechacierre?.split('T').first ?? 'Sin fecha registrada';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kNewsurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Eliminar cierre',
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
                'Terminal: $terminal',
                style: const TextStyle(color: kNewtextPri, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: $fecha',
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

  Widget _cierreTile(
      CierreDatafono cierre, bool isBusy, bool isBound) {
    final String montoFormatted =
        VariosHelpers.formattedToCurrencyValue((cierre.monto ?? 0).toString());
    final String fecha =
        cierre.fechacierre?.split('T').first ?? 'Sin fecha registrada';
    final String terminal = cierre.terminal ?? 'Terminal sin nombre';
    final String banco = cierre.banco ?? 'Banco sin asignar';
    final String lote =
        cierre.idcierredatafono != null ? '#${cierre.idcierredatafono}' : '--';
    final printer = context.read<PrinterProvider>();

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
                colors: [Colors.indigo, Colors.indigoAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset('assets/data.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(                 
                  terminal,
                  style: const TextStyle(
                    color: kNewtextPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    
                  ),
                   maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  banco,
                  style: const TextStyle(color: kContrateFondoOscuro, fontSize: 14),
                ),
                const SizedBox(height: 4),
                 Text(
                  'Lote: $lote',
                  style: const TextStyle(color: kContrateFondoOscuro, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: $fecha',
                  style: const TextStyle(color: kContrateFondoOscuro, fontSize: 14),
                ),
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
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              IconButton(
                tooltip: isBusy
                    ? 'Imprimiendo...'
                    : (isBound ? 'Imprimir' : 'Conectar impresora'),
                onPressed: isBusy
                    ? null
                    : () async {
                        await printer.runLocked(() async {
                          final ok = await printer.ensureBound();
                          if (!ok) {
                            Fluttertoast.showToast(
                                msg: 'No se pudo conectar a la impresora');
                            return;
                          }
                          final pistero = context
                                  .read<CierreActivoProvider>()
                                  .usuario
                                  ?.nombreCompleto ??
                              '';
                          await onPrintPressed(cierre, pistero: pistero);
                        });
                      },
                icon: const Icon(Icons.print_outlined, color: kNewtextSec),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dismissBackground() {
    return Container(
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
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      key: const ValueKey('datafono-empty'),
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
            child: const Icon(
              Icons.point_of_sale_outlined,
              color: kNewtextSec,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aun no hay cierres',
            style: TextStyle(
              color: kNewtextPri,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra un datafono para verlo aqui.',
            style: TextStyle(
              color: kNewtextMut,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _goAdd,
            icon: const Icon(Icons.add, color: kNewtextPri),
            label: const Text(
              'Crear cierre',
              style: TextStyle(color: kNewtextPri),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kNewborder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalBar() {
    return Container(
      color: kNewsurface,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Acumulado',
            style: TextStyle(
              color: kNewtextSec,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            VariosHelpers.formattedToCurrencyValue(total.toString()),
            style: const TextStyle(
              color: kNewtextPri,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _goDelete(int id) async {
    setState(() {
      showLoader = true;
    });

    final Response response =
        await ApiHelper.delete('/api/CierreDatafonos/', id.toString());

    if (!mounted) {
      return false;
    }

    setState(() {
      showLoader = false;
    });

    if (!response.isSuccess) {
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
      return false;
    }

    return true;
  }

  void _goAdd() async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DatafonoScreen(),
      ),
    );
    if (result == 'yes') {
      _getCierres();
    }
  }

  Future<void> onPrintPressed(CierreDatafono cierre,
      {required String pistero}) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printCierreDatafono(cierre, pistero);
      Fluttertoast.showToast(msg: 'Cierre enviado a impresion');
    } catch (e, st) {
      debugPrint('printCierreDatafono error: $e\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir: $e');
    }
  }
}
