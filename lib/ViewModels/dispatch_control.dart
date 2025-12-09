import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/transactions_api_helper.dart';
import '../ViewModels/new_map.dart' show Fuel, HosePhysical, PositionPhysical;

class DispatchControl extends ChangeNotifier {
  final DespachosProvider _provider;
  int? Function(int)? _resolveDispenser;

  DispatchControl(
    this._provider, {
    int? Function(int)? resolveDispenser, // opcional
  }) : _resolveDispenser = resolveDispenser {
    _provider.addListener(_onProviderTick);
  }



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
  bool _persistingTx = false;
  bool _unpaidFlowRunning = false; // candado simple anti-paralelo

  // Tracking de contadores acumulados del surtidor para obtener progreso relativo
  double? _dispensedVolume;    // volumen abastecido desde la autorización
  double? _dispensedAmount;    // monto abastecido desde la autorización
  static const double _simulatedFlowRateLitersPerSecond = 0.65; // ~39 L/min
  static const Duration _simulatedFlowTickInterval = Duration(milliseconds: 250);
  Timer? _simulatedFlowTimer;
  DateTime? _simulatedFlowStartedAt;

  bool get loadingLastSale => _loadingLastSale;
  bool get persistingTx => _persistingTx;
  double? get dispensedVolume => _dispensedVolume;
  double? get dispensedAmount => _dispensedAmount;

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

  void selectPosition(PositionPhysical pos) {
    if (selectedHose != null) {
      _provider.removeWatchedHose(selectedHose!.hoseKey);
    }
    selectedPosition = pos;
    selectedHose = null;
    fuel = null;
    preset = PresetInfo.empty();
    tankFull = false;
    amountRequest = null;
    authorizationExpired = false;
    _lastObservedHoseStatus = null;
    _resetTotalsTracking(); // descarta progreso previo al cambiar posición
    _updateStage();
    notifyListeners();
  }

   void setResolver(int? Function(int) r) => _resolveDispenser = r;

  void selectHose({ required PositionPhysical pos, required HosePhysical hose }) {
    if (selectedHose != null) _provider.removeWatchedHose(selectedHose!.hoseKey);
    selectedPosition = pos;
    selectedHose     = hose;
    fuel             = hose.fuel;
    _ensureUnitPriceFromSelection(force: true);
    _provider.addWatchedHose(hose.hoseKey);
    _lastObservedHoseStatus = null;
    _resetTotalsTracking(); // reinicia el tracking cuando se elige una nueva manguera
    _updateStage();
    _onProviderTick(); // primer sync inmediato
    notifyListeners();
  }

  void setInvoiceType(InvoiceType t) {
    invoiceType = t;
    _ensureUnitPriceFromSelection(force: true);
    _updateStage();
    notifyListeners();
  }

  void setPreset(PresetInfo p) {
    preset = p;
    tankFull = false;
    amountRequest = p.kind == PresetKind.amount ? p.amount : null;
    _resetTotalsTracking(); // cualquier cambio de preset invalida la medición previa
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
    if (value) { preset = PresetInfo.empty(); amountRequest = null; }
    _resetTotalsTracking(); // cambia la estrategia del despacho, reinicia tracking
    _updateStage();
    notifyListeners();
  }

  void markReadyToAuthorize() {
    _stopSimulatedFlowTracking();
    _resetTotalsTracking(); // asegura que el próximo conteo empiece en cero
    stage = DispatchStage.readyToAuthorize;
    notifyListeners();
  }

  void markAuthorizing() {
    _stopSimulatedFlowTracking();
    _resetTotalsTracking(); // en authorizing tomamos la primera lectura como baseline
    stage = DispatchStage.authorizing;
    authorizationExpired = false;
    notifyListeners();
  }

  void markAuthorized()  {
    _stopSimulatedFlowTracking();
    stage = DispatchStage.authorized;
    authorizationExpired = false;
    notifyListeners();
  }

  void markDispatching() {
    stage = DispatchStage.dispatching;
    _startSimulatedFlowTracking();
    notifyListeners();
  }

  void markCompleted() {
    _stopSimulatedFlowTracking();
    _cancelFinishTimer();
    stage = DispatchStage.completed;
    if (autoUnwatchOnTerminal) _detachWatcher();
    notifyListeners();
    _provider.removeDispatch(this);
  }

  /// (opcional) si quieres recuperar solo la parte “fetch”
  // void goGetTr() {
  //   _fetchLastSaleIfNeeded();
  //   notifyListeners();
  // }

  /// Mock helper to jump into unpaid stage with a sample console transaction.
  void mockUnpaidState({ConsoleTransaction? transaction}) {
    _cancelAuthLossTimer();
    _cancelFinishTimer();

    final now = DateTime.now();
   
    
    final mockTx = transaction ??
        ConsoleTransaction(
          id: 30,
          fuelingIndex: 258,
          nozzleNumber: selectedHose?.nozzleNumber ?? 4,
          fuelCode: selectedHose?.fuelCode ?? 3,
          fuelTankNumber: selectedHose?.tankNumber ?? 3,
          totalValue: 66500.0,
          totalVolume: 100.0,
          unitPrice: 665.0,
          duration: 60,
          dateTime: now,
          initialTotalizer: 100000,
          finalTotalizer: 100100,
          attendantId: '12909579249690290000',
          attendantIdRaw: 'B32809EE018B2811',
          customerId: 0,
          currentVolume: 10.0,
          saleStatus: 0,
          saleNumber: 0,
          saleId: null,
          reference: null,
          paymentType: null,
          mode: null,
          invoiceType: null,
          epIdEmpresa: 1,
          paymentConfirmed: false,
          createdAt: now,
          userEmail: 'operator@example.com',
          
        );

    consoleTx = mockTx;
    saleId = mockTx.saleId;
    saleNumber = mockTx.saleNumber;
    productId = mockTx.fuelCode;
    amountDispense = mockTx.totalValue;
    volumenDispense = mockTx.totalVolume;
    price = mockTx.unitPrice;
    tx = mockTx.toTransaccion(
      resolveDispenser: _resolveDispenser, 
    );
    authorizationExpired = false;
    stage = DispatchStage.unpaid;
    if (autoUnwatchOnTerminal) _detachWatcher();
    notifyListeners();
  }

  // ================== NUEVO FLUJO ÚNICO ==================
  // SOLO hace fetch y crea tx local si falta. NUNCA postea aquí.
  Future<void> _fetchLastSaleIfNeeded() async {
    if (_loadingLastSale) return;
    final nozzle = selectedHose?.nozzleNumber;
    if (nozzle == null || nozzle == 0) return;

    _loadingLastSale = true;
    notifyListeners(); // “sincronizando...”

    try {
      const maxAttempts = 3;
      const retryDelay = Duration(milliseconds: 1200);
      ConsoleTransaction? fetchedTx;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final resp = await ConsoleApiHelper.getTransactionLastByNozzle(nozzle);
          if (resp.isSuccess && resp.result != null) {
            fetchedTx = resp.result;
            break;
          }
        } catch (_) {
          // intento fallido, se reintenta si quedan intentos
        }

        if (attempt < maxAttempts - 1) {
          await Future.delayed(retryDelay);
        }
      }

      if (fetchedTx != null) {
        consoleTx        = fetchedTx;
        saleId           = consoleTx?.saleId;
        saleNumber       = consoleTx?.saleNumber;
        productId        = consoleTx?.fuelCode;
        amountDispense   = consoleTx?.totalValue;
        volumenDispense  = consoleTx?.totalVolume;
        price            = consoleTx?.unitPrice;

        // ⚠️ Solo crea la Transaccion UNA VEZ; id=0
        tx ??= consoleTx?.toTransaccion(
          resolveDispenser: _resolveDispenser,
        );

        // NO: nada de onLastUnpaid ni POST aquí.
      } else {
        _clearConsoleValues();
      }
    } finally {
      _loadingLastSale = false;
      notifyListeners(); // SIEMPRE notifica al terminar
    }
  }

  // ÚNICO dueño del pipeline unpaid → fetch → persistir
  Future<void> markUnpaid({Duration? delay}) async {
    if (_unpaidFlowRunning) return;
    _unpaidFlowRunning = true;
    _stopSimulatedFlowTracking();

    try {
      if (stage != DispatchStage.unpaid) {
        _cancelFinishTimer();
        stage = DispatchStage.unpaid;
        if (autoUnwatchOnTerminal) _detachWatcher();
        notifyListeners();
      }

      // Delay opcional (default 1800 ms)
      final d = delay ?? const Duration(milliseconds: 1800);
      if (d.inMilliseconds > 0) {
        await Future.delayed(d);
      }

      // 1) Fetch consola (NO postea)
      await _fetchLastSaleIfNeeded();

      

      // 2) Persistir si hay tx (esperar para evitar id=0)
      final t = tx;
      if (t == null) return;

      _persistingTx = true;
      notifyListeners();
      try {
        // (opcional) hook previo si mantienes validaciones
        final hook = onLastUnpaid;
        if (hook != null) {
          await hook(t);
        }

        final saved = await TransaccionesApiHelper.postAndFetchFull(t);
        tx = saved; // ← ya con idtransaccion asignado
      } finally {
        _persistingTx = false;
        notifyListeners();
      }
    } finally {
      _unpaidFlowRunning = false;
      notifyListeners();
    }
  }

  void syncWithHoseStatus() {
    final s = hoseStatus;

    switch (stage) {
      case DispatchStage.authorizing:
        if (s == HoseStatus.authorized) {
          markAuthorized();
        } else if (s == HoseStatus.fueling) {
          markDispatching();
        }
        break;

      case DispatchStage.authorized:
        if (s == HoseStatus.fueling) {
          _cancelAuthLossTimer();
          markDispatching();
        } else if (s != HoseStatus.authorized) {
          _authLossTimer ??= Timer(const Duration(milliseconds: 600), () {
            final ss = hoseStatus;
            final sigueAutorizado = (ss == HoseStatus.authorized || ss == HoseStatus.fueling);
            if (stage == DispatchStage.authorized && !sigueAutorizado) {
              authorizationExpired = true;
              markReadyToAuthorize();
            }
            _authLossTimer = null;
          });
        } else {
          _cancelAuthLossTimer();
        }
        break;

      case DispatchStage.dispatching:
        if (s == HoseStatus.unpaid) {
          _cancelFinishTimer();
          markUnpaid();
          break;
        }
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
          _cancelFinishTimer();
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
    _stopSimulatedFlowTracking();
    consoleTx = null;
    authorizationExpired = false;
    _lastUserIdentifier = null;
    _resetTotalsTracking(); // prepara el control para un uso posterior
    _cancelFinishTimer();
    _detachWatcher();
    selectedPosition = null;
    selectedHose     = null;
    invoiceType      = null;
    preset           = PresetInfo.empty();
    tankFull         = false;
    fuel             = null;
    
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
    _stopSimulatedFlowTracking();
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

  void _resetTotalsTracking() {
    _dispensedVolume = null;
    _dispensedAmount = null;
  }

  void _ensureUnitPriceFromSelection({bool force = false}) {
    final hose = selectedHose;
    if (hose == null) return;
    final candidate = _preferredUnitPriceFor(hose: hose, type: invoiceType);
    if (candidate == null || candidate <= 0) return;
    final current = price?.toDouble() ?? 0;
    if (force || current <= 0) {
      price = candidate;
    }
  }

  double? _preferredUnitPriceFor({required HosePhysical hose, InvoiceType? type}) {
    double? value;
    switch (type) {
      case InvoiceType.credito:
        value = hose.unitPriceCredit?.toDouble();
        break;
      case InvoiceType.peddler:
      case InvoiceType.ticket:
      case InvoiceType.contado:
        value = hose.unitPriceCash?.toDouble();
        break;
      default:
        value = null;
    }
    value ??= hose.unitPriceCash?.toDouble();
    value ??= hose.unitPriceCredit?.toDouble();
    value ??= hose.unitPriceDebit?.toDouble();
    return value;
  }

  void _startSimulatedFlowTracking() {
    if (stage != DispatchStage.dispatching) return;
    if (_simulatedFlowTimer != null) return;
    _simulatedFlowStartedAt ??= DateTime.now();
    _dispensedVolume ??= 0;
    if (_resolveUnitPricePerLiter() != null && _dispensedAmount == null) {
      _dispensedAmount = 0;
    }
    _simulatedFlowTimer = Timer.periodic(_simulatedFlowTickInterval, (_) => _tickSimulatedFlow());
  }

  void _stopSimulatedFlowTracking() {
    _simulatedFlowTimer?.cancel();
    _simulatedFlowTimer = null;
    _simulatedFlowStartedAt = null;
  }

  void _tickSimulatedFlow() {
    if (stage != DispatchStage.dispatching) {
      _stopSimulatedFlowTracking();
      return;
    }
    final start = _simulatedFlowStartedAt;
    if (start == null) return;

    final elapsedSeconds = DateTime.now().difference(start).inMilliseconds / 1000.0;
    var liters = elapsedSeconds * _simulatedFlowRateLitersPerSecond;
    final litersCap = _targetVolumeCapLiters();
    if (litersCap != null && liters > litersCap) {
      liters = litersCap;
    }

    bool changed = false;
    if (_dispensedVolume == null || (_dispensedVolume! - liters).abs() > 0.0001) {
      _dispensedVolume = liters;
      changed = true;
    }

    final unitPrice = _resolveUnitPricePerLiter();
    if (unitPrice != null && unitPrice > 0) {
      var amount = liters * unitPrice;
      final amountCap = amountRequest?.toDouble() ?? preset.amount;
      if (amountCap != null && amount > amountCap) {
        amount = amountCap;
      }
      if (_dispensedAmount == null || (_dispensedAmount! - amount).abs() > 0.01) {
        _dispensedAmount = amount;
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  double? _targetVolumeCapLiters() {
    if (tankFull) return null;
    final presetVolume = preset.isVolume ? preset.volume : null;
    if (presetVolume != null && presetVolume > 0) {
      return presetVolume;
    }

    final unitPrice = _resolveUnitPricePerLiter();
    final amountCap = amountRequest?.toDouble() ?? preset.amount;
    if (unitPrice != null && unitPrice > 0 && amountCap != null && amountCap > 0) {
      return amountCap / unitPrice;
    }
    return null;
  }

  double? _resolveUnitPricePerLiter() {
    if (price != null && price! > 0) {
      return price!.toDouble();
    }
    final hose = selectedHose;
    if (hose == null) return null;

    double? candidate;
    switch (invoiceType) {
      case InvoiceType.credito:
        candidate = hose.unitPriceCredit?.toDouble();
        break;
      case InvoiceType.peddler:
      case InvoiceType.ticket:
      case InvoiceType.contado:
        candidate = hose.unitPriceCash?.toDouble();
        break;
      default:
        candidate = null;
        break;
    }

    candidate ??= hose.unitPriceCash?.toDouble();
    candidate ??= hose.unitPriceCredit?.toDouble();
    candidate ??= hose.unitPriceDebit?.toDouble();
    return candidate;
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

  // Hook opcional (si quieres validaciones previas al POST)
  Future<void> Function(Transaccion tx)? onLastUnpaid;
}

// ====== Enums y modelos de apoyo (igual que antes) ======

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
  final double? amount; // monto
  final double? volume; // litros

  const PresetInfo._({
    required this.manguera,
    required this.kind,
    required this.amount,
    required this.volume,
  });

  factory PresetInfo.amount({ required String manguera, required double amount }) {
    return PresetInfo._(manguera: manguera, kind: PresetKind.amount, amount: amount, volume: null);
  }

  factory PresetInfo.volume({ required String manguera, required double liters }) {
    return PresetInfo._(manguera: manguera, kind: PresetKind.volume, amount: null, volume: liters);
  }

  factory PresetInfo.empty() {
    return const PresetInfo._(manguera: '', kind: PresetKind.amount, amount: null, volume: null);
  }

  bool get hasValidValue =>
      (kind == PresetKind.amount && (amount ?? 0) > 0) ||
      (kind == PresetKind.volume && (volume ?? 0) > 0);

  bool get isAmount => kind == PresetKind.amount;
  bool get isVolume => kind == PresetKind.volume;
}

extension DispatchControlApi on DispatchControl {


  /// Reintenta la autorización usando el último usuario que llamó applyPresetAndAuthorize.
  Future<bool> retryAuthorize() async {
    final uid = _lastUserIdentifier;
    if (uid == null || uid.isEmpty) {
      throw Exception('No hay usuario previo para reintentar');
    }
    return applyPresetAndAuthorize(uid);
  }

  Future<bool> applyPresetAndAuthorize(String userIdentifier) async {
    _lastUserIdentifier = userIdentifier;
    if (selectedHose == null) {
      throw Exception("No hay manguera seleccionada");
    }
    if (!preset.hasValidValue && !tankFull) {
      throw Exception("No hay preset ni tanque lleno definido");
    }

    final nozzle = selectedHose!.nozzleNumber;

    // --- TANQUE LLENO: PostDispenseV2 solo autoriza la máquina ---
    if (tankFull) {
      try {
        final ok = await ConsoleApiHelper.postDispenseV2(nozzle, userIdentifier, authorize: true);
        if (ok) {
          markAuthorized();
          return true;
        } else {
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
    // Truco para probar problema decimales en dispensador

    
    // --- PRESET (monto o volumen): PreDispenseV2 autoriza ---
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
        markReadyToAuthorize();
        return false;
      }
    } catch (_) {
      markReadyToAuthorize();
      return false;
    }
  }
 
 
  void _clearConsoleValues() {
    consoleTx       = null;
    saleId          = null;
    saleNumber      = null;
    productId       = null;
    amountDispense  = null;
    volumenDispense = null;
    price           = null;
  }
}
  
