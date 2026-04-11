// lib/Models/SignalR/nozzle_status_dto.dart

/// Estado numérico de una manguera tal como lo envía el servidor SignalR.
/// Los valores deben coincidir con el enum del servidor.
enum NozzleStatus {
  notConfigured, // 0 - Sin hardware asignado
  available, // 1 - Libre, en reposo
  blocked, // 2 - Bloqueada, requiere autorización
  fueling, // 3 - Abasteciendo
  ready, // 4 - Manguera levantada (Calling)
  waiting, // 5 - Espera validación
  failure, // 6 - Error comunicación
  busy, // 7 - Ocupado (otro bico)
  error, // 8 - Error genérico
  unknown; // fallback

  static NozzleStatus fromInt(int value) {
    switch (value) {
      case 0:
        return NozzleStatus.notConfigured;
      case 1:
        return NozzleStatus.available;
      case 2:
        return NozzleStatus.blocked;
      case 3:
        return NozzleStatus.fueling;
      case 4:
        return NozzleStatus.ready;
      case 5:
        return NozzleStatus.waiting;
      case 6:
        return NozzleStatus.failure;
      case 7:
        return NozzleStatus.busy;
      case 8:
        return NozzleStatus.error;
      default:
        return NozzleStatus.unknown;
    }
  }

  static NozzleStatus fromString(String value) {
    switch (value.toLowerCase()) {
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

  /// Convierte al string de estado que ya usa el resto de la app
  String toStatusString() {
    switch (this) {
      case NozzleStatus.notConfigured:
        return 'unavailable';
      case NozzleStatus.available:
        return 'available';
      case NozzleStatus.blocked:
        return 'blocked';
      case NozzleStatus.fueling:
        return 'fueling';
      case NozzleStatus.ready:
        return 'calling'; // "Llamando" / Requesting Auth
      case NozzleStatus.waiting:
        return 'waiting';
      case NozzleStatus.failure:
        return 'error'; // Mapeamos ambos errores al mismo string UI si se desea
      case NozzleStatus.busy:
        return 'busy';
      case NozzleStatus.error:
        return 'error';
      case NozzleStatus.unknown:
        return 'unknown';
    }
  }
}

/// Payload del evento `ReceiveStatus` — estado de todas las mangueras configuradas.
class NozzleStatusDto {
  final String nozzleCode; // "01", "02", etc.
  final NozzleStatus status;

  const NozzleStatusDto({
    required this.nozzleCode,
    required this.status,
  });

  factory NozzleStatusDto.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['Status'];
    final status = rawStatus is int
        ? NozzleStatus.fromInt(rawStatus)
        : NozzleStatus.unknown;

    final code = json['nozzleCode'] ?? json['NozzleCode'] as String? ?? '';

    return NozzleStatusDto(
      nozzleCode: code.trim(),
      status: status,
    );
  }
}

/// Payload del evento `ReceiveVisualization` — datos en vivo de mangueras activas.
class NozzleVisualizationDto {
  final String nozzleCode;
  final double currentLiters;
  final double? currentCash;
  final NozzleStatus?
      status; // Puede venir nulo si solo envía datos de visualización
  final String? tagId;

  const NozzleVisualizationDto({
    required this.nozzleCode,
    required this.currentLiters,
    this.currentCash,
    this.status,
    this.tagId,
  });

  factory NozzleVisualizationDto.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['Status'];
    final status = rawStatus is int ? NozzleStatus.fromInt(rawStatus) : null;

    final code = json['nozzleCode'] ?? json['NozzleCode'] as String? ?? '';
    final liters = json['currentLiters'] ?? json['CurrentLiters'] as num? ?? 0;
    final cash = json['currentCash'] ?? json['CurrentCash'] as num?;
    final tag = json['tagId'] ?? json['TagId'] as String?;

    return NozzleVisualizationDto(
      nozzleCode: code.trim(),
      currentLiters: liters.toDouble(),
      currentCash: cash?.toDouble(),
      status: status,
      tagId: tag,
    );
  }
}
