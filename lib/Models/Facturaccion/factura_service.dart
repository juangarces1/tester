import 'package:flutter/material.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:provider/provider.dart';

class FacturaService {
  static void updateFactura(BuildContext context, Invoice factura) {
    var facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
    int index = facturasProvider.facturas.indexOf(factura);
    if (index != -1) {
      // Realiza cambios en `factura` si es necesario
      facturasProvider.updateInvoice(index, factura);
    }
  }

   static void eliminarFactura(BuildContext context, Invoice factura) {
    var facturasProvider = Provider.of<FacturasProvider>(context, listen: false);
    int index = facturasProvider.facturas.indexOf(factura);
    if (index != -1) {
      // Realiza cambios en `factura` si es necesario
      facturasProvider.removeInvoice(factura);
    }
  }
}
