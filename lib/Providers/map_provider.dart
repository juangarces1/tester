import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../ViewModels/new_map.dart';
import '../Models/FuelRed/nozzle_mapping.dart';
import '../Models/SignalR/nozzle_status_dto.dart';
import '../helpers/api_helper.dart';
import '../helpers/console_api_helper.dart';
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

  // ── Precios de Combustible ──────────────────────────────────────────────────
  /// Precios cargados al iniciar sesión (ej: "super": 750, "regular": 730)
  Map<String, double> _fuelPrices = {};

  /// Devuelve el precio por litro del producto especificado (por nombre).
  double getPriceForFuel(String grade) =>
      _fuelPrices[grade.toLowerCase()] ?? 0.0;

  // ── Visualización en vivo ───────────────────────────────────────────────────
  /// Litros actuales por nozzleCode (solo mangueras activas).
  final Map<String, double> _currentLiters = {};

  /// Monto actual por nozzleCode.
  final Map<String, double?> _currentCash = {};

  /// Estado actual por nozzleCode (persistente entre eventos).
  final Map<String, String> _currentStatus = {};

  /// Tag ID actual por nozzleCode (si existe).
  final Map<String, String?> _currentTags = {};

  /// nozzleCode → nombre de combustible (para calcular litros desde monto).
  final Map<String, String> _nozzleFuelIndex = {};

  // -- Getters públicos para estado individual en vivo --
  double? getLiters(String nozzleCode) => _currentLiters[nozzleCode];
  double? getCash(String nozzleCode) => _currentCash[nozzleCode];
  String? getTag(String nozzleCode) => _currentTags[nozzleCode];
  String? getStatus(String nozzleCode) => _currentStatus[nozzleCode];

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
      await _loadFuelPrices();

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

    // Actualizar litros/monto en caché
    // Actualizar cache con datos de visualización
    for (final v in visualizations) {
      // Multiplicar el cash por 100 tal como requiere el hardware
      final cash = v.currentCash != null ? v.currentCash! * 100 : null;
      _currentCash[v.nozzleCode] = cash;

      // El hardware solo manda monto, no litros.
      // Calcular litros = monto / precio_por_litro.
      if (v.currentLiters > 0) {
        _currentLiters[v.nozzleCode] = v.currentLiters;
      } else if (cash != null && cash > 0) {
        final fuelName = _nozzleFuelIndex[v.nozzleCode];
        final price = fuelName != null ? getPriceForFuel(fuelName) : 0.0;
        _currentLiters[v.nozzleCode] = price > 0 ? cash / price : 0;
      }

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

      final fuel = _resolveFuel(mapping);
      final price = getPriceForFuel(fuel.name);

      final hose = HosePhysical(
        nozzleNumber: mapping.hoseNumber,
        hoseKey: code,
        fuel: fuel,
        status: statusStr,
        dispenserNumber: mapping.dispenserNumber,
        unitPriceCash: price > 0 ? price : null,
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

    // Construir índice nozzleCode → fuelName para calcular litros
    _nozzleFuelIndex.clear();
    for (final m in _cachedMappings!) {
      final code = _nozzleNumberToCode(m.hoseNumber);
      _nozzleFuelIndex[code] = _resolveFuel(m).name;
    }

    debugPrint(
        '📋 [MapProvider] Mappings cargados: ${_cachedMappings!.length} mangueras');
  }

  /// Carga el catálogo de precios de combustible.
  /// Intenta primero desde Console API (/api/Prices/current, requiere auth),
  /// con fallback al endpoint legacy (/api/Shifts/GetFuelPrices, sin auth).
  Future<void> _loadFuelPrices() async {
    // Intentar Console API (8087) con auth
    final consolePrices = await ConsoleApiHelper.getCurrentPrices();
    if (consolePrices.isNotEmpty) {
      _fuelPrices = consolePrices;
      debugPrint('💰 [MapProvider] Precios cargados desde Console API: $_fuelPrices');
      return;
    }

    // Fallback al endpoint legacy (puerto 80, sin auth)
    final resp = await ApiHelper.getFuelPrices();
    if (!resp.isSuccess) {
      debugPrint('⚠️ [MapProvider] Error al cargar precios: ${resp.message}');
      return;
    }

    final Map<String, double> rawPrices =
        resp.result as Map<String, double>? ?? {};
    _fuelPrices =
        rawPrices.map((key, value) => MapEntry(key.toLowerCase(), value));

    debugPrint('💰 [MapProvider] Precios cargados desde legacy API: $_fuelPrices');
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
      final code = _nozzleNumberToCode(mapping.hoseNumber);
      final fuel = _resolveFuel(mapping);
      final price = getPriceForFuel(fuel.name);

      final hose = HosePhysical(
        nozzleNumber: mapping.hoseNumber,
        hoseKey: code,
        fuel: fuel,
        status: 'available',
        dispenserNumber: mapping.dispenserNumber,
        unitPriceCash: price > 0 ? price : null,
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

  Fuel _resolveFuel(NozzleMapping mapping) {
    final grade = mapping.grade.toLowerCase();
    if (grade.contains('regular')) {
      return const Fuel(name: 'Regular', color: Color(0xFFec1c24));
    } else if (grade.contains('super')) {
      return const Fuel(name: 'Super', color: Color(0xFFb634b8));
    } else if (grade.contains('diesel')) {
      return const Fuel(name: 'Diesel', color: Color(0xFF1dbd4a));
    } else if (grade.contains('exonerado')) {
      return const Fuel(name: 'Exonerado', color: Color(0xFF0078D4));
    }
    // Fallback: usar el grade tal cual viene del backend
    return Fuel(name: mapping.grade.isNotEmpty ? mapping.grade : 'Combustible',
        color: Colors.teal);
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
    _nozzleFuelIndex.clear();
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
}

// ── Clase auxiliar interna ──────────────────────────────────────────────────

class _HoseEntry {
  final HosePhysical hose;
  final PositionPhysical? positionPhysical;
  _HoseEntry({required this.hose, required this.positionPhysical});
}
