import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:tester/Models/transaccion.dart'; // ajusta el path

class TransaccionesProvider extends ChangeNotifier {
  final List<Transaccion> _items = [];

  // Vista de solo lectura para UI
  UnmodifiableListView<Transaccion> get items => UnmodifiableListView(_items);
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  // ------------------- Escritura / Mutación -------------------

  /// Reemplaza toda la lista.
  void setAll(Iterable<Transaccion> list) {
    _items
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  /// Agrega si no existe, si existe por idtransaccion lo reemplaza (upsert).
  void upsert(Transaccion t) {
    final idx = _indexOfId(t.idtransaccion);
    if (idx >= 0) {
      _items[idx] = t;
    } else {
      _items.add(t);
    }
    notifyListeners();
  }

  void replaceZeroWith(Transaccion serverTx) {
  // por si acaso: no reemplaces con otro 0
  if (serverTx.idtransaccion <= 0) return;

  final idx = _items.indexWhere((t) => t.idtransaccion == 0);
  if (idx == -1) return; // nada que reemplazar

  _items[idx] = serverTx;
  notifyListeners();
}


  /// Inserta/actualiza varias a la vez (1 solo notify).
  void upsertAll(Iterable<Transaccion> list) {
    bool changed = false;
    for (final t in list) {
      final idx = _indexOfId(t.idtransaccion);
      if (idx >= 0) {
        _items[idx] = t;
      } else {
        _items.add(t);
      }
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Agrega si NO existe; si existe, no hace nada.
  bool addIfAbsent(Transaccion t) {
    final exists = _indexOfId(t.idtransaccion) >= 0;
    if (exists) return false;
    _items.add(t);
    notifyListeners();
    return true;
  }

  /// Actualiza por id con una función mutadora.
  bool updateById(int id, Transaccion Function(Transaccion current) updater) {
    final idx = _indexOfId(id);
    if (idx < 0) return false;
    _items[idx] = updater(_items[idx]);
    notifyListeners();
    return true;
  }

  /// Cambia estado por id.
  bool setEstado(int id, String estado) {
    final idx = _indexOfId(id);
    if (idx < 0) return false;
    _items[idx].estado = estado;
    notifyListeners();
    return true;
  }

  /// Marca facturada ('S' por defecto).
  bool markFacturada(int id, {String value = 'S'}) {
    final idx = _indexOfId(id);
    if (idx < 0) return false;
    _items[idx].facturada = value;
    notifyListeners();
    return true;
  }

  /// Elimina por id.
  bool removeById(int id) {
    final idx = _indexOfId(id);
    if (idx < 0) return false;
    _items.removeAt(idx);
    notifyListeners();
    return true;
  }

  /// Elimina según condición.
  int removeWhere(bool Function(Transaccion t) test) {
    final before = _items.length;
    _items.removeWhere(test);
    final removed = before - _items.length;
    if (removed > 0) notifyListeners();
    return removed;
  }

  /// Limpia todo.
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  // ------------------- Lectura / Consultas -------------------

  Transaccion? getById(int id) {
    final idx = _indexOfId(id);
    return idx >= 0 ? _items[idx] : null;
  }

  List<Transaccion> byEstado(String estado) =>
      _items.where((t) => t.estado.toLowerCase() == estado.toLowerCase()).toList();

  List<Transaccion> byCierre(int idCierre) =>
      _items.where((t) => t.idcierre == idCierre).toList();

  List<Transaccion> get unpaid =>
      _items.where((t) => t.estado.toLowerCase() == 'unpaid').toList();

  int get totalColones =>
      _items.fold<int>(0, (sum, t) => sum + (t.total));

  double get totalVolumen =>
      _items.fold<double>(0.0, (sum, t) => sum + (t.volumen));

  // ------------------- Utilidades -------------------

  /// Ordena por fecha (String) intentando parsear a DateTime.
  void sortByFecha({bool descending = true}) {
    int cmp(Transaccion a, Transaccion b) {
      final da = DateTime.tryParse(a.fechatransaccion);
      final db = DateTime.tryParse(b.fechatransaccion);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    }

    _items.sort(cmp);
    if (descending) {
      _items.setAll(0, _items.reversed);
    }
    notifyListeners();
  }

  /// Dedup por idtransaccion conservando el último elemento visto.
  void deduplicateKeepingLast() {
    final map = <int, Transaccion>{};
    for (final t in _items) {
      map[t.idtransaccion] = t;
    }
    if (map.length != _items.length) {
      _items
        ..clear()
        ..addAll(map.values);
      notifyListeners();
    }
  }

  // ------------------- Privados -------------------
  int _indexOfId(int id) => _items.indexWhere((e) => e.idtransaccion == id);
}
