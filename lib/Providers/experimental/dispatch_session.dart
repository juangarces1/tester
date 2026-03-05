import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Models/FuelRed/transaccion.dart';
import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/ViewModels/new_map.dart'
    show Fuel, HosePhysical, PositionPhysical;

// ---------------------------------------------------------------------------
// ENUMS & HELPERS
// ---------------------------------------------------------------------------

enum InvoiceType {
  contado,
  ticket,
  credito,
  peddler;
}

enum PresetKind { amount, volume }

class PresetInfo {
  final PresetKind? kind;
  final double? amount;
  final double? volume;

  const PresetInfo._({this.kind, this.amount, this.volume});

  factory PresetInfo.empty() => const PresetInfo._();

  factory PresetInfo.amount(double amount) =>
      PresetInfo._(kind: PresetKind.amount, amount: amount);

  factory PresetInfo.volume(double liters) =>
      PresetInfo._(kind: PresetKind.volume, volume: liters);

  bool get hasValidValue =>
      (kind == PresetKind.amount && (amount ?? 0) > 0) ||
      (kind == PresetKind.volume && (volume ?? 0) > 0);

  bool get isAmount => kind == PresetKind.amount;
  bool get isVolume => kind == PresetKind.volume;
}

// ---------------------------------------------------------------------------
// DispatchSession
// ---------------------------------------------------------------------------

/// Representa una intención de despacho creada desde el Wizard.
/// El estado de la manguera se refleja directamente desde SignalR
/// a través de [currentStatus]. La flag [hasFueled] indica si la manguera
/// pasó por el estado [fueling] al menos una vez.
class DispatchSession {
  final String id;

  // -- Información base
  final PositionPhysical position;
  final HosePhysical hose;
  final String nozzleCode; // Formato "01", "02" usado por el mapa y API
  final Fuel fuel;

  // -- Configuración del usuario
  InvoiceType invoiceType;
  final PresetInfo preset;
  final bool isTankFull;
  final String userIdentifier;

  // -- FuelRed P4S (si viene de una orden de flotilla)
  final int? fuelRedTxId;
  final Map<String, dynamic>? metadata;
  bool get isFuelRed => fuelRedTxId != null;

  // -- Estado real de SignalR (fuente de verdad)
  NozzleStatus currentStatus;

  /// true si la manguera pasó por [NozzleStatus.fueling] al menos una vez.
  /// Una vez true, nunca vuelve a false.
  bool hasFueled = false;

  /// true si la manguera pasó por [NozzleStatus.ready] (se levantó/calling).
  /// Distingue "recién autorizado" de "preset expiró sin despachar".
  bool hasBeenActivated = false;

  /// Timestamp de cuando la manguera entró a fueling.
  /// Se usa para consultar la consola por transacciones con fecha mayor a este momento.
  DateTime? fuelingStartedAt;

  /// Último momento en que se envió progreso WS al backend.
  /// Se usa para throttlear a ~2 s.
  DateTime? lastProgressSent;

  /// Últimos datos conocidos capturados durante el fueling (antes de que
  /// MapProvider los limpie al pasar a available).
  double? lastVolume;
  double? lastAmount;
  String? lastTag;

  /// true mientras `_processCompletedDispatch` corre en background.
  bool _syncing = false;
  bool get isSyncing => _syncing;

  /// true cuando la sesión fue resuelta (sincronizada con consola o descartada).
  bool _settled = false;
  bool get isSettled => _settled;

  /// true cuando el usuario cerró/facturó la sesión desde la UI.
  bool _completed = false;
  bool get isCompleted => _completed;

  // -- Transacción Final Resultante (se llena en backend)
  Transaccion? dbTransaction;
  ConsoleTransaction? consoleTransaction;

  /// Producto devuelto por la consola tras sincronizar el despacho.
  /// Viene ya listo para agregar a una factura.
  Product? syncedProduct;

  DispatchSession({
    required this.id,
    required this.position,
    required this.hose,
    required this.fuel,
    required this.invoiceType,
    required this.preset,
    required this.isTankFull,
    required this.userIdentifier,
    this.currentStatus = NozzleStatus.blocked,
    this.fuelRedTxId,
    this.metadata,
  }) : nozzleCode = hose.nozzleNumber.toString().padLeft(2, '0');

  // -- Helpers de estado derivado --

  /// La manguera terminó y hubo despacho -> necesita sincronización/facturación.
  /// Permanece true mientras no se haya cerrado/facturado (`_completed`).
  bool get needsSettlement =>
      hasFueled &&
      (currentStatus == NozzleStatus.available ||
          currentStatus == NozzleStatus.blocked) &&
      !_completed;

  /// La manguera se activó (ready) pero volvió a reposo SIN despachar.
  /// Requiere [hasBeenActivated] para distinguir de "recién autorizado".
  bool get canRetryOrDiscard =>
      !hasFueled &&
      hasBeenActivated &&
      !_settled &&
      (currentStatus == NozzleStatus.available ||
          currentStatus == NozzleStatus.blocked);

  /// La manguera está activamente despachando.
  bool get isDispensing => currentStatus == NozzleStatus.fueling;

  /// La sesión está esperando que la manguera avance en su ciclo.
  /// Mutuamente excluyente con [canRetryOrDiscard].
  bool get isWaiting =>
      !_settled &&
      !hasFueled &&
      !canRetryOrDiscard;

  /// Marca la sesión como resuelta (sincronizada o descartada).
  void markAsSettled() {
    _settled = true;
    _syncing = false;
  }

  /// Marca que el proceso de sincronización inició.
  void startSyncing() {
    _syncing = true;
  }

  /// Marca que el sync falló (agotó intentos o error).
  /// Permite reintentar desde la UI.
  void syncFailed() {
    _syncing = false;
  }

  /// Marca este despacho como completamente cerrado (facturado y terminado).
  void markAsFinished() {
    _completed = true;
    _settled = true;
  }
}
