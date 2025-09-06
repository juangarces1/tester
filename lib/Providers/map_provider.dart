// lib/providers/map_provider.dart
import 'package:flutter/material.dart';
import '../ViewModels/new_map.dart';
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

  Future<void> loadMap() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final pumps = await ConsoleApiHelper.getPumpsAndFaces();
      final statuses = await ConsoleApiHelper.getDispensersStatus();
      _stationMap = PositionBuilder.build(pumps: pumps, statuses: statuses);
    } catch (e) {
       _error      = e.toString();
      _stationMap = null;
    }

    _loading = false;
    notifyListeners();

  }
}
