class TestPrint {
  // final BluePrintPos _bluetooth = BluePrintPos.instance;
  // final BlueDevice device;

  // TestPrint({required this.device});

  // Future<void> sample() async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;

  //   final section = ReceiptSectionText();
  //   section.addText(
  //     'ESTACION SAN GERARDO',
  //     size: ReceiptTextSizeType.extraLarge,
  //     style: ReceiptTextStyleType.bold,
  //     alignment: ReceiptAlignment.center,
  //   );
  //   section.addText(
  //     'GRUPO POJI S.A.',
  //     size: ReceiptTextSizeType.extraLarge,
  //     style: ReceiptTextStyleType.bold,
  //     alignment: ReceiptAlignment.center,
  //   );
  //   section.addSpacer();

  //   await _bluetooth.printReceiptText(
  //     section,
  //     useCut: true,
  //     feedCount: 2,
  //     useRaster: false,
  //   );
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printFactura(Factura fac, String tipoDoc, String tipoCliente) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;

  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(fac.fechaHoraTrans);
  //   final section = ReceiptSectionText();
  //   section.addText('ESTACION SAN GERARDO',
  //       size: ReceiptTextSizeType.large,
  //       style: ReceiptTextStyleType.bold,
  //       alignment: ReceiptAlignment.center);
  //   section.addText('GRUPO POJI S.A.',
  //       size: ReceiptTextSizeType.large,
  //       style: ReceiptTextStyleType.bold,
  //       alignment: ReceiptAlignment.center);
  //   section.addSpacer();

  //   section.addLeftRightText('Ced Jur:', '3-101-110670');
  //   section.addText('Chomes, Puntarenas', alignment: ReceiptAlignment.center);
  //   section.addText('100 mts sur de la CCSS', alignment: ReceiptAlignment.center);
  //   section.addText('info@estacionsangerardo.com', alignment: ReceiptAlignment.center);
  //   section.addSpacer();

  //   section.addText(tipoDoc, alignment: ReceiptAlignment.center);
  //   section.addText(fac.clave!.substring(21, 40), alignment: ReceiptAlignment.center);
  //   section.addSpacer();

  //   section.addLeftRightText('CLAVE', fac.clave!);
  //   section.addLeftRightText('Factura:', fac.nFactura);
  //   section.addSpacer();

  //   section.addLeftRightText(
  //     'Forma Pago:',
  //     tipoCliente == 'CONTADO' ? 'Contado' : 'Crédito',
  //   );
  //   section.addLeftRightText('Fecha:', fmt);
  //   section.addLeftRightText('Pistero:', fac.usuario.toString());
  //   section.addSpacer();

  //   if (tipoDoc != 'TICKET') {
  //     section.addText('Cliente: ${fac.cliente}');
  //     section.addText('# Identificación: ${fac.identificacion}');
  //     section.addText('Tel: ${fac.telefono}');
  //     section.addText('Email: ${fac.email}');
  //     section.addSpacer();
  //   }

  //   if ((fac.nPlaca ?? '').isNotEmpty) {
  //     section.addText('Placa: ${fac.nPlaca}');
  //   }
  //   if ((fac.kilometraje ?? 0) > 0) {
  //     section.addText('Kilometraje: ${fac.kilometraje}');
  //   }
  //   if ((fac.observaciones ?? '').isNotEmpty) {
  //     section.addText('Obs: ${fac.observaciones}');
  //   }
  //   section.addSpacer();

  //   section.addText('Detalle', alignment: ReceiptAlignment.center);
  //   for (final d in fac.detalles) {
  //     section.addText(d.detalle);
  //     // Simple 3‑column emulado
  //     final sTot = NumberFormat('###,###.00', 'en_US').format(d.subtotal);
  //     final pUnit = NumberFormat('###,###', 'en_US').format(d.precioUnit);
  //     section.addText('$sTot   $pUnit   ${d.cantidad}');
  //   }
  //   section.addSpacer();

  //   section.addLeftRightText(
  //       'Subtotal:', NumberFormat('###,###.00', 'en_US').format(fac.montoFactura));
  //   section.addLeftRightText(
  //       'Grabado:', NumberFormat('###,###.00', 'en_US').format(fac.totalGravado));
  //   section.addLeftRightText(
  //       'Exento:', NumberFormat('###,###.00', 'en_US').format(fac.totalExento));
  //   section.addLeftRightText(
  //       'Impuestos:', NumberFormat('###,###.00', 'en_US').format(fac.totalImpuesto));
  //   section.addLeftRightText(
  //       'Descuentos:', NumberFormat('###,###.00', 'en_US').format(fac.totalDescuento));
  //   section.addSpacer();

  //   section.addLeftRightText(
  //     'Total:',
  //     NumberFormat('###,###.00', 'en_US').format(fac.totalFactura),
  //     leftSize: ReceiptTextSizeType.extraLarge,
  //   );
  //   section.addSpacer();
  //   section.addText(
  //     'Autorizado mediante resolución DGT-R-48-2016',
  //     alignment: ReceiptAlignment.left,
  //   );
  //   section.addSpacer(count: 2);

  //   if (tipoCliente == 'CREDITO') {
  //     section.addText('Firma Cliente:', alignment: ReceiptAlignment.left);
  //     section.addSpacer(count: 4);
  //     section.addText('__________________________',
  //         alignment: ReceiptAlignment.center);
  //     section.addSpacer();
  //   }

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printPuntosCanje(
  //     String cliente, String pistero, int acumulados, String doc, double canje) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;

  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  //   final pts = NumberFormat('###,###', 'en_US').format(canje.round());
  //   final saldo = NumberFormat('###,###', 'en_US').format(acumulados - canje.round());

  //   final section = ReceiptSectionText()
  //     ..addText('CANJE PUNTOS', alignment: ReceiptAlignment.center)
  //     ..addText('Fecha: $fmt')
  //     ..addText('Pistero: $pistero')
  //     ..addSpacer()
  //     ..addLeftRightText('Cliente:', cliente)
  //     ..addLeftRightText('Ptos Canjeados:', pts)
  //     ..addLeftRightText('Doc #:', doc)
  //     ..addLeftRightText('Saldo:', saldo)
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('_______________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printPuntosAcumulados(
  //     String cliente, String pistero, String doc, List<Product> productos) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;

  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  //   final totalLitros =
  //       productos.fold<double>(0, (sum, p) => sum + p.cantidad);
  //   final puntos = (totalLitros.round() * 10).toString();

  //   final section = ReceiptSectionText()
  //     ..addText('ACUMULACIÓN DE PUNTOS', alignment: ReceiptAlignment.center)
  //     ..addText('Fecha: $fmt')
  //     ..addText('Pistero: $pistero')
  //     ..addSpacer()
  //     ..addLeftRightText('Cliente:', cliente)
  //     ..addText('Tr#   Comb.   Lts') // encabezado
  //     ..addSpacer(useDashed: true);

  //   for (final p in productos) {
  //     section.addText(
  //         '${p.transaccion}   ${p.detalle}   ${p.cantidad.toString()}');
  //   }

  //   section
  //     ..addSpacer()
  //     ..addLeftRightText('Puntos Totales:', puntos)
  //     ..addLeftRightText('Doc #:', doc)
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('__________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printTransferencia(Transferencia tr, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('TRANSFERENCIA', alignment: ReceiptAlignment.center)
  //     ..addText('Fecha: $fmt')
  //     ..addSpacer()
  //     ..addText('Cliente: ${tr.transfers.first.cliente}')
  //     ..addSpacer();

  //   for (final t in tr.transfers) {
  //     section
  //       ..addLeftRightText('# Depósito:', t.numeroDeposito.toString())
  //       ..addLeftRightText('Cuenta:', t.cuenta.toString())
  //       ..addLeftRightText('Aplicado:', t.aplicado.toString())
  //       ..addLeftRightText('Saldo:', t.saldo.toString())
  //       ..addText('-----------------------------');
  //   }

  //   section
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printSinpe(Sinpe sp, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('SINPE', alignment: ReceiptAlignment.center)
  //     ..addText('Fecha: $fmt')
  //     ..addLeftRightText('Num:', sp.numComprobante)
  //     ..addLeftRightText('Monto:', sp.monto.toString())
  //     ..addSpacer();

  //   if ((sp.nota ?? '').isNotEmpty) {
  //     section.addText('Nota: ${sp.nota}');
  //   }

  //   section
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('___________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printCashBack(Cashback cb, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;

  //   final section = ReceiptSectionText()
  //     ..addText('CashBack', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', cb.fechacashback.toString())
  //     ..addLeftRightText(
  //         'Monto:', NumberFormat('###,##0.##', 'en_US').format(cb.monto))
  //     ..addSpacer()
  //     ..addText('Firma Recibido:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('_________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printPeddler(Peddler pd) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  //   final totalLts =
  //       pd.products!.fold<double>(0, (sum, p) => sum + p.cantidad);

  //   final section = ReceiptSectionText()
  //     ..addText('ORDEN DESPACHO', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', fmt)
  //     ..addLeftRightText('Pistero:', pd.pistero.toString())
  //     ..addText('Cliente: ${pd.cliente?.nombre ?? ""}')
  //     ..addText('#ID: ${pd.cliente?.documento}')
  //     ..addText('Email: ${pd.cliente?.email}')
  //     ..addSpacer()
  //     ..addText('Detalle:', alignment: ReceiptAlignment.center);

  //   for (final p in pd.products!) {
  //     section
  //       ..addText('Tr#: ${p.transaccion}')
  //       ..addText('${p.detalle}  Lts: ${p.cantidad}')
  //       ..addText('-----------------------------');
  //   }

  //   section
  //     ..addLeftRightText('Total Lts:', totalLts.toString())
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('__________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printCierreDatafono(CierreDatafono cd, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('CIERRE DATAFONO', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', fmt)
  //     ..addLeftRightText('Cierre #:', cd.idcierredatafono.toString())
  //     ..addLeftRightText('Monto:', NumberFormat('###,##0.##', 'en_US').format(cd.monto))
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('_________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printViatico(Viatico v, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('VIATICO', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', fmt)
  //     ..addLeftRightText('Placa:', v.placa ?? '')
  //     ..addLeftRightText(
  //         'Monto:', NumberFormat('###,##0.##', 'en_US').format(v.monto))
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('_________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printDeposito(Deposito dp, String pistero) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('DEPOSITO', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', fmt)
  //     ..addLeftRightText('Moneda:', dp.moneda ?? '')
  //     ..addLeftRightText(
  //         'Monto:', NumberFormat('###,##0.##', 'en_US').format(dp.monto))
  //     ..addSpacer()
  //     ..addText('Firma Cliente:', alignment: ReceiptAlignment.left)
  //     ..addSpacer(count: 4)
  //     ..addText('_________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }

  // Future<void> printTransaccion(Product pr) async {
  //   final status = await _bluetooth.connect(device);
  //   if (status != ConnectionStatus.connected) return;
  //   final fmt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  //   final section = ReceiptSectionText()
  //     ..addText('TRANSACCIÓN', alignment: ReceiptAlignment.center)
  //     ..addLeftRightText('Fecha:', fmt)
  //     ..addText('Trans #: ${pr.transaccion}')
  //     ..addText('Combustible: ${pr.detalle}')
  //     ..addText('Cantidad: ${pr.cantidad} lts')
  //     ..addText('Precio/U: ${pr.precioUnit}')
  //     ..addText('Total: ${NumberFormat("###,###.00", "en_US").format(pr.total)}')
  //     ..addSpacer()
  //     ..addText('_________________________', alignment: ReceiptAlignment.center);

  //   await _bluetooth.printReceiptText(section,
  //       useCut: true, feedCount: 2, useRaster: false);
  //   await _bluetooth.disconnect();
  // }
}
