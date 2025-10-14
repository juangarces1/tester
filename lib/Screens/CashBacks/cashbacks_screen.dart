import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/cashback.dart';
import 'package:tester/Models/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/CashBacks/add_cashback_screen.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class CashbarksScreen extends StatefulWidget {
  

  // ignore: use_key_in_widget_constructors
  const CashbarksScreen();

  @override
  State<CashbarksScreen> createState() => _CashbarksScreenState();
}

class _CashbarksScreenState extends State<CashbarksScreen> {
  List<Cashback> cashs = [];
  bool showLoader = false;
  late int total = 0;

  @override
  void initState() {
    super.initState();
    _getcashsbacks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          title: 'Cashbacks',
          elevation: 4,
          shadowColor: kPrimaryColor,
          automaticallyImplyLeading: true,
          foreColor: kNewtextPri,
          backgroundColor: kNewbg,
          actions:  <Widget>[
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: cashs.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('cashback-list'),
                            itemCount: cashs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final cashback = cashs[index];
                              return Dismissible(
                                key:
                                    ValueKey<int>(cashback.idcashback ?? index),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) => _confirmDelete(index),
                                child: _cashbackTile(cashback),
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

  Future<void> _getcashsbacks() async {
    setState(() {
      showLoader = true;
    });

    
    final cierreActPro = Provider.of<CierreActivoProvider>(context, listen: false);
    

    final Response response = await ApiHelper.getCashBacks(
        cierreActPro.cierreFinal!.idcierre ?? 0);

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

    final List<Cashback> fetched = response.result;
    setState(() {
      cashs = fetched;
      total = cashs.fold(0, (value, element) => value + (element.monto ?? 0));
    });
  }

  Future<bool> _confirmDelete(int index) async {
    final Cashback target = cashs[index];
    final bool? shouldDelete = await _showDeleteDialog(target);

    if (shouldDelete != true) {
      return false;
    }

    final bool deleted = await _goDelete(target.idcashback ?? 0);

    if (!mounted || !deleted) {
      return false;
    }

    setState(() {
      cashs.removeAt(index);
      total = cashs.fold(0, (value, element) => value + (element.monto ?? 0));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cashback eliminado correctamente.')),
    );

    return true;
  }

  Future<bool?> _showDeleteDialog(Cashback cashback) {
    final String montoFormatted = VariosHelpers.formattedToCurrencyValue(
      (cashback.monto ?? 0).toString(),
    );
    final String fecha =
        cashback.fechacashback?.split('T').first ?? 'Sin fecha registrada';
    final String id = (cashback.idcashback ?? 0).toString();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kNewsurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Eliminar cashback',
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

  Widget _cashbackTile(Cashback cashback) {
    final String montoFormatted = VariosHelpers.formattedToCurrencyValue(
        (cashback.monto ?? 0).toString());
    final String fecha =
        cashback.fechacashback?.split('T').first ?? 'Sin fecha registrada';
  

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
          SizedBox(
            height: 56,
            width: 56,
           
            child: Image.asset(
              'assets/cbs.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banco Nacional',
                  style: TextStyle(
                    color: kNewtextPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha: $fecha',
                  style: const TextStyle(
                    color: kNewtextMut,
                    fontSize: 14,
                  ),
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
              IconButton(
                onPressed: () => onPrintPressed(cashback),
                icon: const Icon(Icons.print_outlined, color: kNewtextSec),
                tooltip: 'Imprimir comprobante',
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
      key: const ValueKey('cashback-empty'),
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
              Icons.wallet_giftcard_outlined,
              color: kNewtextSec,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aun no hay cashbacks',
            style: TextStyle(
              color: kNewtextPri,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra uno nuevo para verlo aqui.',
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
              'Crear cashback',
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total acumulado',
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
        await ApiHelper.delete('/api/Cashbacks/', id.toString());

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
        builder: (context) => const AddCashbackScreen(),
      ),
    );
    if (result == 'yes') {
      _getcashsbacks();
    }
  }

  void onPrintPressed(Cashback cashback) {
    // final printerProv = context.read<PrinterProvider>();
    // final device = printerProv.device;
    // if (device == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Selecciona antes un dispositivo')),
    //   );
    //   return;
    // }

    // // Llamas a tu clase de impresión
    // final testPrint = TestPrint(device: device);
    // testPrint.printCashBack(
    //   cashback,
    //   widget.factura.cierreActivo!.cajero.nombreCompleto,
    // );
  }
}
