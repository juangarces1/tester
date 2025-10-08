// lib/ViewModels/dispatch_control.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Models/transaccion.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/helpers/console_api_helper.dart';
import '../ViewModels/new_map.dart' show Fuel, HosePhysical, PositionPhysical;

class DispatchControl extends ChangeNotifier {
  final DespachosProvider _provider;
  DispatchControl(this._provider) { _provider.addListener(_onProviderTick); }

  String?           id;
  PositionPhysical? selectedPosition;
  HosePhysical?     selectedHose;
  InvoiceType?      invoiceType;
  PresetInfo        preset   = PresetInfo.empty();
  bool              tankFull = false;
  Fuel?             fuel;

  int?    type;
  int?    dispenserId;
  int?    hoseId;
  num?    amountRequest;
  num?    amountDispense;
  num?    volumenDispense;
  num?    price;
  String? saleId;
  int?    productId;
  int?    saleNumber;

  bool authorizationExpired = false;
  String? _lastUserIdentifier;

  // Modelo para Almacenar la última transacción
  ConsoleTransaction? consoleTx;
  Transaccion? tx;
  bool _loadingLastSale = false;

  DispatchStage stage = DispatchStage.idle;

  HoseStatus? _lastObservedHoseStatus;
  Timer? _finishTimer;
  void _cancelFinishTimer() { _finishTimer?.cancel(); _finishTimer = null; }

  /// Al terminar la transacción nos desuscribimos automáticamente
  bool autoUnwatchOnTerminal = true;

  HoseStatus get hoseStatus {
    if (selectedHose == null) return HoseStatus.unknown;
    return _provider.getHoseStatus(selectedHose!.hoseKey) ?? HoseStatus.unknown;
  }

  bool get hasAmountOrTank => tankFull || preset.hasValidValue;

  bool get isReadyToAuthorize =>
      stage == DispatchStage.readyToAuthorize && hoseStatus == HoseStatus.available;

  bool _unpaidHookFired = false; // evita disparar el hook más de una vez

  bool get canEditInvoiceType =>
      stage == DispatchStage.authorized ||
      stage == DispatchStage.dispatching ||
      stage == DispatchStage.completed ||
      stage == DispatchStage.unpaid;

  bool get canRetry =>
    stage == DispatchStage.readyToAuthorize &&
    authorizationExpired &&
    hasAmountOrTank;

  String? get notReadyReason {
    if (selectedHose == null) return 'Selecciona manguera/posición';
    if (!hasAmountOrTank)     return 'Indica monto o marca tanque lleno';
    if (hoseStatus != HoseStatus.available) return 'La manguera no está disponible';
    return null;
  }

  Timer? _authLossTimer;
  void _cancelAuthLossTimer() { _authLossTimer?.cancel(); _authLossTimer = null; }

  void setFuel(Fuel v) { fuel = v; notifyListeners(); }

  void selectHose({ required PositionPhysical pos, required HosePhysical hose }) {
    if (selectedHose != null) _provider.removeWatchedHose(selectedHose!.hoseKey);
    selectedPosition = pos;
    selectedHose     = hose;
    id               = hose.hoseKey;
    _provider.addWatchedHose(hose.hoseKey);
    _lastObservedHoseStatus = null;
    _updateStage();
    _onProviderTick(); // primer sync inmediato
    notifyListeners();
  }

  void setInvoiceType(InvoiceType t) { invoiceType = t; _updateStage(); notifyListeners(); }

  void setPreset(PresetInfo p) {
    preset = p;
    tankFull = false;

    // amountRequest solo aplica cuando el preset es de monto; si es volumen lo dejamos nulo.
    amountRequest = p.kind == PresetKind.amount ? p.amount : null;

    _updateStage();
    notifyListeners();
  }

  void setPresetByAmount({required String manguera, required double amount}) {
    setPreset(PresetInfo.amount(manguera: manguera, amount: amount));
  }

  void setPresetByVolume({required String manguera, required double liters}) {
    setPreset(PresetInfo.volume(manguera: manguera, liters: liters));
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

  void markReadyToAuthorize() {
    stage = DispatchStage.readyToAuthorize;
    notifyListeners();
  }

  void markAuthorizing() {
    stage = DispatchStage.authorizing;
    authorizationExpired = false;
    notifyListeners();
  }

  void markAuthorized()  {
    stage = DispatchStage.authorized;
    authorizationExpired = false;
    notifyListeners();
  }

  void markDispatching() {
    stage = DispatchStage.dispatching;
    notifyListeners();
  }

  void markCompleted() {
    _cancelFinishTimer();
    stage = DispatchStage.completed;
    if (autoUnwatchOnTerminal) _detachWatcher();
    notifyListeners();
  }

  void goGetTr() {
    _fetchLastSaleIfNeeded();
    notifyListeners();
  }

  void markUnpaid() {
    if (stage == DispatchStage.unpaid) return; // evita re-entradas

    _cancelFinishTimer();
    stage = DispatchStage.unpaid;
    if (autoUnwatchOnTerminal) _detachWatcher();

    // 1) Notifica inmediatamente el cambio de etapa para que la UI pinte “Sin pagar”
    notifyListeners();

    // 2) Lanza el fetch; él mismo notificará al finalizar
    _fetchLastSaleIfNeeded();
  }

  void syncWithHoseStatus() {
    final s = hoseStatus;

    switch (stage) {
      case DispatchStage.authorizing:
        if (s == HoseStatus.authorized) {
          markAuthorized();
        } else if (s == HoseStatus.fueling) {
          // a veces brinca directo sin authorized “estable”
          markDispatching();
        }
        break;

      case DispatchStage.authorized:
        if (s == HoseStatus.fueling) {
          // Empezó a despachar
          _cancelAuthLossTimer();
          markDispatching();
        } else if (s != HoseStatus.authorized) {
          // Posible expiración: debounce corto para evitar flicker
          _authLossTimer ??= Timer(const Duration(milliseconds: 600), () {
            final ss = hoseStatus;
            final sigueAutorizado = (ss == HoseStatus.authorized || ss == HoseStatus.fueling);
            if (stage == DispatchStage.authorized && !sigueAutorizado) {
              authorizationExpired = true;
              markReadyToAuthorize(); // queda listo para reintentar
            }
            _authLossTimer = null;
          });
        } else {
          // Sigue autorizado estable → cancela cualquier debounce pendiente
          _cancelAuthLossTimer();
        }
        break;

      case DispatchStage.dispatching:
        if (s == HoseStatus.unpaid) {
          _cancelFinishTimer();
          markUnpaid();
          break;
        }
        // Flow real: termina → vuelve a available (o busy/stopped). Cierra si sale de fueling/authorized.
        final leftFueling = s != HoseStatus.fueling && s != HoseStatus.authorized;
        if (leftFueling) {
          _finishTimer ??= Timer(const Duration(milliseconds: 500), () {
            final ss = hoseStatus;
            if (stage == DispatchStage.dispatching &&
                ss != HoseStatus.fueling &&
                ss != HoseStatus.authorized &&
                ss != HoseStatus.unpaid) {
              markUnpaid();
            }
            _finishTimer = null;
          });
        } else {
          _cancelFinishTimer(); // volvió a fueling/authorized → cancela el cierre
        }
        break;

      default:
        _cancelFinishTimer();
        _cancelAuthLossTimer();
        break;
    }
  }

  void clear() {
    _cancelAuthLossTimer();
    consoleTx = null;
    authorizationExpired = false;
    _lastUserIdentifier = null;
    _cancelFinishTimer();
    _detachWatcher();
    selectedPosition = null;
    selectedHose     = null;
    invoiceType      = null;
    preset           = PresetInfo.empty();
    tankFull         = false;
    fuel             = null;
    _unpaidHookFired = false;
    type = null; dispenserId = null; hoseId = null; amountRequest = null;
    amountDispense = null; volumenDispense = null; price = null;
    saleId = null; productId = null; saleNumber = null;

    _lastObservedHoseStatus = null;
    stage = DispatchStage.idle;
    notifyListeners();
  }

  void _detachWatcher() {
    final key = selectedHose?.hoseKey;
    if (key != null) _provider.removeWatchedHose(key);
  }

  @override
  void dispose() {
    _cancelAuthLossTimer();
    _cancelFinishTimer();
    _detachWatcher();
    _provider.removeListener(_onProviderTick);
    super.dispose();
  }

  void _updateStage() {
    if (stage == DispatchStage.authorizing ||
        stage == DispatchStage.authorized  ||
        stage == DispatchStage.dispatching ||
        stage == DispatchStage.completed   ||
        stage == DispatchStage.unpaid) return;

    if (selectedHose == null) {
      stage = DispatchStage.idle;
    } else if (!hasAmountOrTank) {
      stage = DispatchStage.hoseSelected;
    } else {
      stage = DispatchStage.readyToAuthorize;
    }
  }

  void _onProviderTick() {
    if (selectedHose == null) return;
    final curr = hoseStatus;
    if (_lastObservedHoseStatus != curr) {
      _lastObservedHoseStatus = curr;
      syncWithHoseStatus();
      notifyListeners();
    }
  }

  // Implementación Cancelación por tiempo
  // Nuevo Timer para vigilancia de inicio de despacho

  Future<void> Function(Transaccion tx)? onLastUnpaid;

  Future<bool> retryAuthorize() async {
    final uid = _lastUserIdentifier;
    if (uid == null || uid.isEmpty) {
      throw Exception('No hay usuario previo para reintentar');
    }
    return applyPresetAndAuthorize(uid);
  }

  Future<void> _fetchLastSaleIfNeeded() async {
    if (_loadingLastSale) return;
    final nozzle = selectedHose?.nozzleNumber;
    if (nozzle == null || nozzle == 0) return;

    _loadingLastSale = true;
    notifyListeners(); // para que puedas mostrar “sincronizando…”

    try {
      final resp = await ConsoleApiHelper.getTransactionLastByNozzle(nozzle);

      if (resp.isSuccess && resp.result != null) {
        consoleTx        = resp.result;
        saleId           = consoleTx?.saleId;
        saleNumber       = consoleTx?.saleNumber;
        productId        = consoleTx?.fuelCode;
        amountDispense   = consoleTx?.totalValue;
        volumenDispense  = consoleTx?.totalVolume;
        price            = consoleTx?.unitPrice;

        // ⚠️ Solo crea la Transaccion UNA VEZ; no la reemplaces después
        tx ??= consoleTx?.toTransaccion();

        // Dispara el hook solo una vez por ciclo
        final t = tx;
        if (!_unpaidHookFired && t != null) {
          _unpaidHookFired = true;
          // No bloquees la UI esperando el POST
          unawaited(onLastUnpaid?.call(t));
        }

      } else {
        // Limpia estado para no mostrar valores viejos
        consoleTx        = null;
        saleId           = null;
        saleNumber       = null;
        productId        = null;
        amountDispense   = null;
        volumenDispense  = null;
        price            = null;
      }
    } catch (e) {
      // log opcional
      consoleTx        = null;
      saleId           = null;
      saleNumber       = null;
      productId        = null;
      amountDispense   = null;
      volumenDispense  = null;
      price            = null;
    } finally {
      _loadingLastSale = false;
      notifyListeners(); // SIEMPRE notifica al terminar
    }
  }

  bool get loadingLastSale => _loadingLastSale;
}

enum DispatchStage {
  idle, hoseSelected, amountOrTankChosen, readyToAuthorize,
  authorizing, authorized, dispatching, completed, unpaid,
}

enum InvoiceType {
  credito(Colors.blue), contado(Colors.red), peddler(Colors.amber), ticket(Colors.green);
  final Color color; const InvoiceType(this.color);
}

enum PresetKind { amount, volume }

class PresetInfo {
  final String manguera;
  final PresetKind kind;
  /// Monto en moneda (cuando kind == amount). Null en volumen.
  final double? amount;
  /// Volumen en litros (cuando kind == volume). Null en monto.
  final double? volume;

  const PresetInfo._({
    required this.manguera,
    required this.kind,
    required this.amount,
    required this.volume,
  });

  /// Preset de monto
  factory PresetInfo.amount({
    required String manguera,
    required double amount,
  }) {
    return PresetInfo._(
      manguera: manguera,
      kind: PresetKind.amount,
      amount: amount,
      volume: null,
    );
  }

  /// Preset de volumen (litros)
  factory PresetInfo.volume({
    required String manguera,
    required double liters,
  }) {
    return PresetInfo._(
      manguera: manguera,
      kind: PresetKind.volume,
      amount: null,
      volume: liters,
    );
  }

  /// Preset vacío (sin valor)
  factory PresetInfo.empty() {
    return const PresetInfo._(
      manguera: '',
      kind: PresetKind.amount,
      amount: null,
      volume: null,
    );
  }

  bool get hasValidValue =>
      (kind == PresetKind.amount && (amount ?? 0) > 0) ||
      (kind == PresetKind.volume && (volume ?? 0) > 0);

  bool get isAmount => kind == PresetKind.amount;
  bool get isVolume => kind == PresetKind.volume;
}

extension DispatchControlApi on DispatchControl {
  Future<bool> applyPresetAndAuthorize(String userIdentifier) async {
    _lastUserIdentifier = userIdentifier;
    if (selectedHose == null) {
      throw Exception("No hay manguera seleccionada");
    }
    if (!preset.hasValidValue && !tankFull) {
      throw Exception("No hay preset ni tanque lleno definido");
    }

    final nozzle = selectedHose!.nozzleNumber;

    // --- Caso TANQUE LLENO: PostDispenseV2 solo autoriza la máquina ---
    if (tankFull) {
      try {
        final ok = await ConsoleApiHelper.postDispenseV2(nozzle, userIdentifier, authorize: true);
        if (ok) {
          markAuthorized();
          return true;
        } else {
          // asegurar que no quedamos en 'authorizing'
          markReadyToAuthorize();
          return false;
        }
      } catch (_) {
        if (stage == DispatchStage.authorizing) {
          markReadyToAuthorize();
        }
        return false;
      }
    }

    // --- Caso PRESET (monto o volumen): PreDispenseV2 autoriza ---
    final isVolume = preset.isVolume;
    final value = isVolume ? preset.volume! : preset.amount!;

    markAuthorizing();

    try {
      final ok = await ConsoleApiHelper.preDispenseV2(
        nozzle,
        value,
        userIdentifier,
        volumeDispatch: isVolume,
      );

      if (ok) {
        markAuthorized();
        return true;
      } else {
        // <- corrección clave
        markReadyToAuthorize();
        return false;
      }
    } catch (_) {
      markReadyToAuthorize();
      return false;
    }
  }
}
