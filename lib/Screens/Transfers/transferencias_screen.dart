import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';

import 'package:tester/Models/transparcial.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({super.key, });

 
  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  List<TransParcial> transfers = [];
  bool showLoader = false;
  double totalAplicado = 0;

  @override
  void initState() {
    super.initState();
    _getTransfers();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: MyCustomAppBar(
          title: 'Transferencias',
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
                    child: transfers.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            key: const ValueKey('transferencias-list'),
                            itemCount: transfers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) =>
                                _transferTile(transfers[index]),
                          ),
                  ),
                ),
              ),
        bottomNavigationBar: _totalBar(),
      ),
    );
  }

  Widget _transferTile(TransParcial transfer) {
    final cliente = transfer.cliente.isNotEmpty
        ? transfer.cliente
        : 'Cliente no definido';
    final banco =
        transfer.banco.isNotEmpty ? transfer.banco : 'Banco no registrado';
    final cuenta =
        transfer.cuenta.isNotEmpty ? transfer.cuenta : 'Cuenta no disponible';
    final numeroDeposito = transfer.numeroDeposito.isNotEmpty
        ? transfer.numeroDeposito
        : 'Sin número';
    final aplicado = VariosHelpers.formattedToCurrencyValue(
      transfer.aplicado.toString(),
    );
    final saldo = VariosHelpers.formattedToCurrencyValue(
      transfer.saldo.toString(),
    );

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
            child: Image.asset('assets/tr9.png', fit: BoxFit.contain),
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
                  'Depósito: $numeroDeposito',
                  style: const TextStyle(color: kNewtextMut, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Banco: $banco',
                  style: const TextStyle(color: kNewtextSec, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cuenta: $cuenta',
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
                  aplicado,
                  style: const TextStyle(
                    color: kNewgreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Text(
                  'Saldo: $saldo',
                  style: const TextStyle(
                    color: kNewtextSec,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        key: const ValueKey('transferencias-empty'),
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
              child: const Icon(Icons.swap_horiz_outlined,
                  color: kNewtextSec, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay transferencias',
              style: TextStyle(
                color: kNewtextPri,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registra una transferencia para verla aquí.',
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
              'Total Aplicado',
              style: TextStyle(
                color: kNewtextSec,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              VariosHelpers.formattedToCurrencyValue(
                totalAplicado.toStringAsFixed(2),
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

  Future<void> _getTransfers() async {
    setState(() {
      showLoader = true;
    });

    var cierreFinal = context.read<CierreActivoProvider>().cierreFinal;

    final response = await ApiHelper.getTransfesByCierre(
      cierreFinal!.idcierre ?? 0,
    );

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

    transfers = List<TransParcial>.from(response.result);
    totalAplicado = transfers.fold<double>(
      0,
      (prev, e) => prev + e.aplicado,
    );

    setState(() {});
  }
}
