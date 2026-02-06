import 'dart:async';
import 'package:flutter/material.dart';
import '../ViewModels/new_map.dart';
import '../Models/FuelRed/nozzle_mapping.dart';
import '../helpers/api_helper.dart';
import '../helpers/console_api_helper.dart';

class MapProvider extends ChangeNotifier {
  Map<int, PositionPhysical>? _stationMap;
  bool _loading = true;
  String? _error;
  bool _toastShown = false;
  List<NozzleMapping>? _cachedMappings;

  Timer? _pollingTimer;
  bool _isPollingActive = false;

  Map<int, PositionPhysical>? get stationMap => _stationMap;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isError => _error != null;
  bool get toastShown => _toastShown;

  // ========== CONTADORES DE MONITOREO ==========
  int _pollAttempts = 0; // Cuántas veces intentamos pollear
  int _pollSuccess = 0; // Cuántas veces el API respondió OK
  int _pollErrors = 0; // Cuántas veces falló
  int _pollEmptyResponses = 0; // Cuántas veces respondió vacío

  int get pollAttempts => _pollAttempts;
  int get pollSuccess => _pollSuccess;
  int get pollErrors => _pollErrors;
  int get pollEmptyResponses => _pollEmptyResponses;

  void resetCounters() {
    _pollAttempts = 0;
    _pollSuccess = 0;
    _pollErrors = 0;
    _pollEmptyResponses = 0;
  }
  // ============================================

  int? _currentPollingMs;
  bool _stopPollingRequested = false;

  /// Inicia polling SECUENCIAL: espera que termine cada request antes de iniciar el siguiente.
  /// Esto evita acumulación de requests cuando el servidor es lento.
  void startGlobalPolling({int milliseconds = 500}) {
    if (_isPollingActive) return; // Ya hay un loop corriendo

    _isPollingActive = true;
    _stopPollingRequested = false;
    _currentPollingMs = milliseconds;

    // Iniciar loop secuencial
    _runSequentialPolling(milliseconds);
  }

  /// Loop secuencial: await cada request, repite inmediatamente.
  /// SIN DELAY: apenas termina uno, inicia el siguiente para mantener conexión caliente.
  Future<void> _runSequentialPolling(int delayMs) async {
    debugPrint('🔄 [MapProvider] Iniciando polling SECUENCIAL CONTINUO');

    while (_isPollingActive && !_stopPollingRequested) {
      await loadMapDirect(); // Espera a que termine
      // SIN DELAY: inicia el siguiente inmediatamente
    }

    debugPrint('⏹️ [MapProvider] Polling SECUENCIAL detenido');
  }

  void stopGlobalPolling() {
    _stopPollingRequested = true;
    _pollingTimer?.cancel();
    _isPollingActive = false;
    _currentPollingMs = null;
  }

  /// ALTERNATIVO: Inicia polling usando /api/Connector/Statuses
  /// Usar para probar si este endpoint es más estable.
  /// SIN CANDADO - permite peticiones concurrentes para mantener conexión activa
  void startConnectorPolling({int milliseconds = 1000}) {
    if (_isPollingActive && _currentPollingMs == milliseconds) return;

    _pollingTimer?.cancel();
    _currentPollingMs = milliseconds;
    _isPollingActive = true;

    _pollingTimer =
        Timer.periodic(Duration(milliseconds: milliseconds), (timer) {
      // SIN CANDADO: siempre dispara el poll
      loadMapFromConnector();
    });

    // Carga inmediata al iniciar
    loadMapFromConnector();
  }

  /// Marca que ya lanzamos el toast para no repetirlo en cada rebuild.
  void markToastShown() {
    _toastShown = true;
  }

  /// Devuelve el número de posición (o dispensador) asociado a una manguera.
  int? positionIndexForNozzle(int nozzleNumber) {
    final map = _stationMap;
    if (map == null) return null;

    for (final entry in map.entries) {
      final hoses = entry.value.hoses;
      final match = hoses.any((hose) => hose.nozzleNumber == nozzleNumber);
      if (match) {
        return entry.key; // o entry.value.number, son iguales
      }
    }
    return null;
  }

  Future<void> loadMap({bool strictPhysicalOnly = false}) async {
    _loading = true;
    _error = null;
    // No borramos _stationMap aquí para evitar saltos en la UI durante el polling
    _toastShown = false;
    notifyListeners();

    try {
      final pumps = await ConsoleApiHelper.getPumpsAndFaces();
      final statuses = await ConsoleApiHelper.getDispensersStatus();
      final mappingResp = await ApiHelper.getMapHoseDispenser();
      if (!mappingResp.isSuccess) {
        throw Exception(mappingResp.message);
      }

      final mappings = (mappingResp.result as List<NozzleMapping>? ??
          const <NozzleMapping>[]);
      _stationMap = PositionBuilder.build(
        pumps: pumps,
        statuses: statuses,
        mappings: mappings,
        strictPhysicalOnly: strictPhysicalOnly,
      );
    } catch (e) {
      _error = e.toString();
      _stationMap = null;
    }

    _loading = false;
    notifyListeners();
  }

  /// MÉTODO SIMPLIFICADO: Carga mapa usando solo estados y mappings cacheados.
  /// SIN CANDADO: permite peticiones concurrentes
  Future<void> loadMapDirect() async {
    // SIN CANDADO: no bloqueamos peticiones concurrentes

    _pollAttempts++;
    debugPrint('📡 [MapProvider] Poll #$_pollAttempts iniciando...');

    final isFirstLoad = _stationMap == null;

    // Solo mostramos loading si es la primera carga
    if (isFirstLoad) {
      _loading = true;
      _error = null;
      _toastShown = false;
      notifyListeners();
    }

    try {
      // 1. Cargar mappings solo si no están en caché
      if (_cachedMappings == null) {
        final mappingResp = await ApiHelper.getMapHoseDispenser();
        if (!mappingResp.isSuccess) {
          throw Exception('Error al cargar mappings: ${mappingResp.message}');
        }
        _cachedMappings = (mappingResp.result as List<NozzleMapping>? ??
            const <NozzleMapping>[]);
      }

      // 2. Cargar estados (siempre necesario para tiempo real)
      final stopwatch = Stopwatch()..start();
      final statuses = await ConsoleApiHelper.getDispensersStatus();
      stopwatch.stop();
      final responseTimeMs = stopwatch.elapsedMilliseconds;

      // Si la lista de estados está vacía
      if (statuses.isEmpty) {
        _pollEmptyResponses++;
        debugPrint(
            '⚠️ [MapProvider] Poll #$_pollAttempts → VACÍO en ${responseTimeMs}ms (total vacíos: $_pollEmptyResponses)');
        _loading = false;
        return;
      }

      // 3. Reconstruir mapa
      _stationMap = PositionBuilder.buildDirect(
        statuses: statuses,
        mappings: _cachedMappings!,
      );
      _error = null;
      _pollSuccess++;

      // Log de éxito con resumen de estados
      final statusSummary =
          statuses.take(5).map((s) => '${s.number}:${s.status}').join(', ');
      debugPrint(
          '✅ [MapProvider] Poll #$_pollAttempts → OK en ${responseTimeMs}ms (${statuses.length} dispensers) [$statusSummary${statuses.length > 5 ? '...' : ''}]');
      debugPrint(
          '   📊 Stats: OK=$_pollSuccess, ERR=$_pollErrors, VACÍO=$_pollEmptyResponses | ⏱️ Response: ${responseTimeMs}ms');
    } catch (e) {
      _pollErrors++;
      _error = e.toString();
      debugPrint('❌ [MapProvider] Poll #$_pollAttempts → ERROR: $_error');
      debugPrint(
          '   📊 Stats: OK=$_pollSuccess, ERR=$_pollErrors, VACÍO=$_pollEmptyResponses');
    }

    _loading = false;
    notifyListeners();
  }

  /// MÉTODO ALTERNATIVO: Usa /api/Connector/Statuses
  /// Cada 3 elementos del array corresponden a 1 dispensador.
  /// Ej: [0-2] = Disp 1, [3-5] = Disp 2, etc.
  /// SIN CANDADO: permite peticiones concurrentes
  Future<void> loadMapFromConnector() async {
    // SIN CANDADO: no bloqueamos peticiones concurrentes

    _pollAttempts++;
    debugPrint('📡 [MapProvider/Connector] Poll #$_pollAttempts iniciando...');

    final isFirstLoad = _stationMap == null;

    if (isFirstLoad) {
      _loading = true;
      _error = null;
      _toastShown = false;
      notifyListeners();
    }

    try {
      // 1. Cargar mappings solo si no están en caché
      if (_cachedMappings == null) {
        final mappingResp = await ApiHelper.getMapHoseDispenser();
        if (!mappingResp.isSuccess) {
          throw Exception('Error al cargar mappings: ${mappingResp.message}');
        }
        _cachedMappings = (mappingResp.result as List<NozzleMapping>? ??
            const <NozzleMapping>[]);
      }

      // 2. Cargar estados del endpoint alternativo
      final stopwatch = Stopwatch()..start();
      final statuses = await ConsoleApiHelper.getConnectorStatuses();
      stopwatch.stop();
      final responseTimeMs = stopwatch.elapsedMilliseconds;

      if (statuses.isEmpty) {
        _pollEmptyResponses++;
        debugPrint(
            '⚠️ [MapProvider/Connector] Poll #$_pollAttempts → VACÍO en ${responseTimeMs}ms');
        _loading = false;
        return;
      }

      // 3. Mapear: cada 3 statuses = 1 dispensador
      // El índice de la manguera es 1-based (1, 2, 3, 4, ...)
      final result = <int, PositionPhysical>{};
      const hosesPerDispenser = 3;
      final dispenserCount = (statuses.length / hosesPerDispenser).ceil();

      for (var dispIdx = 0; dispIdx < dispenserCount; dispIdx++) {
        final dispenserNumber = dispIdx + 1;
        final hoses = <HosePhysical>[];

        for (var hoseIdx = 0; hoseIdx < hosesPerDispenser; hoseIdx++) {
          final globalIndex = dispIdx * hosesPerDispenser + hoseIdx;
          if (globalIndex >= statuses.length) break;

          final status = statuses[globalIndex];
          final nozzleNumber = globalIndex + 1; // 1-based

          // Buscar mapping para este nozzle si existe
          final mapping = _cachedMappings?.firstWhere(
            (m) => m.hoseNumber == nozzleNumber,
            orElse: () => NozzleMapping(
              id: nozzleNumber, // ID ficticio usando nozzleNumber
              hoseNumber: nozzleNumber,
              hoseKey: 'H$nozzleNumber',
              dispenserNumber: dispenserNumber,
            ),
          );

          hoses.add(HosePhysical(
            nozzleNumber: nozzleNumber,
            hoseKey: mapping?.hoseKey ?? 'H$nozzleNumber',
            fuel: const Fuel(name: 'Combustible', color: Colors.teal),
            status: status,
            dispenserNumber: dispenserNumber,
          ));
        }

        if (hoses.isNotEmpty) {
          result[dispenserNumber] = PositionPhysical(
            number: dispenserNumber,
            pumpId: dispenserNumber,
            pumpName: 'Surtidor $dispenserNumber',
            faceIndex: 1,
            faceLabel: dispenserNumber.toString(),
            faceDescription: 'Surtidor $dispenserNumber',
            hoses: List.unmodifiable(hoses),
          );
        }
      }

      _stationMap = result;
      _error = null;
      _pollSuccess++;

      // Log de éxito
      final statusSummary = statuses.take(6).join(', ');
      debugPrint(
          '✅ [MapProvider/Connector] Poll #$_pollAttempts → OK en ${responseTimeMs}ms (${statuses.length} hoses, ${result.length} dispensers)');
      debugPrint(
          '   📊 Statuses: [$statusSummary${statuses.length > 6 ? '...' : ''}]');
      debugPrint(
          '   📊 Stats: OK=$_pollSuccess, ERR=$_pollErrors, VACÍO=$_pollEmptyResponses | ⏱️ Response: ${responseTimeMs}ms');
    } catch (e) {
      _pollErrors++;
      _error = e.toString();
      debugPrint(
          '❌ [MapProvider/Connector] Poll #$_pollAttempts → ERROR: $_error');
      debugPrint(
          '   📊 Stats: OK=$_pollSuccess, ERR=$_pollErrors, VACÍO=$_pollEmptyResponses');
    }

    _loading = false;
    notifyListeners();
  }

  // Dentro de MapProvider
  void reset() {
    _stationMap = null; // Limpia el mapa cargado
    _loading = true; // Marca como pendiente de carga
    _error = null; // Borra mensajes de error
    _toastShown = false; // Permite que vuelva a mostrarse el toast inicial
    _cachedMappings = null; // 👈 También limpiamos caché si se resetea todo
    notifyListeners(); // Notifica a la UI
  }
}
