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
  bool   _toastShown  = false; 

  Map<int, PositionPhysical>? get stationMap => _stationMap;
  bool   get isLoading   => _loading;
  String? get error      => _error;
  bool   get isError     => _error != null; // 👈 NUEVO
  bool   get toastShown  => _toastShown;    // 👈 NUEVO

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
    _stationMap = null;
    _toastShown = false;
    notifyListeners();

    try {
      final pumps = await ConsoleApiHelper.getPumpsAndFaces();
      final statuses = await ConsoleApiHelper.getDispensersStatus();
      final mappingResp = await ApiHelper.getMapHoseDispenser();
      if (!mappingResp.isSuccess) {
        throw Exception(mappingResp.message);
      }

      final mappings = (mappingResp.result as List<NozzleMapping>? ?? const <NozzleMapping>[]);
      _stationMap = PositionBuilder.build(
        pumps: pumps,
        statuses: statuses,
        mappings: mappings,
        strictPhysicalOnly: strictPhysicalOnly,
      );
    } catch (e) {
       _error      = e.toString();
      _stationMap = null;
    }

    _loading = false;
    notifyListeners();

  }

      // Dentro de MapProvider
    void reset() {
      _stationMap = null;   // Limpia el mapa cargado
      _loading = true;      // Marca como pendiente de carga
      _error = null;        // Borra mensajes de error
      _toastShown = false;  // Permite que vuelva a mostrarse el toast inicial
      notifyListeners();    // Notifica a la UI
    }


}
