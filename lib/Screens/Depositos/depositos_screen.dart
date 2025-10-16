import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/FuelRed/deposito.dart';

import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Screens/Depositos/entrega_efectivo_screen.dart';
import 'package:tester/Screens/test_print/testprint.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class DepositosScreen extends StatefulWidget {
  const DepositosScreen({super.key});
  @override
  State<DepositosScreen> createState() => _DepositosScreenState();
}

class _DepositosScreenState extends State<DepositosScreen> {
  List<Deposito> depositos = [];
  bool showLoader = false;
  late int total = 0;

  @override
  void initState() {
    super.initState();
    // Inicializa el servicio de impresión una vez montado el contexto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().init();
      _getdepositos();
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
          title: 'Depositos',
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
                  // Pequeño indicador de estado de la impresora (verde listo / rojo no conectado)
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
                    child: depositos.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('depositos-list'),
                            itemCount: depositos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final deposito = depositos[index];
                              return Dismissible(
                                key: ValueKey<int>(deposito.iddeposito ?? index),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) =>
                                    _confirmDelete(index, deposito),
                                child: _depositoTile(deposito, isBusy, isBound),
                              );
                            },
                          ),
                  ),
                ),
              ),
        bottomNavigationBar: _totalBar(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kNewgreen,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: _goAdd,
          icon: const Icon(Icons.add, color: Colors.white, size: 29),
          label: const Text('Nuevo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(int index, Deposito deposito) async {
    if (!mounted) return false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: const Text('Esta seguro de que desea eliminar este deposito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    final deleted = await _goDelete(deposito.iddeposito ?? 0);
    if (!deleted || !mounted) return false;
    setState(() {
      depositos.removeAt(index);
      total = depositos.fold(0, (p, e) => p + (e.monto ?? 0));
    });
    return true;
  }

  Widget _depositoTile(Deposito d, bool isBusy, bool isBound) {
    final montoFormatted =
        VariosHelpers.formattedToCurrencyValue((d.monto ?? 0).toString());
    final fecha = d.fechadepostio?.split('T').first ?? 'Sin fecha registrada';
    final moneda = d.moneda ?? 'Sin moneda';
    final printer = context.read<PrinterProvider>();

    return Container(
      decoration: BoxDecoration(
        color: kNewsurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kNewborder),
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
            child: Image.asset('assets/deposito.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moneda: $moneda',
                  style: const TextStyle(
                      color: kNewtextPri,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text('Fecha:  $fecha',
                    style: const TextStyle(color: kNewtextMut, fontSize: 14)),
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
                  // si tu Flutter no soporta withValues, usa withOpacity(0.16)
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
              const SizedBox(height: 6),
              IconButton(
                tooltip: isBusy
                    ? 'Imprimiendo...'
                    : (isBound ? 'Imprimir' : 'Conectar impresora'),
                onPressed: isBusy
                    ? null
                    : () async {
                        await printer.runLocked(() async {
                          // Asegura conexión antes de imprimir
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
                          await onPrintPressed(d, pistero: pistero);
                        });
                      },
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_outlined, color: kNewtextSec),
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
        key: const ValueKey('depositos-empty'),
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
              child: const Icon(Icons.account_balance,
                  color: kNewtextSec, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Aun no hay depositos',
                style: TextStyle(
                    color: kNewtextPri,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Registra uno nuevo para verlo aqui.',
                style: TextStyle(color: kNewtextMut, fontSize: 14)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _goAdd,
              icon: const Icon(Icons.add, color: kNewtextPri),
              label: const Text('Crear deposito',
                  style: TextStyle(color: kNewtextPri)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kNewborder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      );

  Widget _totalBar() => Container(
        color: kNewbg,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Depositos',
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

  Future<void> _getdepositos() async {
    setState(() => showLoader = true);

    final cierreActPro =
        Provider.of<CierreActivoProvider>(context, listen: false);

    final response =
        await ApiHelper.getDepositos(cierreActPro.cierreFinal!.idcierre ?? 0);

    setState(() => showLoader = false);

    if (!response.isSuccess) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(response.message),
            actions: <Widget>[
              TextButton(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    total = 0;
    depositos = (response.result as List).cast<Deposito>();
    for (final element in depositos) {
      total += element.monto ?? 0;
    }
    if (mounted) setState(() {});
  }

  Future<bool> _goDelete(int id) async {
    setState(() => showLoader = true);

    final response = await ApiHelper.delete('/api/Depositos/', id.toString());

    setState(() => showLoader = false);

    if (!response.isSuccess) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(response.message),
            actions: <Widget>[
              TextButton(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.of(context).pop(),
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
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const EntregaEfectivoScreen()),
    );
    if (result == 'yes') {
      _getdepositos();
    }
  }

  Future<void> onPrintPressed(Deposito deposito, {required String pistero}) async {
    try {
      final tp = TestPrint(totalChars: 32); // 32 suele ir bien en Q3
      // await tp.printDeposito(deposito, pistero);
      await tp.printDeposito(deposito, pistero);
      Fluttertoast.showToast(msg: 'Depósito enviado a impresión');
    } catch (e, st) {
      debugPrint('printDeposito error: $e\n$st');
      Fluttertoast.showToast(msg: 'Error al imprimir: $e');
    }
  }
}
