import 'package:flutter/material.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';

typedef UnpaidPredicate = bool Function(ConsoleTransaction tx);

class TransactionsProvider extends ChangeNotifier {
  final Map<int, ConsoleTransaction> _byId = <int, ConsoleTransaction>{};

  // ✅ selección efímera local (antes: _authorizedIds)
  final Set<int> _selectedIds = <int>{};

  final UnpaidPredicate _isUnpaid;
  final int? _maxSelected; // opcional, para limitar selección múltiple

  TransactionsProvider({
    UnpaidPredicate? unpaidPredicate,
    Iterable<ConsoleTransaction>? initialItems,
    int? maxSelected, // p.ej. 3 si solo cobras hasta 3 a la vez
  })  : _isUnpaid = unpaidPredicate ?? ((tx) => tx.saleStatus == 0 && !tx.paymentConfirmed),
        _maxSelected = maxSelected {
    if (initialItems != null) upsertAll(initialItems);
  }

  // ---------- helpers
  static int _cmpDesc(ConsoleTransaction a, ConsoleTransaction b) {
    final t = b.dateTime.compareTo(a.dateTime);
    return t != 0 ? t : b.id.compareTo(a.id);
  }
  List<ConsoleTransaction> _sorted(Iterable<ConsoleTransaction> it) {
    final list = it.toList()..sort(_cmpDesc);
    return list;
  }

  // ---------- derivados
  List<ConsoleTransaction> get all => _sorted(_byId.values);
  List<ConsoleTransaction> get unpaid => _sorted(_byId.values.where(_isUnpaid));

  // ✅ seleccionados
  bool isSelected(int id) => _selectedIds.contains(id);
  List<ConsoleTransaction> get selected =>
      _sorted(_selectedIds.map((id) => _byId[id]).whereType<ConsoleTransaction>());
  List<ConsoleTransaction> get selectedUnpaid => _sorted(selected.where(_isUnpaid));

  int get countAll => _byId.length;
  int get countUnpaid => unpaid.length;
  int get countSelected => _selectedIds.length;
  int get countSelectedUnpaid => selectedUnpaid.length;

  // ---------- mutaciones base
  void replaceAll(Iterable<ConsoleTransaction> items) {
    _byId
      ..clear()
      ..addEntries(items.map((e) => MapEntry(e.id, e)));
    _selectedIds.removeWhere((id) => !_byId.containsKey(id));
    notifyListeners();
  }

  void upsert(ConsoleTransaction tx) {
    _byId[tx.id] = tx;
    _pruneSelectionIfNotUnpaid(tx.id);
    notifyListeners();
  }

  void upsertAll(Iterable<ConsoleTransaction> items) {
    for (final tx in items) {
      _byId[tx.id] = tx;
      _pruneSelectionIfNotUnpaid(tx.id);
    }
    notifyListeners();
  }

  void removeById(int id) {
    _byId.remove(id);
    _selectedIds.remove(id);
    notifyListeners();
  }

  void clear() {
    _byId.clear();
    _selectedIds.clear();
    notifyListeners();
  }

  // ---------- selección efímera
  void setSelected(int id, bool selected) {
    if (!_byId.containsKey(id)) return;

    if (selected) {
      // opcional: solo permitir seleccionar si está impaga
      if (!_isUnpaid(_byId[id]!)) return;

      if (_maxSelected != null && _selectedIds.length >= _maxSelected) {
        // estrategia: dejar solo el más reciente + el nuevo
        // o sencillamente ignorar; aquí uso "selectOnly" si max=1
        if (_maxSelected == 1) {
          _selectedIds
            ..clear()
            ..add(id);
        } else {
          // quita el más antiguo de la selección
          final toRemove = _sorted(_selectedIds
              .map((x) => _byId[x])
              .whereType<ConsoleTransaction>()).reversed.skip(_maxSelected - 1);
          for (final old in toRemove) {
            _selectedIds.remove(old.id);
          }
          _selectedIds.add(id);
        }
      } else {
        _selectedIds.add(id);
      }
    } else {
      _selectedIds.remove(id);
    }
    notifyListeners();
  }

  void toggleSelected(int id) =>
      setSelected(id, !_selectedIds.contains(id));

  void selectOnly(int id) {
    if (!_byId.containsKey(id)) return;
    _selectedIds
      ..clear()
      ..add(id);
    notifyListeners();
  }

  void selectMany(Iterable<int> ids) {
    for (final id in ids) {
      if (_byId.containsKey(id) && _isUnpaid(_byId[id]!)) {
        _selectedIds.add(id);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void selectWhere(bool Function(ConsoleTransaction tx) test) {
    _selectedIds
      ..clear()
      ..addAll(_byId.values.where(test).map((e) => e.id));
    notifyListeners();
  }

  // ---------- updates frecuentes
  void markPaymentConfirmed(int id, {bool value = true}) {
    final cur = _byId[id];
    if (cur == null) return;
    _byId[id] = cur.copyWith(paymentConfirmed: value);
    _pruneSelectionIfNotUnpaid(id);
    notifyListeners();
  }

  void updateStatus(
    int id, {
    int? saleStatus,
    bool? paymentConfirmed,
    String? saleId,
    int? saleNumber,
  }) {
    final cur = _byId[id];
    if (cur == null) return;
    _byId[id] = cur.copyWith(
      saleStatus: saleStatus ?? cur.saleStatus,
      paymentConfirmed: paymentConfirmed ?? cur.paymentConfirmed,
      saleId: saleId ?? cur.saleId,
      saleNumber: saleNumber ?? cur.saleNumber,
    );
    _pruneSelectionIfNotUnpaid(id);
    notifyListeners();
  }

  // ---------- filtros ad-hoc
  List<ConsoleTransaction> filter(bool Function(ConsoleTransaction) test) =>
      _sorted(_byId.values.where(test));

  // ---------- housekeeping
  void _pruneSelectionIfNotUnpaid(int id) {
    final tx = _byId[id];
    if (tx == null) {
      _selectedIds.remove(id);
      return;
    }
    if (!_isUnpaid(tx)) _selectedIds.remove(id);
  }

  // ---------- (opcional) alias compatibles con el código anterior
  bool isAuthorized(int id) => isSelected(id);
  List<ConsoleTransaction> get authorized => selected;
  List<ConsoleTransaction> get authorizedUnpaid => selectedUnpaid;
  int get countAuthorized => countSelected;
  int get countAuthorizedUnpaid => countSelectedUnpaid;
  void setAuthorized(int id, bool authorized) => setSelected(id, authorized);
  void toggleAuthorized(int id) => toggleSelected(id);
}
