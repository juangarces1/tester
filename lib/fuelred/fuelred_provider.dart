import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/experimental/active_dispatch_manager.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/fuelred/fuelred_api_helper.dart';
import 'package:tester/fuelred/fuelred_ws_service.dart';
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/Components/state/state_widgets.dart';

/// Estado central de la integración FuelRed P4S.
///
/// Responsabilidades:
///   - Mantiene las listas de transacciones esperando y despachos pendientes
///   - Escucha WebSocket y actualiza en tiempo real
///   - Expone acciones REST (acknowledge, start, complete, cancel, verify)
class FuelRedProvider extends ChangeNotifier with ViewStateMixin {
  final FuelRedWsService _ws = FuelRedWsService();

  /// Acceso al WS service para inyectarlo en ActiveDispatchManager.
  FuelRedWsService get wsService => _ws;

  // ── Estado ──────────────────────────────────────────────────
  List<Map<String, dynamic>> waitingTransactions = [];
  List<Map<String, dynamic>> pendingDispatches = [];
  bool wsConnected = false;
  bool _initialized = false;

  final List<StreamSubscription> _subs = [];

  /// Extrae el ID de una transacción (WS usa transaction_id, REST usa id).
  int _txId(Map<String, dynamic> t) =>
      t['transaction_id'] as int? ?? t['id'] as int? ?? 0;

  /// Centraliza la decisión de qué ViewState mostrar y notifica una sola vez.
  void _refreshState() {
    if (waitingTransactions.isEmpty && pendingDispatches.isEmpty) {
      if (viewState != ViewState.empty) {
        setEmpty();
        return;
      }
    } else {
      if (viewState != ViewState.content) {
        setContent();
        return;
      }
    }
    // El estado no cambió pero la data sí — notificar para rebuild.
    notifyListeners();
  }

  // ── Inicialización ──────────────────────────────────────────
  /// Llamar una sola vez después de tener API key configurada.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    setLoading();

    // Suscribirse a streams del WS
    _subs.add(_ws.onConnectionStatus.listen((connected) {
      wsConnected = connected;
      notifyListeners();
    }));

    _subs.add(_ws.onTransactionWaiting.listen((data) {
      final newId = data['transaction_id'] as int? ?? 0;
      // Evitar duplicados (REST puede haberlo cargado antes con key 'id')
      waitingTransactions.removeWhere((t) => _txId(t) == newId);
      waitingTransactions.insert(0, data);
      _refreshState();
      FlutterRingtonePlayer().playNotification();
      debugPrint(
          '[FuelRedProvider] Nueva transacción esperando: ${data['transaction_id']}');
    }));

    _subs.add(_ws.onDispatchReady.listen((data) {
      final txId = data['transaction_id'] as int? ?? 0;
      debugPrint('[FuelRedProvider] dispatch:ready txId=$txId, waiting=${waitingTransactions.map((t) => '${t['id']}/${t['transaction_id']}').toList()}');
      waitingTransactions.removeWhere((t) => _txId(t) == txId);
      pendingDispatches.insert(0, data);
      _refreshState();
      FlutterRingtonePlayer().playNotification();
      debugPrint('[FuelRedProvider] Despacho listo: $txId, waiting restante: ${waitingTransactions.length}');
    }));

    _subs.add(_ws.onTransactionCancelled.listen((data) {
      final txId = data['transaction_id'] as int? ?? 0;
      waitingTransactions.removeWhere((t) => _txId(t) == txId);
      _refreshState();
      FlutterRingtonePlayer().playNotification();
    }));

    _subs.add(_ws.onDispatchUpdate.listen((data) {
      final txId = data['transaction_id'] as int? ?? 0;
      final status = data['dispatch_status'] as String?;
      debugPrint('[FuelRedProvider] Dispatch update: $txId → $status');
      FlutterRingtonePlayer().playNotification();

      // Actualizar en la lista de pending o remover si terminó
      if (status == 'dispensed' || status == 'cancelled') {
        pendingDispatches.removeWhere((d) => _txId(d) == txId);
      } else {
        final idx = pendingDispatches.indexWhere((d) => _txId(d) == txId);
        if (idx >= 0) {
          pendingDispatches[idx] = {
            ...pendingDispatches[idx],
            ...data,
          };
        }
      }
      _refreshState();
    }));

    // Callback al reconectar: re-sincronizar desde REST
    _ws.onReconnect = syncFromRest;

    // Conectar WS
    _ws.connect();

    // Carga inicial desde REST
    await syncFromRest();
  }

  // ── Sincronización REST ─────────────────────────────────────
  Future<void> syncFromRest() async {
    try {
      // Solo loading si no hay datos previos (no borrar pantalla en re-sync)
      if (waitingTransactions.isEmpty && pendingDispatches.isEmpty) {
        setLoading();
      }

      final results = await Future.wait([
        FuelRedApiHelper.getWaitingTransactions(),
        FuelRedApiHelper.getPendingDispatches(),
      ]);
      waitingTransactions = results[0];
      pendingDispatches = results[1];
      _refreshState();
      debugPrint('[FuelRedProvider] Sync REST OK');
    } catch (e) {
      setError('Error al sincronizar: $e');
      debugPrint('[FuelRedProvider] Sync REST error: $e');
    }
  }

  // ── Acciones ────────────────────────────────────────────────

  /// Verificar vehículo + pistero (Sello 2+3).
  Future<Map<String, dynamic>?> verifyVehicle({
    required int transactionId,
    required String rfidTag,
    required String pisteroCode,
  }) async {
    final result = await FuelRedApiHelper.verifyVehicle(
      transactionId: transactionId,
      rfidTag: rfidTag,
      pisteroCode: pisteroCode,
    );
    if (result != null) {
      // Remover de waiting (pasará a pending cuando llegue dispatch:ready por WS)
      waitingTransactions.removeWhere((t) => _txId(t) == transactionId);
      _refreshState();
    }
    return result;
  }

  /// Pistero confirma recepción de la orden.
  Future<bool> acknowledgeDispatch(int dispatchId) async {
    final ok = await FuelRedApiHelper.acknowledgeDispatch(dispatchId);
    if (ok) _updateDispatchStatus(dispatchId, 'acknowledged');
    return ok;
  }

  /// Pistero enciende bomba.
  Future<bool> startDispatch(int dispatchId) async {
    final ok = await FuelRedApiHelper.startDispatch(dispatchId);
    if (ok) _updateDispatchStatus(dispatchId, 'dispensing');
    return ok;
  }

  /// Despacho completado con litros y monto reales.
  Future<Map<String, dynamic>?> completeDispatch({
    required int dispatchId,
    required double liters,
    required int amount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final result = await FuelRedApiHelper.completeDispatch(
      dispatchId: dispatchId,
      liters: liters,
      amount: amount,
      startedAt: startedAt,
      completedAt: completedAt,
    );
    if (result != null) {
      pendingDispatches.removeWhere((d) => _txId(d) == dispatchId);
      _refreshState();
    }
    return result;
  }

  /// Cancelar despacho.
  Future<bool> cancelDispatch({
    required int dispatchId,
    required String reason,
  }) async {
    final ok = await FuelRedApiHelper.cancelDispatch(
      dispatchId: dispatchId,
      reason: reason,
    );
    if (ok) {
      pendingDispatches.removeWhere((d) => _txId(d) == dispatchId);
      waitingTransactions.removeWhere((t) => _txId(t) == dispatchId);
      _refreshState();
    }
    return ok;
  }

  // ── Autorizar despacho FuelRed → pipeline local ─────────────
  /// Toma una orden `dispatch:ready` y la convierte en un DispatchSession
  /// que entra al ActiveDispatchManager para ser trackeada por SignalR.
  Future<bool> authorizeDispatch({
    required BuildContext context,
    required Map<String, dynamic> dispatch,
  }) async {
    // 1. Extraer datos de Flotilla
    final txId = dispatch['transaction_id'] as int? ?? dispatch['id'] as int? ?? 0;
    final rawHoseLabel = dispatch['hose_label'] as String? ?? dispatch['hose_number']?.toString() ?? '0';
    // hose_label puede venir como "09 (Dispensador 3)" — extraer solo los dígitos del inicio
    final hoseDigits = RegExp(r'^\d+').firstMatch(rawHoseLabel)?.group(0) ?? '0';
    final hoseNumber = int.tryParse(hoseDigits) ?? 0;
    final amount = (dispatch['amount'] as num? ?? 0).toDouble();
    debugPrint('[AuthDispatch] 1. txId=$txId hoseLabel=$hoseNumber hoseNumber=$hoseNumber amount=$amount');
    debugPrint('[AuthDispatch] 1. dispatch=$dispatch');

    // 2. Buscar posición/manguera en MapProvider
    final mapProv = context.read<MapProvider>();
    final posIndex = mapProv.positionIndexForNozzle(hoseNumber);
    debugPrint('[AuthDispatch] 2. posIndex=$posIndex stationMap=${mapProv.stationMap != null}');
    if (posIndex == null || mapProv.stationMap == null) {
      debugPrint('[AuthDispatch] ✗ No se encontró posición para manguera $hoseNumber');
      return false;
    }
    final position = mapProv.stationMap![posIndex]!;
    final hose = position.hoses.firstWhere(
      (h) => h.nozzleNumber == hoseNumber,
      orElse: () => position.hoses.first,
    );

    // 3. Validar estado de manguera
    final nozzleCode = hoseNumber.toString().padLeft(2, '0');
    final status = mapProv.getStatus(nozzleCode) ?? 'unknown';
    debugPrint('[AuthDispatch] 3. nozzleCode=$nozzleCode status=$status');
    if (status != 'available' && status != 'blocked') {
      debugPrint('[AuthDispatch] ✗ Manguera $nozzleCode en estado $status');
      return false;
    }

    // 4. Acknowledge + Start a Flotilla
    debugPrint('[AuthDispatch] 4. Acknowledge + Start txId=$txId');
    await acknowledgeDispatch(txId);
    await startDispatch(txId);

    // 5. Preset al hardware
    final tagId = context.read<CierreActivoProvider>().usuario?.attendantId ?? '';
    debugPrint('[AuthDispatch] 5. Preset nozzle=$nozzleCode amount=$amount tagId=$tagId');
    final ok = await ConsoleApiHelper.presetByAmount(
      nozzleCode: nozzleCode,
      amount: amount,
      tagId: tagId,
    );

    if (!ok) {
      debugPrint('[AuthDispatch] ✗ Fallo preset al hardware');
      return false;
    }
    debugPrint('[AuthDispatch] 5. Preset OK');

    // 6. Crear DispatchSession con fuelRedTxId
    final session = DispatchSession(
      id: 'fuelred-$txId-${DateTime.now().microsecondsSinceEpoch}',
      position: position,
      hose: hose,
      fuel: hose.fuel,
      invoiceType: InvoiceType.contado,
      preset: PresetInfo.amount(amount),
      isTankFull: false,
      userIdentifier: tagId,
      fuelRedTxId: txId,
      metadata: {
        'driver_name': dispatch['driver_name'] ?? '',
        'plate': dispatch['plate'] ?? '',
        'fuel_type': dispatch['fuel_type'] ?? '',
        'company_name': dispatch['company_name'] ?? '',
      },
      currentStatus: NozzleStatus.fromString(status),
    );

    // 7. Registrar en ActiveDispatchManager
    context.read<ActiveDispatchManager>().registerDispatch(session);

    // 8. Quitar de pendingDispatches
    pendingDispatches.removeWhere((d) => _txId(d) == txId);
    _refreshState();

    debugPrint('[FuelRedProvider] Despacho FuelRed TX#$txId autorizado → DispatchSession ${session.id}');
    return true;
  }

  // ── Helpers ─────────────────────────────────────────────────

  void _updateDispatchStatus(int dispatchId, String status) {
    final idx = pendingDispatches.indexWhere((d) => _txId(d) == dispatchId);
    if (idx >= 0) {
      pendingDispatches[idx] = {
        ...pendingDispatches[idx],
        'dispatch_status': status,
      };
      _refreshState();
    }
  }

  // ── Conteos para badges ─────────────────────────────────────
  int get waitingCount => waitingTransactions.length;
  int get pendingCount => pendingDispatches.length;
  int get totalActiveCount => waitingCount + pendingCount;

  // ── Cleanup ─────────────────────────────────────────────────
  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _ws.dispose();
    super.dispose();
  }
}
