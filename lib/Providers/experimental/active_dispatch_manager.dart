import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/fuelred/fuelred_api_helper.dart';
import 'package:tester/fuelred/fuelred_ws_service.dart';
import 'package:tester/helpers/api_helper.dart';

/// ActiveDispatchManager es la única fuente de verdad para intenciones de despacho.
/// El estado físico (litros, monto) lo sigue teniendo MapProvider.
/// Aquí solo trackeamos la sesión y su progreso basándonos en NozzleStatus de SignalR.
class ActiveDispatchManager extends ChangeNotifier {
  /// Referencia al WS service de la estación para enviar progreso al backend.
  /// Se inyecta desde main.dart después de crear FuelRedProvider.
  FuelRedWsService? fuelRedWs;

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
      final newStatus = NozzleStatus.fromString(statusStr);
      final oldStatus = session.currentStatus;

      // Capturar datos en vivo mientras la manguera despacha.
      // Se hace ANTES del early-exit porque MapProvider limpia liters/cash/tags
      // en el mismo ciclo que cambia el status a available, y para ese momento
      // ya es tarde. Aquí guardamos el último snapshot válido en cada tick.
      if (newStatus == NozzleStatus.fueling) {
        final vol = mapProv.getLiters(session.nozzleCode);
        final amt = mapProv.getCash(session.nozzleCode);
        final tag = mapProv.getTag(session.nozzleCode);
        if (vol != null) session.lastVolume = vol;
        if (amt != null) session.lastAmount = amt;
        if (tag != null) session.lastTag = tag;

        // Enviar progreso FuelRed al backend cada ~2s
        if (session.isFuelRed && fuelRedWs != null) {
          final now = DateTime.now();
          final last = session.lastProgressSent;
          if (last == null || now.difference(last).inSeconds >= 2) {
            session.lastProgressSent = now;
            fuelRedWs!.sendDispatchProgress(
              transactionId: session.fuelRedTxId!,
              liters: session.lastVolume ?? 0,
              amount: session.lastAmount ?? 0,
              status: 'fueling',
            );
          }
        }
      }

      // No procesar transiciones de estado si no cambió
      if (newStatus == oldStatus) continue;

      debugPrint(
          '🔎 [ActiveDispatchManager] Sesión ${session.id} | Manguera ${session.nozzleCode} | ${oldStatus.name} -> ${newStatus.name}');

      // Actualizar estado directo de SignalR
      session.currentStatus = newStatus;
      hasChanges = true;

      // Marcar hasBeenActivated cuando la manguera se levanta (ready/calling)
      if (newStatus == NozzleStatus.ready && !session.hasBeenActivated) {
        session.hasBeenActivated = true;
        debugPrint(
            '🖐️ [ActiveDispatchManager] Despacho $id -> manguera activada (ready)');
      }

      // Marcar hasFueled y capturar timestamp cuando entra a fueling
      if (newStatus == NozzleStatus.fueling && !session.hasFueled) {
        session.hasFueled = true;
        session.fuelingStartedAt = DateTime.now();
        debugPrint(
            '⛽ [ActiveDispatchManager] Despacho $id -> hasFueled = true (stamp: ${session.fuelingStartedAt})');
      }

      // Evaluar si la manguera volvió a reposo (available o blocked)
      if (newStatus == NozzleStatus.available ||
          newStatus == NozzleStatus.blocked) {
        if (session.hasFueled && !session.isSyncing && !session.isSettled) {
          // Los datos (lastVolume, lastAmount, lastTag) ya fueron capturados
          // progresivamente durante fueling. El timestamp (fuelingStartedAt)
          // se capturó al entrar a fueling.

          // Marcar como sincronizando (evita re-entrada) pero NO como settled
          // para que needsSettlement siga true y la UI muestre el indicador.
          session.startSyncing();
          debugPrint(
              '💳 [ActiveDispatchManager] Despacho $id finalizado con éxito. '
              'Vol: ${session.lastVolume}, Monto: ${session.lastAmount}, Tag: ${session.lastTag}. '
              'Sincronizando...');
          _processCompletedDispatch(session).catchError((e, st) {
            session.markAsSettled();
            debugPrint(
                '❌ [ActiveDispatchManager] Error inesperado sincronizando '
                'despacho ${session.id}: $e');
            notifyListeners();
          });
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
      // Diferir la notificación al siguiente microtask para no llamar
      // notifyListeners() durante la fase de build de Flutter.
      // syncWithPhysicalState se invoca desde el `update` del
      // ChangeNotifierProxyProvider, que corre DENTRO del build phase.
      Future.microtask(() => notifyListeners());
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
    const maxIntentos = 20;
    const intervalo = Duration(seconds: 2);

    final dispensador = session.hose.dispenserNumber ?? 0;
    final fecha = session.fuelingStartedAt ?? DateTime.now();

    if (dispensador == 0) {
      debugPrint(
          '❌ [ActiveDispatchManager] No se puede sincronizar despacho ${session.id}: '
          'dispenserNumber es null/0');
      session.syncFailed();
      notifyListeners();
      return;
    }

    // Delay inicial para dar tiempo al worker del backend
    await Future.delayed(const Duration(seconds: 2));

    debugPrint(
        '🔍 [ActiveDispatchManager] Iniciando polling para despacho ${session.id} '
        '(dispensador $dispensador, fecha $fecha, máx $maxIntentos intentos)');

    for (int intento = 1; intento <= maxIntentos; intento++) {
      await Future.delayed(intervalo);

      debugPrint('🔄 [ActiveDispatchManager] Intento $intento/$maxIntentos '
          'para despacho ${session.id} | dispensador=$dispensador | fecha=$fecha | '
          'fechaStr=${fecha.toIso8601String().split('.').first}');

      final response = await ApiHelper.getUltimaTransaccion(dispensador, fecha);

      debugPrint('   → isSuccess=${response.isSuccess}, '
          'hasResult=${response.result != null}, '
          'message=${response.message}');

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

        // Reportar a Flotilla si es despacho FuelRed (fire-and-forget)
        if (session.isFuelRed) {
          FuelRedApiHelper.completeDispatch(
            dispatchId: session.fuelRedTxId!,
            liters: product.cantidad,
            amount: product.total.toInt(),
          ).then((_) {
            debugPrint(
                '✅ [ActiveDispatchManager] Complete reportado a Flotilla para TX ${session.fuelRedTxId}');
          }).catchError((e) {
            debugPrint(
                '⚠️ [ActiveDispatchManager] Error reportando complete a Flotilla: $e');
          });
        }

        notifyListeners();
        return;
      }
    }

    // Agotó los intentos — NO marcar como settled, permitir retry
    session.syncFailed();
    debugPrint(
        '❌ [ActiveDispatchManager] Se agotaron los $maxIntentos intentos '
        'para despacho ${session.id}. El worker no subió la transacción.');
    notifyListeners();
  }

  /// Reintenta la sincronización de un despacho que falló.
  void retrySync(String id) {
    final session = _sessions[id];
    if (session == null || session.isSyncing || session.isSettled) return;
    if (!session.hasFueled) return;

    session.startSyncing();
    notifyListeners();
    debugPrint('🔁 [ActiveDispatchManager] Reintentando sync para $id');

    _processCompletedDispatch(session).catchError((e, st) {
      session.syncFailed();
      debugPrint('❌ [ActiveDispatchManager] Retry falló para $id: $e');
      notifyListeners();
    });
  }

  // -- Reset --
  void reset() {
    _sessions.clear();
    notifyListeners();
  }
}
