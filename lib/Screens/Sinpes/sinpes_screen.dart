import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Screens/Sinpes/add_sinpe_screen.dart';

import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class SinpesScreen extends StatefulWidget {
  const SinpesScreen({super.key, });

 
  @override
  State<SinpesScreen> createState() => _SinpesScreenState();
}

class _SinpesScreenState extends State<SinpesScreen> {
  List<Sinpe> sinpes = [];
  bool showLoader = false;
  double total = 0;

  @override
  void initState() {
    super.initState();
    _getSinpes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          title: 'Sinpes',
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: sinpes.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('sinpes-list'),
                            itemCount: sinpes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final sinpe = sinpes[index];
                              return Dismissible(
                                key: ValueKey<int>(sinpe.id),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                confirmDismiss: (_) =>
                                    _confirmDelete(index, sinpe),
                                child: _sinpeTile(sinpe),
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
          icon: const Icon(Icons.add, size: 30),
          label: const Text(
            'Nuevo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(int index, Sinpe sinpe) async {
    if (sinpe.activo == 1) {
      Fluttertoast.showToast(
        msg: 'No se puede eliminar un sinpe aplicado',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14,
      );
      return false;
    }

    final deleted = await _goDelete(sinpe);
    if (!deleted || !mounted) return false;
    setState(() {
      sinpes.removeAt(index);
      total = sinpes.fold<double>(0, (prev, e) => prev + e.monto);
    });
    Fluttertoast.showToast(
      msg: 'Sinpe eliminado con �xito',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 14,
    );
    return true;
  }

 Widget _sinpeTile(Sinpe sinpe) {
  final estadoAplicado = sinpe.activo == 1;
  final fechaFormatted = DateFormat('dd/MM/yyyy HH:mm').format(sinpe.fecha);
  final montoFormatted =
      VariosHelpers.formattedToCurrencyValue(sinpe.monto.toString());
  final estadoColor = estadoAplicado ? kNewgreen : const Color(0xFFFBBF24);
  final estadoLabel = estadoAplicado ? 'Aplicado' : 'Disponible';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen a la izquierda
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/sinpe.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 16),

        // Toda la info a la derecha en UNA sola columna
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título (comprobante)
              Text(
                'Comprobante: ${sinpe.numComprobante}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kNewtextPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),

              // Fecha
              Text(
                'Fecha: $fechaFormatted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kNewtextPri, fontSize: 18),
              ),
              const SizedBox(height: 2),

              // Empleado
              Text(
                'Creado por: ${sinpe.nombreEmpleado}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kNewtextPri, fontSize: 18),
              ),

              // Nota (opcional)
              if (sinpe.nota.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sinpe.nota,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kNewtextSec, fontSize: 15),
                ),
              ],

              const SizedBox(height: 10),

              // Chips en la MISMA columna (envueltos si no caben)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: estadoColor),
                    ),
                    child: Text(
                      estadoLabel,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
                ],
              ),
            ],
          ),
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
        key: const ValueKey('sinpes-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: kColorMenu,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kNewborder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/sinpe.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aun no hay sinpes',
              style: TextStyle(
                color: kNewtextPri,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registra un nuevo sinpe para comenzar.',
              style: TextStyle(color: kNewtextMut, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _totalBar() => Container(
        color: kNewsurface,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Sinpes',
              style: TextStyle(
                color: kNewtextSec,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              VariosHelpers.formattedToCurrencyValue(
                total.toStringAsFixed(2),
              ),
              style: const TextStyle(
                color: kNewtextPri,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Future<void> _getSinpes() async {
    setState(() {
      showLoader = true;
    });

    var cierreFinal = Provider.of<CierreActivoProvider>(context, listen: false).cierreFinal!;
     
    final Response response = await ApiHelper.getSinpes(
      cierreFinal.idcierre ?? 0,
    );

    setState(() {
      showLoader = false;
    });

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

    sinpes = List<Sinpe>.from(response.result);
    total = sinpes.fold<double>(0, (prev, e) => prev + e.monto);
    setState(() {});
  }

  Future<bool> _goDelete(Sinpe sinpe) async {
    setState(() {
      showLoader = true;
    });

    final response = await ApiHelper.delete(
      '/api/Sinpes/',
      sinpe.id.toString(),
    );

    setState(() {
      showLoader = false;
    });

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
        builder: (context) => const AddSinpeScreen(),
      ),
    );
    if (result == 'yes') {
      _getSinpes();
    }
  }
}
