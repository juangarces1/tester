import 'package:flutter/material.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/experimental/alt_dispatch_control.dart';
import 'package:tester/Providers/dispatch_control.dart' show DispatchStage;
import 'package:tester/ViewModels/new_map.dart';

/// Este Provider es el encargado de agrupar los despachos y sincronizarlos con el mapa.
class AltDespachosProvider extends ChangeNotifier {
  final MapProvider mapProvider;
  final List<AltDispatchControl> _despachos = [];

  AltDespachosProvider({required this.mapProvider}) {
    // Escuchamos al MapProvider. Cada vez que él cargue el mapa, nosotros reaccionamos.
    mapProvider.addListener(_onMapUpdate);
  }

  List<AltDispatchControl> get despachos => List.unmodifiable(_despachos);

  void refresh() => notifyListeners();

  AltDispatchControl? getById(String id) {
    for (final d in _despachos) {
      if (d.id == id) return d;
    }
    return null;
  }

  void removeById(String id) {
    final d = getById(id);
    if (d != null) removeDispatch(d);
  }

  void addDispatch(AltDispatchControl d) {
    _despachos.add(d);
    _onMapUpdate();
    _syncPollingInterval();
    notifyListeners();
  }

  void removeDispatch(AltDispatchControl d) {
    _despachos.remove(d);
    _syncPollingInterval();
    notifyListeners();
  }

  void _syncPollingInterval() {
    // Estados que requieren polling activo
    const activeStages = {
      DispatchStage.idle,
      DispatchStage.hoseSelected,
      DispatchStage.readyToAuthorize,
      DispatchStage.authorizing,
      DispatchStage.authorized,
      DispatchStage.dispatching,
      // unpaid y completed NO necesitan polling
    };

    // Verificamos si hay al menos un despacho en estado activo
    final hasActiveDispatch =
        _despachos.any((d) => activeStages.contains(d.stage));

    if (hasActiveDispatch) {
      // Hay actividad: Polling SECUENCIAL (500ms delay entre requests)
      mapProvider.startGlobalPolling(milliseconds: 500);
    } else {
      // Solo despachos en 'completed' o lista vacía: Parada total
      mapProvider.stopGlobalPolling();
    }
  }

  /// Función CRUCIAL: Se ejecuta cada vez que el MapProvider termina de pedir los estados al API.
  void _onMapUpdate() {
    final map = mapProvider.stationMap;
    if (map == null) return;

    // Buscamos cada manguera de nuestros despachos activos dentro del mapa fresco
    for (var dispatch in _despachos) {
      if (dispatch.selectedHose == null) continue;

      // Buscamos la manguera en el mapa por su Nozzle Number o Hose Key
      HosePhysical? matchingHose;

      for (var pos in map.values) {
        for (var h in pos.hoses) {
          if (h.nozzleNumber == dispatch.selectedHose!.nozzleNumber) {
            matchingHose = h;
            break;
          }
        }
        if (matchingHose != null) break;
      }

      // Le pasamos el estado actualizado al despacho
      if (matchingHose != null) {
        dispatch.updateFromMap(matchingHose);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    mapProvider.removeListener(_onMapUpdate);
    super.dispose();
  }
}
