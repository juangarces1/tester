// lib/Screens/Dispatch/dispatch_summary_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/usuario_provider.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/helpers/varios_helpers.dart';


class DispatchSummaryPage extends StatelessWidget {
  final String dispatchId;
  const DispatchSummaryPage({
    super.key,
    required this.dispatchId,
  });

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<DespachosProvider>(context);
    final DispatchControl? d = despachosProv.getById(dispatchId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Resumen del Despacho',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          _confirmDelete(context);
        },
        mini: true,
        backgroundColor: Colors.white12,
        splashColor: Colors.white24,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      body: d == null
          ? const Center(
              child: Text(
                'Despacho no encontrado',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(
                  icon: Icons.local_gas_station,
                  label: 'Combustible',
                  value: d.fuel?.name ?? '-',
                  color: d.fuel?.color ?? Colors.white,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.map_rounded,
                  label: 'Pocición',
                  value: d.selectedPosition != null
                      ? 'POS-${d.selectedPosition!.number}'
                      : '-',
                  color: const Color.fromARGB(255, 30, 11, 126),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.ev_station,
                  label: 'Manguera',
                  value: d.selectedHose != null
                      ? 'M-${d.selectedHose!.nozzleNumber}'
                      : '-',
                  color: Colors.orangeAccent,
                ),

                // Preset (monto o volumen)
                if (d.preset.hasValidValue) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: d.preset.isAmount ? Icons.attach_money : Icons.speed,
                    label: d.preset.isAmount ? 'Preset (Monto)' : 'Preset (Volumen)',
                    value: d.preset.isAmount
                        ? VariosHelpers.formattedToCurrencyValue(
                            d.preset.amount!.toString(),
                          )
                        : '${d.preset.volume!.toStringAsFixed(2)} L',
                    color: d.preset.isAmount ? Colors.greenAccent : Colors.cyanAccent,
                  ),
                ],

                // Tanque lleno
                if (d.tankFull) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.water_drop,
                    label: 'Tanque lleno',
                    value: 'Sí',
                    color: Colors.tealAccent,
                  ),
                ],

                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.send, color: Colors.white, size: 24),
                      label: const Text(
                        'Autorizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _handleAuthorize(context),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

 Future<void> _handleAuthorize(BuildContext context) async {
  final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
  final dispatch = despachosProv.getById(dispatchId);

  if (dispatch == null) {
    Fluttertoast.showToast(
      msg: 'No se encontró el despacho.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return;
  }

  // Validación previa: evita llamadas cuando no está listo
  if (!dispatch.isReadyToAuthorize) {
    final reason = dispatch.notReadyReason ?? 'No está listo para autorizar.';
    Fluttertoast.showToast(
      msg: reason,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
    return;
  }

 
  // 1) Obtener el usuario actual desde el Provider
  final user = context.read<UsuarioProvider>().current;
  if (user == null || user.identifier.isEmpty) {
    Fluttertoast.showToast(
      msg: 'Debes iniciar sesión para autorizar.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
    return;
  }


  // Mostrar loading (rootNavigator para asegurar pop del diálogo y no de la página)
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  // Helper para cerrar el loading sin riesgo de lanzar
  void safeClose() {
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
  }

  try {
    // Llama a la lógica del ViewModel (maneja markAuthorizing/Authorized y resets)
    final ok = await dispatch
        .applyPresetAndAuthorize(user.identifier)
        .timeout(const Duration(seconds: 8));

    safeClose();

    if (ok) {
      Fluttertoast.showToast(
        msg: 'Manguera lista ✅',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    } else {
      Fluttertoast.showToast(
        msg: 'Error al autorizar',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  } on TimeoutException {
    safeClose();
    Fluttertoast.showToast(
      msg: 'Tiempo de espera agotado',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  } catch (e) {
    safeClose();
    Fluttertoast.showToast(
      msg: 'Error: $e',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}

Future<void> _confirmDelete(BuildContext context) async {
  final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
  final d = despachosProv.getById(dispatchId);

  if (d == null) {
    Fluttertoast.showToast(
      msg: 'Despacho no encontrado.',
      gravity: ToastGravity.CENTER, backgroundColor: Colors.red, textColor: Colors.white,
    );
    return;
  }

  // Opcional: restringe cuándo se puede borrar (evitar while dispatching/completed)
  final canDelete = switch (d.stage) {
    DispatchStage.dispatching || DispatchStage.completed || DispatchStage.unpaid => false,
    _ => true,
  };

  if (!canDelete) {
    Fluttertoast.showToast(
      msg: 'No se puede eliminar en este estado.',
      gravity: ToastGravity.CENTER, backgroundColor: Colors.grey, textColor: Colors.white,
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Eliminar despacho', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Esta acción eliminará el despacho de la lista.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  ) ?? false;

  if (ok) {
    await _handleDelete(context);
  }
}

Future<void> _handleDelete(BuildContext context) async {
  final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
  final d = despachosProv.getById(dispatchId);

  if (d == null) {
    Fluttertoast.showToast(
      msg: 'Despacho no encontrado.',
      gravity: ToastGravity.CENTER, backgroundColor: Colors.red, textColor: Colors.white,
    );
    return;
  }

  // Limpia timers y desuscribe watcher de la manguera
  d.clear();

  // Elimina del provider
  despachosProv.removeDispatch(d);

  Fluttertoast.showToast(
    msg: 'Despacho eliminado',
    gravity: ToastGravity.CENTER, backgroundColor: Colors.green, textColor: Colors.white,
  );

  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}


  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
