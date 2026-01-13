// lib/providers/map_provider.dart
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
  List<NozzleMapping>?
      _cachedMappings; // 👈 NUEVO: Caché de la configuración física

  Map<int, PositionPhysical>? get stationMap => _stationMap;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isError => _error != null; // 👈 NUEVO
  bool get toastShown => _toastShown; // 👈 NUEVO

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

  /// NUEVO MÉTODO SIMPLIFICADO: Carga mapa usando solo estados y mappings cacheados.
  Future<void> loadMapDirect() async {
    _loading = true;
    _error = null;
    _toastShown = false;
    notifyListeners();

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
      final statuses = await ConsoleApiHelper.getDispensersStatus();

      // OPT: Si la lista de estados está vacía (aunque sea 200 OK),
      // es probable que sea un estado transitorio del backend o error de comunicación.
      // No actualizamos para mantener la última vista válida.
      if (statuses.isEmpty) {
        debugPrint(
            '[MapProvider] Statuses empty, skipping update to preserve last state.');
        return;
      }

      // 3. Reconstruir mapa usando la lógica directa (sin PumpData)
      _stationMap = PositionBuilder.buildDirect(
        statuses: statuses,
        mappings: _cachedMappings!,
      );
    } catch (e) {
      _error = e.toString();
      // IMPORTANTE: Al no limpiar _stationMap aquí, la UI conserva
      // lo último que se cargó correctamente (resiliencia).
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
