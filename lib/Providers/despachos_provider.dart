// lib/Providers/despachos_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/helpers/console_api_helper.dart';

enum HoseStatus { available, authorized, busy, fueling, unpaid, stopped, unknown, finished }

class DespachosProvider extends ChangeNotifier {
  final List<DispatchControl> _despachos = [];
  final Set<String> _watchedHoses = {};
  final Map<String, HoseStatus> _hoseStatuses = {};
  final Map<String, String> _hoseRaw = {};

  Timer? _pollTimer;
  bool _busy = false;
  bool _disposed = false;

  Duration _interval = const Duration(seconds: 2);
  final Duration _okInterval = const Duration(seconds: 2);
  final Duration _errorInterval = const Duration(seconds: 8);
  bool _lastTickFailed = false;

  List<DispatchControl> get despachos => List.unmodifiable(_despachos);
  HoseStatus? getHoseStatus(String hoseId) => _hoseStatuses[hoseId];
  String? getHoseRawStatus(String hoseId) => _hoseRaw[hoseId];
  bool get isPolling => _pollTimer != null;

  String getHoseDisplayLabel(String hoseKey) {
    final st = _hoseStatuses[hoseKey];
    final raw = _hoseRaw[hoseKey];
    switch (st) {
      case HoseStatus.available:  return 'Disponible';
      case HoseStatus.authorized: return 'Autorizada';
      case HoseStatus.busy:       return 'Ocupada';
      case HoseStatus.fueling:    return 'Despachando';
      case HoseStatus.unpaid:     return 'Pendiente de pago';
      case HoseStatus.stopped:    return 'Detenida';
      case HoseStatus.finished:   return 'Finalizado'; // compat
      case HoseStatus.unknown:
      default: return _beautifyRaw(raw) ?? 'Estado desconocido';
    }
  }


  void _onChildChanged() {
    // Cada vez que cambie cualquier DispatchControl, esto obliga a FirstPage a reconstruirse
    notifyListeners();
  }
  void addDispatch(DispatchControl d) {
    _despachos.add(d);
    final hoseKey = d.selectedHose?.hoseKey;
    if (hoseKey != null) addWatchedHose(hoseKey);
     d.addListener(_onChildChanged);
    _safeNotify();
  }

 

  void removeDispatch(DispatchControl d) {
    d.dispose();          // cancela timers + quita watcher + removeListener(...)
    _despachos.remove(d); // sácalo de tu colección
    d.removeListener(_onChildChanged);
    _safeNotify();
}

  DispatchControl? getById(String id) {
    for (final d in _despachos) { if (d.id == id) return d; }
    return null;
  }

  void refresh() => _safeNotify();

  void clearAll() {
    _despachos.clear();
    _watchedHoses.clear();
    _hoseStatuses.clear();
    _hoseRaw.clear();
    _stopPolling();
    _safeNotify();
  }

  void addWatchedHose(String hoseKey) {
    if (_watchedHoses.add(hoseKey)) {
      if (_pollTimer == null) {
        _startPolling();
      } else {
        pollNow();
      }
    }
  }

  void removeWatchedHose(String hoseKey) {
    _watchedHoses.remove(hoseKey);
    _hoseStatuses.remove(hoseKey);
    _hoseRaw.remove(hoseKey);
    if (_watchedHoses.isEmpty) _stopPolling();
    _safeNotify();
  }

  void replaceWatchedHose(String oldKey, String newKey) {
    if (oldKey == newKey) return;
    removeWatchedHose(oldKey);
    addWatchedHose(newKey);
  }

  Future<void> pollNow() async => _tick();

  void _startPolling() {
    _pollTimer = Timer.periodic(_interval, (_) => _tick());
    pollNow();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _restartPollingWith(Duration interval) {
    _interval = interval;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_busy || _watchedHoses.isEmpty) return;
    _busy = true;

    try {
      final allDispensers = await ConsoleApiHelper.getDispensersStatus();
      final seen = <String>{};
      bool changed = false;

      for (final disp in allDispensers) {
        for (final hose in disp.hoses) {
          final key = hose.key;
          if (!_watchedHoses.contains(key)) continue;
          seen.add(key);

          final raw = _extractRawStatus(hose.status);
          if (_hoseRaw[key] != raw) { _hoseRaw[key] = raw; changed = true; }

          final parsed = _parseStatus(raw);
          if (_hoseStatuses[key] != parsed) { _hoseStatuses[key] = parsed; changed = true; }
        }
      }

      for (final key in _watchedHoses) {
        if (!seen.contains(key)) {
          if (_hoseStatuses[key] != HoseStatus.unknown) { _hoseStatuses[key] = HoseStatus.unknown; changed = true; }
          if (_hoseRaw.containsKey(key)) { _hoseRaw.remove(key); changed = true; }
        }
      }

      if (changed) _safeNotify();

      if (_lastTickFailed && _interval != _okInterval) {
        _lastTickFailed = false;
        _restartPollingWith(_okInterval);
      } else {
        _lastTickFailed = false;
      }
    } catch (e) {
      if (!_lastTickFailed || _interval != _errorInterval) {
        _lastTickFailed = true;
        _restartPollingWith(_errorInterval);
      }
    } finally {
      _busy = false;
    }
  }

  String _extractRawStatus(dynamic status) {
    if (status == null) return '';
    if (status is String) return status;
    if (status is Enum) return status.name;
    final s = status.toString();           // p.ej. "Status.fueling"
    final parts = s.split('.');
    return parts.isNotEmpty ? parts.last : s;
  }

  HoseStatus _parseStatus(String raw) {
    final token = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (token) {
      case 'available':  return HoseStatus.available;
      case 'authorized': return HoseStatus.authorized;
      case 'fueling':    return HoseStatus.fueling;
      case 'unpaid':     return HoseStatus.unpaid;
      case 'stopped':    return HoseStatus.stopped;
      case 'busy':       return HoseStatus.busy;
      case 'finished':   return HoseStatus.finished; // por compatibilidad si algún día aparece
      default:           return HoseStatus.unknown;
    }
  }

  String? _beautifyRaw(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final cleaned = s.replaceAll(RegExp(r'[_\\-\\.]+'), ' ').trim();
    return cleaned
        .split(RegExp(r'\\s+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _safeNotify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
