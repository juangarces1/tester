import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/FuelRed/peddler.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class PeddlersScreen extends StatefulWidget {
  const PeddlersScreen({super.key, });

  
  @override
  State<PeddlersScreen> createState() => _PeddlersScreenState();
}

class _PeddlersScreenState extends State<PeddlersScreen> {
  List<Peddler> peddlers = [];
  bool showLoader = false;
  double total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().init();
      _getPeddlers();
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
          title: 'Peddlers',
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
                    child: peddlers.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('peddlers-list'),
                            itemCount: peddlers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final peddler = peddlers[index];
                              return Dismissible(
                                key: ValueKey<int>(peddler.id ?? index),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) =>
                                    _confirmDelete(index, peddler),
                                child: _peddlerTile(peddler, isBusy, isBound),
                              );
                            },
                          ),
                  ),
                ),
              ),
        bottomNavigationBar: _totalBar(),
      ),
    );
  }

  Future<bool> _confirmDelete(int index, Peddler peddler) async {
    final deleted = await _goDelete(peddler);
    if (!deleted || !mounted) return false;
    setState(() {
      peddlers.removeAt(index);
      total = peddlers.fold<double>(0, (prev, e) => prev + e.total);
    });
    
    Fluttertoast.showToast(
      msg: 'Peddler eliminado con �xito',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 14,
    );
    return true;
  }

  Widget _peddlerTile(
      Peddler p, bool isBusy, bool isBound) {
    final cliente = p.cliente?.nombre ?? 'Sin cliente';
    final fecha = p.fecha?.split('T').first ?? 'Sin fecha registrada';
    final placa = p.placa?.isNotEmpty == true ? p.placa! : 'Sin placa';
    final chofer = p.chofer?.isNotEmpty == true ? p.chofer! : 'Sin chofer';
    final orden = p.orden?.isNotEmpty == true ? p.orden! : 'Sin orden';
    final montoFormatted =
        VariosHelpers.formattedToCurrencyValue(p.total.toStringAsFixed(2));
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
            child: Image.asset('assets/peddler.png', fit: BoxFit.contain),
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: $fecha',
                  style: const TextStyle(color: kNewtextMut, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orden: $orden',
                  style: const TextStyle(color: kNewtextSec, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Placa: $placa � Chofer: $chofer',
                  style: const TextStyle(color: kNewtextSec, fontSize: 13),
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
                          await _printPeddler(p);
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
        key: const ValueKey('peddlers-empty'),
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
              child: const Icon(Icons.fire_truck,
                  color: kNewtextSec, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aun no hay peddlers',
              style: TextStyle(
                color: kNewtextPri,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
           
          ],
        ),
      );

  Widget _totalBar() => Container(
        color: kNewsurface,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Peddlers',
              style: TextStyle(
                color: kNewtextSec,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              VariosHelpers
                  .formattedToVolumenValue(total.toString()),
              style: const TextStyle(
                color: kNewtextPri,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Future<bool> _goDelete(Peddler ped) async {
    setState(() {
      showLoader = true;
    });

    final response =
        await ApiHelper.delete('/api/Peddler/', ped.id.toString());

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

  Future<void> _getPeddlers() async {
    setState(() {
      showLoader = true;
    });

    var cierreFinal =  context.read<CierreActivoProvider>().cierreFinal;

    final response = await ApiHelper.getPeddlersByCierre(
        cierreFinal!.idcierre ?? 0);

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

    peddlers = List<Peddler>.from(response.result);
    total = peddlers.fold<double>(0, (prev, e) => prev + e.total);
    setState(() {});
  }

  Future<void> _printPeddler(Peddler peddler) async {
    try {
      final tp = TestPrint(totalChars: 32);
      await tp.printPeddler(peddler);
      Fluttertoast.showToast(msg: 'Peddler enviado a impresion');
    } catch (e, st) {
      debugPrint('printPeddler error: $e\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir: $e');
    }
  }
}
