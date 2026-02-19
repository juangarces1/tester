import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/ViewModels/new_map.dart'
    show Fuel, HosePhysical, PositionPhysical;
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/transactions_api_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS (consolidados aquí, ya no dependen de dispatch_control.dart ni
// despachos_provider.dart)
// ─────────────────────────────────────────────────────────────────────────────

enum HoseStatus {
  available,
  authorized,
  busy,
  fueling,
  unpaid,
  stopped,
  blocked,
  unknown,
  finished,
}

enum DispatchStage {
  idle,
  hoseSelected,
  readyToAuthorize,
  authorizing,
  authorized,
  dispatching,
  unpaid,
  completed,
}

enum InvoiceType {
  contado,
  ticket,
  credito,
  peddler;

  Color get color {
    switch (this) {
      case InvoiceType.contado:
        return Colors.blue;
      case InvoiceType.ticket:
        return Colors.orange;
      case InvoiceType.credito:
        return Colors.green;
      case InvoiceType.peddler:
        return Colors.yellow;
    }
  }
}

enum PresetKind { amount, volume }

class PresetInfo {
  final PresetKind? kind;
  final double? amount;
  final double? volume;
  final String? manguera;

  const PresetInfo._({this.kind, this.amount, this.volume, this.manguera});

  factory PresetInfo.empty() => const PresetInfo._();

  factory PresetInfo.amount(
          {required String manguera, required double amount}) =>
      PresetInfo._(kind: PresetKind.amount, amount: amount, manguera: manguera);

  factory PresetInfo.volume(
          {required String manguera, required double liters}) =>
      PresetInfo._(kind: PresetKind.volume, volume: liters, manguera: manguera);

  bool get hasValidValue =>
      (kind == PresetKind.amount && (amount ?? 0) > 0) ||
      (kind == PresetKind.volume && (volume ?? 0) > 0);

  bool get isAmount => kind == PresetKind.amount;
  bool get isVolume => kind == PresetKind.volume;
}

// ─────────────────────────────────────────────────────────────────────────────
// AltDispatchControl
// ─────────────────────────────────────────────────────────────────────────────

/// Versión simplificada de DispatchControl que no hace polling por sí mismo.
/// Depende de que MapProvider (vía SignalR) le asigne los estados del mapa.
class AltDispatchControl extends ChangeNotifier {
  final String id;

  /// Callback que se invoca cuando el despacho se marca como completado.
  VoidCallback? onComplete;

  AltDispatchControl({required this.id, this.onComplete});

  // ── Datos de selección ──────────────────────────────────────────────────────
  PositionPhysical? selectedPosition;
  HosePhysical? selectedHose;
  InvoiceType? invoiceType;
  PresetInfo preset = PresetInfo.empty();
  bool tankFull = false;
  Fuel? fuel;

  // ── Estado del flujo ────────────────────────────────────────────────────────
  DispatchStage stage = DispatchStage.idle;
  String? hoseStatus; // Estado crudo que viene del mapa (SignalR)

  // ── Datos del despacho ──────────────────────────────────────────────────────
  num? amountRequest;
  num? amountDispense;
  num? volumenDispense;
  num? price;

  bool authorizationExpired = false;
  String? _lastUserIdentifier;

  // ── Propiedades de carga ────────────────────────────────────────────────────
  bool _loadingLastSale = false;
  bool _persistingTx = false;
  bool _unpaidFlowRunning = false;
  DateTime? _unpaidEnteredAt;

  bool get loadingLastSale => _loadingLastSale;
  bool get persistingTx => _persistingTx;

  // ── Datos de consola/BD ─────────────────────────────────────────────────────
  ConsoleTransaction? consoleTx;
  Transaccion? tx;
  String? saleId;
  int? saleNumber;
  int? productId;

  int? Function(int)? resolveDispenser;

  // ── Getters derivados ───────────────────────────────────────────────────────

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
    if (s.contains('blocked')) return HoseStatus.blocked;
    return HoseStatus.unknown;
  }

  bool get isReadyToAuthorize =>
      stage != DispatchStage.authorizing &&
      stage != DispatchStage.authorized &&
      stage != DispatchStage.dispatching &&
      (hoseStatusEnum == HoseStatus.available ||
          hoseStatusEnum == HoseStatus.blocked);

  String? get notReadyReason {
    if (selectedHose == null) return 'Selecciona manguera/posición';
    if (!hasAmountOrTank) return 'Indica monto o marca tanque lleno';
    if (hoseStatusEnum != HoseStatus.available &&
        hoseStatusEnum != HoseStatus.blocked) {
      return 'La manguera no está disponible ($hoseStatus)';
    }
    return null;
  }

  bool get canEditInvoiceType =>
      stage == DispatchStage.authorized ||
      stage == DispatchStage.dispatching ||
      stage == DispatchStage.completed ||
      stage == DispatchStage.unpaid;

  // ── Métodos de selección ────────────────────────────────────────────────────

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
    hoseStatus = hose.status; // sincroniza estado inicial desde el mapa
    stage = DispatchStage.hoseSelected;
    notifyListeners();
  }

  void setInvoiceType(InvoiceType type) {
    invoiceType = type;
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
        stage == DispatchStage.unpaid) {
      return;
    }

    if (selectedHose == null) {
      stage = DispatchStage.idle;
    } else if (!hasAmountOrTank) {
      stage = DispatchStage.hoseSelected;
    } else {
      stage = DispatchStage.readyToAuthorize;
    }
  }

  void clear() {
    selectedPosition = null;
    selectedHose = null;
    invoiceType = null;
    preset = PresetInfo.empty();
    tankFull = false;
    fuel = null;
    hoseStatus = null;
    stage = DispatchStage.idle;
    notifyListeners();
  }

  // ── Ciclo de vida del despacho ──────────────────────────────────────────────

  void markCompleted() {
    stage = DispatchStage.completed;
    notifyListeners();
    onComplete?.call();
  }

  /// Flujo completo cuando el despacho termina y queda pendiente de pago.
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

      final d = delay ?? const Duration(milliseconds: 1800);
      if (d.inMilliseconds > 0) {
        await Future.delayed(d);
      }

      _loadingLastSale = true;
      notifyListeners();

      try {
        final fetchedTx = await _waitForConsoleTx();

        if (fetchedTx == null) {
          _clearConsoleValues();
          return;
        }

        consoleTx = fetchedTx;
        saleId = fetchedTx.saleId;
        saleNumber = fetchedTx.saleNumber;
        productId = fetchedTx.fuelCode;
        amountDispense = fetchedTx.totalValue;
        volumenDispense = fetchedTx.totalVolume;
        price = fetchedTx.unitPrice;
        notifyListeners();

        final numero = fetchedTx.fuelingIndex;
        final fecha = fetchedTx.dateTime;

        _persistingTx = true;
        notifyListeners();

        final dbTx = await _waitForDbTx(numero, fecha);

        if (dbTx != null) {
          tx = dbTx;
        } else {
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

  // ── Autorización ────────────────────────────────────────────────────────────

  Future<bool> retryAuthorize() async {
    final uid = _lastUserIdentifier;
    if (uid == null) return false;
    return applyPresetAndAuthorize(uid);
  }

  Future<bool> applyPresetAndAuthorize(String userIdentifier) async {
    _lastUserIdentifier = userIdentifier;
    if (selectedHose == null) return false;

    // El nuevo API requiere nozzleCode como string con cero a la izquierda ("01".."48")
    final nozzleCode = selectedHose!.nozzleNumber.toString().padLeft(2, '0');

    stage = DispatchStage.authorizing;
    notifyListeners();
    debugPrint(
        '[AltDispatchControl] Stage → authorizing (nozzle: $nozzleCode)');

    bool ok;

    if (tankFull) {
      ok = await ConsoleApiHelper.presetTankFull(
        nozzleCode: nozzleCode,
        tagId: userIdentifier,
      );
      debugPrint('[AltDispatchControl] presetTankFull → $ok');
    } else if (preset.isVolume) {
      ok = await ConsoleApiHelper.presetByVolume(
        nozzleCode: nozzleCode,
        liters: preset.volume!,
        tagId: userIdentifier,
      );
      debugPrint(
          '[AltDispatchControl] presetByVolume(${preset.volume}L) → $ok');
    } else {
      ok = await ConsoleApiHelper.presetByAmount(
        nozzleCode: nozzleCode,
        amount: preset.amount!,
        tagId: userIdentifier,
      );
      debugPrint(
          '[AltDispatchControl] presetByAmount(₡${preset.amount}) → $ok');
    }

    if (ok) {
      stage = DispatchStage.authorized;
      debugPrint('[AltDispatchControl] Stage → authorized');
    } else {
      stage = DispatchStage.readyToAuthorize;
      debugPrint('[AltDispatchControl] Stage → readyToAuthorize (FAILED)');
    }
    notifyListeners();
    return ok;
  }

  // ── Sincronización con SignalR (vía AltDespachosProvider) ───────────────────

  /// El Provider llama a esto cada vez que el mapa se actualiza vía SignalR.
  void updateFromMap(HosePhysical? hose) {
    if (hose == null) return;

    selectedHose = hose;
    hoseStatus = hose.status;
    _syncStageWithStatus(hose.status.toLowerCase());
    notifyListeners();
  }

  void _syncStageWithStatus(String status) {
    if (stage == DispatchStage.unpaid) return;

    final prevStage = stage;
    bool shouldMarkUnpaid = false;

    if (status.contains('fuel')) {
      stage = DispatchStage.dispatching;
    } else if (prevStage == DispatchStage.dispatching) {
      shouldMarkUnpaid = true;
    } else if (status.contains('author')) {
      stage = DispatchStage.authorized;
    } else if (status.contains('unpaid') || status.contains('finish')) {
      shouldMarkUnpaid = true;
    } else if (status.contains('available')) {
      if (prevStage == DispatchStage.authorized ||
          prevStage == DispatchStage.authorizing) {
        stage = DispatchStage.readyToAuthorize;
        authorizationExpired = true;
      }
    }

    if (shouldMarkUnpaid) {
      debugPrint(
          '[AltDispatchControl] Despacho terminó → iniciando flujo markUnpaid');
      markUnpaid();
    } else if (prevStage != stage) {
      debugPrint(
          '[AltDispatchControl] _syncStageWithStatus: $prevStage → $stage (hose: $status)');
    }
  }

  // ── Bucles de espera ────────────────────────────────────────────────────────

  /// El nuevo API no expone un endpoint de consulta de transacciones por manguera.
  /// Los estados llegan por SignalR. Este método retorna null hasta que se
  /// integre un endpoint equivalente en el nuevo backend.
  Future<ConsoleTransaction?> _waitForConsoleTx() async {
    debugPrint(
        '[AltDispatchControl] _waitForConsoleTx: no disponible en nuevo API');
    return null;
  }

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

  void _clearConsoleValues() {
    consoleTx = null;
    saleId = null;
    saleNumber = null;
    productId = null;
    amountDispense = null;
    volumenDispense = null;
    price = null;
  }
}
