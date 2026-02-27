import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/helpers/api_helper.dart';

/// ActiveDispatchManager es la única fuente de verdad para intenciones de despacho.
/// El estado físico (litros, monto) lo sigue teniendo MapProvider.
/// Aquí solo trackeamos la sesión y su progreso basándonos en NozzleStatus de SignalR.
class ActiveDispatchManager extends ChangeNotifier {
  final Map<String, DispatchSession> _sessions = {};

  Map<String, DispatchSession> get sessions => _sessions;
  List<DispatchSession> get activeSessions =>
      _sessions.values.where((s) => !s.isCompleted).toList();

  /// Agrega un nuevo despacho al sistema tras haber sido autorizado con éxito en el Wizard.
  void registerDispatch(DispatchSession session) {
    _sessions[session.id] = session;
    notifyListeners();
    debugPrint(
        '🚀 [ActiveDispatchManager] Registrado despacho ${session.id} en manguera ${session.nozzleCode}');
  }

  /// Fuerza el redibujo manual desde la UI si se cambian propiedades de una sesión existente.
  void forceRefresh() => notifyListeners();

  /// Recupera un despacho por su ID.
  DispatchSession? getSession(String id) => _sessions[id];

  /// Marca un despacho como completamente cerrado por el usuario (ej. ya facturado).
  void finishSession(String id) {
    if (_sessions.containsKey(id)) {
      _sessions[id]!.markAsFinished();
      _sessions.remove(id);
      notifyListeners();
      debugPrint('🏁 [ActiveDispatchManager] Despacho $id cerrado y removido.');
    }
  }

  /// Método Core Reaccionario.
  /// Llamado cada vez que MapProvider recibe información fresca mediante SignalR.
  ///
  /// Flujo esperado de la manguera:
  ///   blocked/available -> ready -> waiting -> fueling -> blocked/available
  ///
  /// Si pasó por fueling (hasFueled=true) y vuelve a available/blocked
  /// -> hubo despacho -> sincronizar con consola.
  /// Si NUNCA pasó por fueling y vuelve a available/blocked
  /// -> no despachó -> reintentar o descartar.
  void syncWithPhysicalState(MapProvider mapProv) {
    bool hasChanges = false;

    final sessionIds = _sessions.keys.toList();

    for (final id in sessionIds) {
      final session = _sessions[id]!;
      if (session.isCompleted) continue;

      // Leer estado real de SignalR
      final statusStr = mapProv.getStatus(session.nozzleCode) ?? 'unknown';
      final newStatus = _parseStatus(statusStr);
      final oldStatus = session.currentStatus;

      // No procesar si no cambió
      if (newStatus == oldStatus) continue;

      debugPrint(
          '🔎 [ActiveDispatchManager] Sesión ${session.id} | Manguera ${session.nozzleCode} | ${oldStatus.name} -> ${newStatus.name}');

      // Actualizar estado directo de SignalR
      session.currentStatus = newStatus;
      hasChanges = true;

      // Marcar hasFueled si pasa por fueling
      if (newStatus == NozzleStatus.fueling && !session.hasFueled) {
        session.hasFueled = true;
        debugPrint(
            '⛽ [ActiveDispatchManager] Despacho $id -> hasFueled = true');
      }

      // Evaluar si la manguera volvió a reposo (available o blocked)
      if (newStatus == NozzleStatus.available ||
          newStatus == NozzleStatus.blocked) {
        if (session.hasFueled && !session.isSyncing && !session.isSettled) {
          // Capturar datos finales ANTES de que MapProvider los limpie
          session.fuelingEndedAt = DateTime.now();
          session.lastVolume = mapProv.getLiters(session.nozzleCode);
          session.lastAmount = mapProv.getCash(session.nozzleCode);
          session.lastTag = mapProv.getTag(session.nozzleCode);

          // Marcar como sincronizando (evita re-entrada) pero NO como settled
          // para que needsSettlement siga true y la UI muestre el indicador.
          session.startSyncing();
          debugPrint(
              '💳 [ActiveDispatchManager] Despacho $id finalizado con éxito. '
              'Vol: ${session.lastVolume}, Monto: ${session.lastAmount}, Tag: ${session.lastTag}. '
              'Sincronizando...');
          _processCompletedDispatch(session);
        }
        // Si !hasFueled, dejamos la sesión visible para que el usuario
        // decida reintentar o descartar (canRetryOrDiscard == true).
      }

      // Error del hardware
      if (newStatus == NozzleStatus.error ||
          newStatus == NozzleStatus.failure) {
        debugPrint(
            '⚠️ [ActiveDispatchManager] Despacho $id -> Error de hardware');
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Busca la transacción en la API de FuelRed una vez que el despacho finalizó.
  ///
  /// Flujo:
  ///  1. Polling cada 1 s (máx 10 intentos) hasta que el worker suba la tx.
  ///  2. Consulta `GetUltimaTransaccion` con el dispensador y la fecha de fin.
  ///  3. Si la obtiene como Product, lo asigna a [session.syncedProduct].
  ///  4. Notifica a la UI para que actualice la tarjeta.
  Future<void> _processCompletedDispatch(DispatchSession session) async {
    const maxIntentos = 10;
    const intervalo = Duration(seconds: 1);

    final dispensador = session.hose.dispenserNumber ?? 0;
    final fecha = session.fuelingEndedAt ?? DateTime.now();

    if (dispensador == 0) {
      debugPrint(
          '❌ [ActiveDispatchManager] No se puede sincronizar despacho ${session.id}: '
          'dispenserNumber es null/0');
      notifyListeners();
      return;
    }

    // Delay inicial para dar tiempo al worker del backend
    await Future.delayed(const Duration(seconds: 3));

    debugPrint(
        '🔍 [ActiveDispatchManager] Iniciando polling para despacho ${session.id} '
        '(dispensador $dispensador, fecha $fecha, máx $maxIntentos intentos)');

    for (int intento = 1; intento <= maxIntentos; intento++) {
      await Future.delayed(intervalo);

      debugPrint('🔄 [ActiveDispatchManager] Intento $intento/$maxIntentos '
          'para despacho ${session.id}');

      final response = await ApiHelper.getUltimaTransaccion(dispensador, fecha);

      if (response.isSuccess && response.result != null) {
        // ✅ Encontró la transacción
        final product = response.result as Product;
        session.syncedProduct = product;
        session.markAsSettled();

        debugPrint(
            '✅ [ActiveDispatchManager] Product sincronizado (intento $intento) '
            'para despacho ${session.id}: '
            'detalle=${product.detalle}, '
            'vol=${product.cantidad}, '
            'total=${product.total}, '
            'dispensador=${product.dispensador}');

        notifyListeners();
        return;
      }
    }

    // Agotó los intentos
    session.markAsSettled();
    debugPrint(
        '❌ [ActiveDispatchManager] Se agotaron los $maxIntentos intentos '
        'para despacho ${session.id}. El worker no subió la transacción.');
    notifyListeners();
  }

  /// Convierte el string de estado de SignalR al enum NozzleStatus.
  NozzleStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return NozzleStatus.available;
      case 'blocked':
        return NozzleStatus.blocked;
      case 'fueling':
        return NozzleStatus.fueling;
      case 'calling':
        return NozzleStatus.ready;
      case 'waiting':
        return NozzleStatus.waiting;
      case 'error':
        return NozzleStatus.error;
      case 'busy':
        return NozzleStatus.busy;
      case 'unavailable':
        return NozzleStatus.notConfigured;
      default:
        return NozzleStatus.unknown;
    }
  }

  // -- Reset --
  void reset() {
    _sessions.clear();
    notifyListeners();
  }
}
