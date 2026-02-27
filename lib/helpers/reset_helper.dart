// lib/helpers/reset_helper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importa todos tus providers
import 'package:tester/Providers/usuario_provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/tranascciones_provider.dart';

import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Providers/map_provider.dart';
import 'package:tester/Providers/printer_provider.dart';
import 'package:tester/Providers/faces_provider.dart';

/// Helper seguro para limpiar todos los providers.
/// Puedes llamarlo desde logout, restart o cambio de estación.
class ResetHelper {
  static void resetAll(BuildContext context) {
    _tryRead<UsuarioProvider>(context)?.reset();
    _tryRead<CierreActivoProvider>(context)?.reset();
    _tryRead<TransaccionesProvider>(context)?.reset();
    _tryRead<FacturasProvider>(context)?.reset();
    _tryRead<ClienteProvider>(context)?.reset();
    _tryRead<MapProvider>(context)?.reset();
    _tryRead<PrinterProvider>(context)?.reset();
    _tryRead<FacesProvider>(context)?.reset();
  }

  // Evita errores si algún provider no está montado en el árbol
  static T? _tryRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}
