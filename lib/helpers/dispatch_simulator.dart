import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:tester/Components/combustible_icon.dart';
import 'package:tester/Providers/transacciones_provider.dart'; // <-- ojo al import corregido
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/ConsoleModels/console_transaction.dart'; // tiene la ext .toTransaccion(...)
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/ViewModels/new_map.dart';

/// Extensión para preparar un despacho mock listo para facturar,
/// crear la ConsoleTransaction y registrar en ambos providers.
/// NO navega ni simula estados.
extension DispatchControlMock on DispatchControl {
  /// Crea datos del despacho, genera TX, la adjunta al control
  /// y registra en TransaccionesProvider (legacy) + DespachosProvider.
  ///
  /// Params más usados:
  /// - [useAmount] si true usa monto, si false usa volumen.
  /// - [amount] monto del preset si useAmount = true.
  /// - [liters] volumen del preset si useAmount = false.
  /// - [pricePerL] precio unitario por litro.
  /// - [product] código de combustible (fuelCode/productId).
  /// - [nozzle] número de manguera por defecto (visual/estadístico).
  void seedMockAndRegister({
    BuildContext? context,                      // 👈 opcional: para idCierre del provider
    required DespachosProvider despachos,
    required TransaccionesProvider transactions,
    bool useAmount = true,
    double amount = 50000,
    double liters = 10.0,
    double pricePerL = 5200.0,
    int product = 95,
    int nozzle = 1,
    InvoiceType type = InvoiceType.contado,
    String userId = 'tester@fuelred.dev',
  }) {
    // 1) Config del DispatchControl (solo estado visual/flujo)
    id = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
    invoiceType = type;

    if (useAmount) {
      setPresetByAmount(manguera: 'M-$nozzle', amount: amount);
    } else {
      setPresetByVolume(manguera: 'M-$nozzle', liters: liters);
    }

    productId = product;
    price     = pricePerL;
    fuel      = const Fuel(name: 'Super', color: kSuperColor);
    this.nozzle = nozzle; // 👈 respeta el parámetro
    selectedPosition = const PositionPhysical(number: 1, hoses: []);
    selectedHose = HosePhysical(
      hoseKey: 'H-$nozzle',
      nozzleNumber: nozzle,
      fuel: const Fuel(name: 'Super', color: kSuperColor),
      status: 'Available',
    );

    // Dejar listo para facturar
    stage = DispatchStage.unpaid;

    // 2) Construir ConsoleTransaction coherente y enlazar al control
    final tx = _buildMockTx(
      userId: userId,
      nozzle: nozzle,
      product: product,
      unitPrice: pricePerL,
    );

    // Adjuntar la tx al control para flujos que siguen usando ConsoleTransaction
    consoleTx        = tx;
    saleId           = tx.saleId;
    saleNumber       = tx.saleNumber;
    productId        = tx.fuelCode;
    amountDispense   = tx.totalValue;
    volumenDispense  = tx.totalVolume;
    price            = tx.unitPrice;

    // 3) Registrar en providers
    // 3.1 Registrar despacho (UI)
    despachos.addDispatch(this);

    // 3.2 Registrar transacción LEGACY en TransaccionesProvider
    //     Usamos la extensión que ya hicimos (ConsoleTransaction -> Transaccion).
    final legacy = tx.toTransaccion(
      context: context,             // si hay context, toma idCierre del provider
      nombreProducto: 'Combustible ${tx.fuelCode}',
      facturada: 'N',               // mock impaga
      estadoMapper: (_) => 'unpaid' // forza "unpaid" en legacy
    );
    transactions.upsert(legacy);
  }

  /// Crea una ConsoleTransaction coherente con el preset y el precio.
  ConsoleTransaction _buildMockTx({
    required String userId,
    required int nozzle,
    required int product,
    required double unitPrice,
  }) {
    final rnd = Random();
    final now = DateTime.now();

    final isVolume = preset.isVolume;
    final totalVolume = tankFull
        ? (12.0 + rnd.next
