import 'package:flutter/foundation.dart';
import 'package:tester/clases/q3_printer.dart';

class PrinterProvider extends ChangeNotifier {
  bool _isBound = false;
  bool get isBound => _isBound;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> init() async {
    _isBound = await Q3Printer.bind();
    notifyListeners();
  }

  Future<bool> ensureBound() async {
    if (_isBound) return true;
    _isBound = await Q3Printer.bind();
    notifyListeners();
    return _isBound;
  }

  /// Ejecuta una acción garantizando exclusión mutua (busy = true/false)
  Future<T?> runLocked<T>(Future<T> Function() action) async {
    if (_busy) return null; // ya está ocupado, ignoramos
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
