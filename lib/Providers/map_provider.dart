import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../ViewModels/new_map.dart';
import '../Models/FuelRed/nozzle_mapping.dart';
import '../Models/SignalR/nozzle_status_dto.dart';
import '../ConsoleModels/dispensersstatusresponse.dart';
import '../helpers/api_helper.dart';
import '../helpers/constans.dart';

class MapProvider extends ChangeNotifier {
  // ── Estado público ──────────────────────────────────────────────────────────
  Map<int, PositionPhysical>? _stationMap;
  bool _loading = true;
  String? _error;
  bool _toastShown = false;

  Map<int, PositionPhysical>? get stationMap => _stationMap;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isError => _error != null;
  bool get toastShown => _toastShown;

  // ── SignalR ─────────────────────────────────────────────────────────────────
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ── Caché de mappings (nozzleCode → dispenserNumber) ───────────────────────
  /// Cargados una sola vez desde la API REST al conectar.
  List<NozzleMapping>? _cachedMappings;

  /// Índice rápido: nozzleCode (ej. "01") → NozzleMapping
  // Map<String, NozzleMapping> _mappingByCode = {};

  // ── Visualización en vivo ───────────────────────────────────────────────────
  /// Litros actuales por nozzleCode (solo mangueras activas).
  final Map<String, double> _currentLiters = {};

  /// Monto actual por nozzleCode.
  final Map<String, double?> _currentCash = {};

  /// Estado actual por nozzleCode (persistente entre eventos).
  final Map<String, String> _currentStatus = {};

  /// Tag ID actual por nozzleCode (si existe).
  final Map<String, String?> _currentTags = {};

  // ── Compatibilidad con AltDespachosProvider (stubs vacíos) ─────────────────
  /// Ya no se usa polling, pero se mantienen para no romper código existente.
  void startGlobalPolling({int milliseconds = 500}) {}
  void stopGlobalPolling() {}

  // ── Conexión ────────────────────────────────────────────────────────────────

  /// Conecta al hub SignalR de monitoreo.
  /// Llama esto justo después del login.
  Future<void> connect() async {
    if (_isConnected) return;

    _loading = true;
    _error = null;
    _toastShown = false;
    notifyListeners();

    try {
      // 1. Cargar mappings desde la API REST (solo una vez)
      await _loadMappings();

      // 2. Construir conexión SignalR
      final httpOptions = HttpConnectionOptions(
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      );

      _hubConnection = HubConnectionBuilder()
          .withUrl(Constans.monitoringHubUrl, options: httpOptions)
          .withAutomaticReconnect()
          .build();

      // 3. Registrar handlers de eventos
      _hubConnection!.on('ReceiveStatus', _onReceiveStatus);
      _hubConnection!.on('ReceiveVisualization', _onReceiveVisualization);

      // 4. Manejar cambios de estado de la conexión
      _hubConnection!.onclose(({error}) {
        debugPrint('🔴 [MapProvider] SignalR desconectado: $error');
        _isConnected = false;
        notifyListeners();
      });

      _hubConnection!.onreconnecting(({error}) {
        debugPrint('🟡 [MapProvider] SignalR reconectando...');
        _isConnected = false;
        notifyListeners();
      });

      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('🟢 [MapProvider] SignalR reconectado: $connectionId');
        _isConnected = true;
        notifyListeners();
      });

      // 5. Iniciar conexión
      await _hubConnection!.start();
      _isConnected = true;
      debugPrint(
          '🟢 [MapProvider] SignalR conectado a ${Constans.monitoringHubUrl}');

      // 6. Construir mapa inicial desde los mappings (sin esperar ReceiveStatus)
      //    Así el wizard muestra las posiciones de inmediato.
      _buildInitialMap();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      _isConnected = false;
      debugPrint('❌ [MapProvider] Error al conectar SignalR: $_error');
      notifyListeners();
    }
  }

  /// Desconecta del hub SignalR.
  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
    } catch (_) {}
    _hubConnection = null;
    _isConnected = false;
    debugPrint('⏹️ [MapProvider] SignalR desconectado manualmente');
  }

  // ── Handlers de eventos SignalR ─────────────────────────────────────────────

  /// `ReceiveStatus` — estado de TODAS las mangueras configuradas.
  /// Payload: List<NozzleStatusDto>
  void _onReceiveStatus(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;

    final raw = parameters[0];
    if (raw is! List) return;

    final statuses = raw
        .whereType<Map<String, dynamic>>()
        .map(NozzleStatusDto.fromJson)
        .toList();

    debugPrint('📡 [MapProvider] ReceiveStatus → ${statuses.length} mangueras');

    for (final s in statuses) {
      _currentStatus[s.nozzleCode] = s.status.toStatusString();

      // Si la manguera está disponible, limpiar datos de despacho anterior
      if (s.status == NozzleStatus.available) {
        _currentLiters.remove(s.nozzleCode);
        _currentCash.remove(s.nozzleCode);
        _currentTags.remove(s.nozzleCode);
      }
    }

    _rebuildMap();
  }

  /// `ReceiveVisualization` — datos en vivo de mangueras activas (litros, monto).
  /// Payload: List<NozzleVisualizationDto>
  void _onReceiveVisualization(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;

    final raw = parameters[0];
    if (raw is! List) return;

    final visualizations = raw
        .whereType<Map<String, dynamic>>()
        .map(NozzleVisualizationDto.fromJson)
        .toList();

    debugPrint(
        '📊 [MapProvider] ReceiveVisualization → ${visualizations.length} mangueras activas');

    // Actualizar litros/monto en caché
    // Actualizar cache con datos de visualización
    for (final v in visualizations) {
      _currentLiters[v.nozzleCode] = v.currentLiters;
      _currentCash[v.nozzleCode] = v.currentCash;

      if (v.tagId != null) {
        _currentTags[v.nozzleCode] = v.tagId;
      }

      if (v.status != null) {
        _currentStatus[v.nozzleCode] = v.status!.toStatusString();
      }
    }

    _rebuildMap();
  }

  // ── Construcción del mapa ───────────────────────────────────────────────────

  /// Reconstruye `_stationMap` usando `_cachedMappings` y el estado actual en cache.
  void _rebuildMap() {
    if (_cachedMappings == null || _cachedMappings!.isEmpty) return;

    final Map<int, List<_HoseEntry>> groups = {};

    for (final mapping in _cachedMappings!) {
      final code = _nozzleNumberToCode(mapping.hoseNumber);

      // Estado actual o 'unknown' si no ha llegado nada
      final statusStr = _currentStatus[code] ?? 'unknown';

      final hose = HosePhysical(
        nozzleNumber: mapping.hoseNumber,
        hoseKey: mapping.hoseKey,
        fuel: _resolveFuel(mapping),
        status: statusStr,
        dispenserNumber: mapping.dispenserNumber,
        totalVolume: _currentLiters[code],
        totalAmount: _currentCash[code],
        tagId: _currentTags[code],
      );

      groups
          .putIfAbsent(mapping.dispenserNumber, () => [])
          .add(_HoseEntry(hose: hose, positionPhysical: null));
    }

    // Construir el Map<int, PositionPhysical> final
    final result = <int, PositionPhysical>{};
    var posCounter = 1;
    final sortedIds = groups.keys.toList()..sort();

    for (final dispenserId in sortedIds) {
      final entries = groups[dispenserId]!;
      final hoses = entries.map((e) => e.hose).toList()
        ..sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

      result[posCounter] = PositionPhysical(
        number: posCounter,
        pumpId: dispenserId,
        pumpName: 'Surtidor $dispenserId',
        faceIndex: 1,
        faceLabel: dispenserId.toString(),
        faceDescription: 'Surtidor $dispenserId',
        hoses: List.unmodifiable(hoses),
      );
      posCounter++;
    }

    _stationMap = result;
    _error = null;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Carga los NozzleMappings desde la API REST (solo una vez).
  Future<void> _loadMappings() async {
    if (_cachedMappings != null) return;

    final mappingResp = await ApiHelper.getMapHoseDispenser();
    if (!mappingResp.isSuccess) {
      throw Exception('Error al cargar mappings: ${mappingResp.message}');
    }

    _cachedMappings =
        (mappingResp.result as List<NozzleMapping>? ?? const <NozzleMapping>[]);

    // Construir índice rápido por nozzleCode (ej. "01", "02")

    debugPrint(
        '📋 [MapProvider] Mappings cargados: ${_cachedMappings!.length} mangueras');
  }

  /// Construye el mapa inicial desde los mappings con estado 'unknown'.
  /// Se llama justo después de conectar al hub, antes de recibir el primer
  /// ReceiveStatus. Así el wizard muestra los dispensadores de inmediato.
  void _buildInitialMap() {
    if (_cachedMappings == null || _cachedMappings!.isEmpty) return;
    // Solo construir si aún no hay mapa (no sobreescribir uno ya recibido)
    if (_stationMap != null) return;

    debugPrint(
        '🗺️ [MapProvider] Construyendo mapa inicial desde ${_cachedMappings!.length} mappings');

    final Map<int, List<_HoseEntry>> groups = {};

    for (final mapping in _cachedMappings!) {
      final hose = HosePhysical(
        nozzleNumber: mapping.hoseNumber,
        hoseKey: mapping.hoseKey,
        fuel: const Fuel(name: 'Combustible', color: Colors.teal),
        // Inicializamos como 'available' para no bloquear el flujo
        // hasta que llegue el primer reporte real del hub.
        status: 'available',
        dispenserNumber: mapping.dispenserNumber,
        totalVolume: null,
        totalAmount: null,
      );
      groups
          .putIfAbsent(mapping.dispenserNumber, () => [])
          .add(_HoseEntry(hose: hose, positionPhysical: null));
    }

    final result = <int, PositionPhysical>{};
    var posCounter = 1;
    final sortedIds = groups.keys.toList()..sort();

    for (final dispenserId in sortedIds) {
      final entries = groups[dispenserId]!;
      final hoses = entries.map((e) => e.hose).toList()
        ..sort((a, b) => a.nozzleNumber.compareTo(b.nozzleNumber));

      result[posCounter] = PositionPhysical(
        number: posCounter,
        pumpId: dispenserId,
        pumpName: 'Surtidor $dispenserId',
        faceIndex: 1,
        faceLabel: dispenserId.toString(),
        faceDescription: 'Surtidor $dispenserId',
        hoses: List.unmodifiable(hoses),
      );
      posCounter++;
    }

    _stationMap = result;
    debugPrint('🗺️ [MapProvider] Mapa inicial: ${result.length} posiciones');
    notifyListeners();
  }

  /// Convierte número de manguera (1, 2, 3...) al código de 2 dígitos ("01", "02"...)
  /// que usa el servidor SignalR.
  String _nozzleNumberToCode(int number) => number.toString().padLeft(2, '0');

  /// Devuelve el número de posición asociado a una manguera (por nozzleNumber).
  int? positionIndexForNozzle(int nozzleNumber) {
    final map = _stationMap;
    if (map == null) return null;
    for (final entry in map.entries) {
      if (entry.value.hoses.any((h) => h.nozzleNumber == nozzleNumber)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Marca que ya se mostró el toast inicial.
  void markToastShown() {
    _toastShown = true;
  }

  // ── Reset ───────────────────────────────────────────────────────────────────

  /// Limpia todo el estado y desconecta SignalR.
  /// Llamar al hacer logout.
  /// Limpia todo el estado y desconecta SignalR.
  /// Llamar al hacer logout.
  void reset() {
    disconnect();
    _stationMap = null;
    _loading = true;
    _error = null;
    _toastShown = false;
    _cachedMappings = null;
    _currentLiters.clear();
    _currentCash.clear();
    _currentStatus.clear();
    _cachedMappings = null;
    _currentTags.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  Fuel _resolveFuel(NozzleMapping mapping) {
    // FALLBACK TEMPORAL: Mapeo fijo por número de manguera
    // Asumimos orden: 1=Regular, 2=Super, 3=Diesel
    // El hoseNumber es global (1..32), así que usamos el residuo.
    final index = (mapping.hoseNumber - 1) % 3;

    switch (index) {
      case 0: // 1, 4, 7...
        return const Fuel(name: 'Regular', color: Color(0xFFec1c24)); // Rojo
      case 1: // 2, 5, 8...
        return const Fuel(name: 'Super', color: Color(0xFFb634b8)); // Morado
      case 2: // 3, 6, 9...
        return const Fuel(name: 'Diesel', color: Color(0xFF1dbd4a)); // Verde
      default:
        return const Fuel(name: 'Combustible', color: Colors.teal);
    }
  }
}

// ── Clase auxiliar interna ──────────────────────────────────────────────────

class _HoseEntry {
  final HosePhysical hose;
  final PositionPhysical? positionPhysical;
  _HoseEntry({required this.hose, required this.positionPhysical});
}
