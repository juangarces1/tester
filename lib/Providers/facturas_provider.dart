// lib/Providers/facturas_provider.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as context;
import 'package:provider/provider.dart';

import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/cierrefinal.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/empleado.dart';
import 'package:tester/Models/paid.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/Models/sinpe.dart';
import 'package:tester/Models/transferencia.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';

// Si quieres usar el enum para setear flags:
import 'package:tester/ViewModels/dispatch_control.dart' show InvoiceType;

class FacturasProvider with ChangeNotifier {
  final List<Invoice> _facturas = <Invoice>[];

  /// Lista de solo lectura para la UI
  UnmodifiableListView<Invoice> get facturas =>
      UnmodifiableListView(_facturas);

  int get count => _facturas.length;

  /// Agrega una factura existente y devuelve el índice donde quedó.
  int addInvoice(Invoice nuevaFactura) {
    _facturas.add(nuevaFactura);
    notifyListeners();
    return _facturas.length - 1;
  }

  void removeInvoice(Invoice factura) {
    _facturas.remove(factura);
    notifyListeners();
  }

  void updateInvoice(int index, Invoice facturaActualizada) {
    if (index >= 0 && index < _facturas.length) {
      _facturas[index] = facturaActualizada;
      notifyListeners();
    }
  }

  /// Obtiene por índice; si no existe, devuelve una factura "vacía" (no la agrega).
  Invoice getInvoiceByIndex(int index) {
    if (index >= 0 && index < _facturas.length) return _facturas[index];
    return _buildEmptyInvoice();
  }

  // ---------------------------------------------------------------------------
  // NUEVO: crear facturas fácilmente
  // ---------------------------------------------------------------------------

  /// Crea una nueva factura **sin** agregarla a la lista.
  /// Puedes pasar el [type] (InvoiceType de DispatchControl) para setear los flags,
  /// y/o un [cliente] inicial si ya lo tienes.
  Invoice newInvoice({InvoiceType? type, Cliente? cliente, CierreFinal? cierre, Empleado? empleado}) {
    final inv = _buildEmptyInvoice(cliente: cliente, cierre: cierre, empleado: empleado);
    _applyInvoiceTypeFlags(inv, type);
    return inv;
  }

  /// Crea una nueva factura, la **agrega** a la lista y devuelve el **índice**.
  int addNewInvoice({InvoiceType? type, Cliente? cliente}) {
    final inv = newInvoice(type: type, cliente: cliente);
    return addInvoice(inv);
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  Invoice _buildEmptyInvoice({Cliente? cliente, CierreFinal? cierre, Empleado? empleado}) {
    final clienteVacio = cliente ?? _emptyCliente();

    

    return Invoice(
      kms: 0,
      observaciones: '',
      placa: '',
      detail: const [],      // ajusta si necesitas lista mutable
      empleado: empleado,
      cierre: cierre,
      formPago: Paid(
        totalEfectivo: 0,
        totalBac: 0,
        totalDav: 0,
        totalBn: 0,
        totalSctia: 0,
        totalDollars: 0,
        totalCheques: 0,
        totalCupones: 0,
        totalPuntos: 0,
        totalTransfer: 0,
        showTotal: false,
        showFact: false,
        totalSinpe: 0,
        clienteFactura: clienteVacio,
        clientePuntos: clienteVacio,
        transfer: Transferencia(
          cliente: clienteVacio,
          transfers: const [],
          monto: 0,
          totalTransfer: 0,
        ),
        sinpe: Sinpe(
          id: 0,
          numComprobante: '',
          nota: '',
          idCierre: 0,
          nombreEmpleado: '',
          fecha: DateTime.now(),
          numFact: '',
          activo: 1,
          monto: 0,
        ),
      ),
      isCredit: false,
      isPeddler: false,
      isProcess: false,
      isTicket: false,
      isContado: false,
      isPromo: false,
      peddler: Peddler(placa: '', km: '', chofer: '', observaciones: '', orden: ''),
    );
  }

  Cliente _emptyCliente() => Cliente(
        nombre: '',
        documento: '',
        codigoTipoID: '',
        email: '',
        puntos: 0,
        codigo: '',
        telefono: '',
      );

  void _applyInvoiceTypeFlags(Invoice invoice, InvoiceType? type) {
    if (type == null) return;
    invoice.isContado = type == InvoiceType.contado;
    invoice.isTicket  = type == InvoiceType.ticket;
    invoice.isCredit  = type == InvoiceType.credito;
    invoice.isPeddler = type == InvoiceType.peddler;
    // Si tu modelo Invoice tiene un campo enum propio, mejor guarda también:
    // invoice.invoiceType = type;
  }
}
