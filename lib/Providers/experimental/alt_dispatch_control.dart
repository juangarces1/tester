import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/ViewModels/new_map.dart'
    show Fuel, HosePhysical, PositionPhysical;
import 'package:tester/Providers/dispatch_control.dart'
    show DispatchStage, InvoiceType, PresetInfo;
import 'package:tester/Providers/despachos_provider.dart' show HoseStatus;
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/transactions_api_helper.dart';

/// Versión alternativa de DispatchControl que no hace polling por sí mismo.
/// Depende totalmente de que el Provider le asigne los estados que vienen del mapa.
class AltDispatchControl extends ChangeNotifier {
  final String id;

  /// Callback que se invoca cuando el despacho se marca como completado.
  /// El provider lo usa para remover este despacho de la lista.
  VoidCallback? onComplete;

  AltDispatchControl({required this.id, this.onComplete});

  // Datos de selección
  PositionPhysical? selectedPosition;
  HosePhysical? selectedHose;
  InvoiceType? invoiceType;
  PresetInfo preset = PresetInfo.empty();
  bool tankFull = false;
  Fuel? fuel;

  // Estado del flujo
  DispatchStage stage = DispatchStage.idle;
  String? hoseStatus; // Estado crudo que viene del mapa

  // Datos del despacho
  num? amountRequest;
  num? amountDispense;
  num? volumenDispense;
  num? price;

  bool authorizationExpired = false;
  String? _lastUserIdentifier;

  bool get canRetry =>
      stage == DispatchStage.readyToAuthorize &&
      authorizationExpired &&
      hasAmountOrTank;

  bool get hasAmountOrTank => tankFull || preset.hasValidValue;

  HoseStatus get hoseStatusEnum {
    final s = hoseStatus?.toLowerCase() ?? '';
    if (s.contains('available')) return HoseStatus.available;
    if (s.contains('author')) return HoseStatus.authorized;
    if (s.contains('fuel')) return HoseStatus.fueling;
    if (s.contains('unpaid')) return HoseStatus.unpaid;
    if (s.contains('busy')) return HoseStatus.busy;
    if (s.contains('stop')) return HoseStatus.stopped;
    if (s.contains('finish')) return HoseStatus.finished;
    return HoseStatus.unknown;
  }

  bool get isReadyToAuthorize =>
      stage != DispatchStage.authorizing &&
      stage != DispatchStage.authorized &&
      stage != DispatchStage.dispatching &&
      (hoseStatusEnum == HoseStatus.available);

  String? get notReadyReason {
    if (selectedHose == null) return 'Selecciona manguera/posición';
    if (!hasAmountOrTank) return 'Indica monto o marca tanque lleno';
    if (hoseStatusEnum != HoseStatus.available) {
      return 'La manguera no está disponible ($hoseStatus)';
    }
    return null;
  }

  void setInvoiceType(InvoiceType type) {
    invoiceType = type;
    notifyListeners();
  }

  void clear() {
    selectedPosition = null;
    selectedHose = null;
    invoiceType = null;
    preset = PresetInfo.empty();
    tankFull = false;
    fuel = null;
    stage = DispatchStage.idle;
    notifyListeners();
  }

  bool get canEditInvoiceType =>
      stage == DispatchStage.authorized ||
      stage == DispatchStage.dispatching ||
      stage == DispatchStage.completed ||
      stage == DispatchStage.unpaid;

  // Propiedades para estados de carga
  bool _loadingLastSale = false;
  bool _persistingTx = false;
  bool _unpaidFlowRunning = false;
  DateTime? _unpaidEnteredAt;

  bool get loadingLastSale => _loadingLastSale;
  bool get persistingTx => _persistingTx;

  // Datos de consola/BD
  ConsoleTransaction? consoleTx;
  Transaccion? tx;
  String? saleId;
  int? saleNumber;
  int? productId;

  int? Function(int)? resolveDispenser;

  void markCompleted() {
    stage = DispatchStage.completed;
    notifyListeners();

    // Notificar al provider para que remueva este despacho
    onComplete?.call();
  }

  /// Flujo completo cuando el despacho termina y queda pendiente de pago.
  /// Replica la lógica de DispatchControl.markUnpaid()
  Future<void> markUnpaid({Duration? delay}) async {
    if (_unpaidFlowRunning) return;
    _unpaidFlowRunning = true;
    _unpaidEnteredAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 6)); // hora Costa Rica (UTC-6)

    try {
      if (stage != DispatchStage.unpaid) {
        stage = DispatchStage.unpaid;
        notifyListeners();
      }

      // Delay opcional (default 1800 ms) para dar tiempo a la consola
      final d = delay ?? const Duration(milliseconds: 1800);
      if (d.inMilliseconds > 0) {
        await Future.delayed(d);
      }

      _loadingLastSale = true;
      notifyListeners();

      try {
        // 1) Bucle consola: esperar tx con hora válida
        final fetchedTx = await _waitForConsoleTx();

        if (fetchedTx == null) {
          _clearConsoleValues();
          return;
        }

        // Guardar datos de consola
        consoleTx = fetchedTx;
        saleId = fetchedTx.saleId;
        saleNumber = fetchedTx.saleNumber;
        productId = fetchedTx.fuelCode;
        amountDispense = fetchedTx.totalValue;
        volumenDispense = fetchedTx.totalVolume;
        price = fetchedTx.unitPrice;
        notifyListeners();

        // 2) Bucle BD: esperar que el worker grabe la tx
        final numero = fetchedTx.fuelingIndex;
        final fecha = fetchedTx.dateTime;

        _persistingTx = true;
        notifyListeners();

        final dbTx = await _waitForDbTx(numero, fecha);

        if (dbTx != null) {
          tx = dbTx;
        } else {
          // Fallback: crear tx local sin id
          tx ??= fetchedTx.toTransaccion(resolveDispenser: resolveDispenser);
        }
      } finally {
        _loadingLastSale = false;
        _persistingTx = false;
        notifyListeners();
      }
    } finally {
      _unpaidFlowRunning = false;
      notifyListeners();
    }
  }

  /// Bucle 1: Pregunta a la consola por la última tx de la manguera
  Future<ConsoleTransaction?> _waitForConsoleTx() async {
    final nozzle = selectedHose?.nozzleNumber;
    if (nozzle == null || nozzle == 0) return null;

    const maxAttempts = 15;
    const retryDelay = Duration(milliseconds: 500);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final resp = await ConsoleApiHelper.getTransactionLastByNozzle(nozzle);
        if (resp.isSuccess && resp.result != null) {
          final candidate = resp.result;
          if (_isTransactionInValidTimeRange(candidate)) {
            return candidate;
          }
        }
      } catch (_) {}

      if (attempt < maxAttempts - 1) {
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  /// Bucle 2: Pregunta a nuestra BD por (numero, fecha)
  Future<Transaccion?> _waitForDbTx(int numero, DateTime fecha) async {
    const maxAttempts = 15;
    const retryDelay = Duration(milliseconds: 500);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final found = await TransaccionesApiHelper.getByKey(numero, fecha);
        if (found != null) {
          return found;
        }
      } catch (_) {}

      if (attempt < maxAttempts - 1) {
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  bool _isTransactionInValidTimeRange(ConsoleTransaction? tx) {
    if (tx == null || _unpaidEnteredAt == null) return false;
    final txTime = tx.dateTime;
    final threshold = _unpaidEnteredAt!.subtract(const Duration(seconds: 30));
    return txTime.isAfter(threshold);
  }

  void _clearConsoleValues() {
    consoleTx = null;
    saleId = null;
    saleNumber = null;
    productId = null;
    amountDispense = null;
    volumenDispense = null;
    price = null;
  }

  /// Método central: El Provider llama a esto cada vez que el mapa se actualiza.
  void updateFromMap(HosePhysical? hose) {
    if (hose == null) return;

    selectedHose = hose;
    hoseStatus = hose.status;
    _syncStageWithStatus(hose.status.toLowerCase());
    notifyListeners();
  }

  void _syncStageWithStatus(String status) {
    // Si ya estamos en unpaid, no cambiamos (el usuario debe facturar)
    if (stage == DispatchStage.unpaid) return;

    final prevStage = stage;
    bool shouldMarkUnpaid = false;

    if (status.contains('fuel')) {
      // Está despachando
      stage = DispatchStage.dispatching;
    } else if (prevStage == DispatchStage.dispatching) {
      // Estábamos despachando y ya NO está en fueling → terminó
      shouldMarkUnpaid = true;
    } else if (status.contains('author')) {
      stage = DispatchStage.authorized;
    } else if (status.contains('unpaid') || status.contains('finish')) {
      shouldMarkUnpaid = true;
    } else if (status.contains('available')) {
      if (prevStage == DispatchStage.authorized ||
          prevStage == DispatchStage.authorizing) {
        // La autorización expiró
        stage = DispatchStage.readyToAuthorize;
        authorizationExpired = true;
      }
    }

    if (shouldMarkUnpaid) {
      debugPrint(
          '[AltDispatchControl] Despacho terminó → iniciando flujo markUnpaid');
      markUnpaid(); // Activa el flujo completo de recuperación de tx
    } else if (prevStage != stage) {
      debugPrint(
          '[AltDispatchControl] _syncStageWithStatus: $prevStage → $stage (hose: $status)');
    }
  }

  void selectPosition(PositionPhysical pos) {
    selectedPosition = pos;
    selectedHose = null;
    stage = DispatchStage.idle;
    notifyListeners();
  }

  void selectHose({required PositionPhysical pos, required HosePhysical hose}) {
    selectedPosition = pos;
    selectedHose = hose;
    fuel = hose.fuel;
    stage = DispatchStage.hoseSelected;
    notifyListeners();
  }

  void setTankFull(bool value) {
    tankFull = value;
    if (value) {
      preset = PresetInfo.empty();
      amountRequest = null;
    }
    _updateStage();
    notifyListeners();
  }

  void setPresetByAmount({required String manguera, required double amount}) {
    preset = PresetInfo.amount(manguera: manguera, amount: amount);
    tankFull = false;
    amountRequest = amount;
    _updateStage();
    notifyListeners();
  }

  void setPresetByVolume({required String manguera, required double liters}) {
    preset = PresetInfo.volume(manguera: manguera, liters: liters);
    tankFull = false;
    amountRequest = null;
    _updateStage();
    notifyListeners();
  }

  void _updateStage() {
    if (stage == DispatchStage.authorizing ||
        stage == DispatchStage.authorized ||
        stage == DispatchStage.dispatching ||
        stage == DispatchStage.unpaid) return;

    if (selectedHose == null) {
      stage = DispatchStage.idle;
    } else if (!hasAmountOrTank) {
      stage = DispatchStage.hoseSelected;
    } else {
      stage = DispatchStage.readyToAuthorize;
    }
  }

  Future<bool> retryAuthorize() async {
    final uid = _lastUserIdentifier;
    if (uid == null) return false;
    return applyPresetAndAuthorize(uid);
  }

  Future<bool> applyPresetAndAuthorize(String userIdentifier) async {
    _lastUserIdentifier = userIdentifier;
    if (selectedHose == null) return false;

    final nozzle = selectedHose!.nozzleNumber;
    stage = DispatchStage.authorizing;
    notifyListeners();
    debugPrint('[AltDispatchControl] Stage → authorizing');

    if (tankFull) {
      final ok = await ConsoleApiHelper.postDispenseV2(nozzle, userIdentifier);
      if (ok) {
        stage = DispatchStage.authorized;
        debugPrint('[AltDispatchControl] Stage → authorized (tank full OK)');
      } else {
        stage = DispatchStage.readyToAuthorize;
        debugPrint(
            '[AltDispatchControl] Stage → readyToAuthorize (tank full FAILED)');
      }
      notifyListeners();
      return ok;
    }

    final isVolume = preset.isVolume;
    final value = isVolume ? preset.volume! : preset.amount!;

    final ok = await ConsoleApiHelper.preDispenseV2(
      nozzle,
      value,
      userIdentifier,
      volumeDispatch: isVolume,
    );

    if (ok) {
      stage = DispatchStage.authorized;
      debugPrint('[AltDispatchControl] Stage → authorized (preset OK)');
    } else {
      stage = DispatchStage.readyToAuthorize;
      debugPrint(
          '[AltDispatchControl] Stage → readyToAuthorize (preset FAILED)');
    }
    notifyListeners();
    return ok;
  }
}
