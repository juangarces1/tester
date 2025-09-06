import 'dart:math';
import 'package:tester/Components/combustible_icon.dart';
import 'package:tester/ViewModels/dispatch_control.dart';
import 'package:tester/ConsoleModels/console_transaction.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Providers/transactions_provider.dart';
import 'package:tester/ViewModels/new_map.dart';

/// Extensión para preparar un despacho mock listo para facturar,
/// crear la ConsoleTransaction y registrar en ambos providers.
/// NO navega ni simula estados.
extension DispatchControlMock on DispatchControl {
  /// Crea datos del despacho, genera TX, la adjunta al control
  /// y registra en TransactionsProvider + DespachosProvider.
  ///
  /// Params más usados:
  /// - [useAmount] si true usa monto, si false usa volumen.
  /// - [amount] monto del preset si useAmount = true.
  /// - [liters] volumen del preset si useAmount = false.
  /// - [pricePerL] precio unitario por litro.
  /// - [product] código de combustible (fuelCode/productId).
  /// - [nozzle] número de manguera por defecto (visual/estadístico).
  void seedMockAndRegister({
    required DespachosProvider despachos,
    required TransactionsProvider transactions,
    bool useAmount = true,
    double amount = 50000,
    double liters = 10.0,
    double pricePerL = 5200.0,
    int product = 95,
    int nozzle = 1,
    InvoiceType type = InvoiceType.contado,
    String userId = 'tester@fuelred.dev',
  }) {
    // 1) Crear/llenar datos del despacho (solo DispatchControl)
    id = 'SIM-${DateTime.now().millisecondsSinceEpoch}';
    invoiceType = type;

    // Preset por monto/volumen (elige uno)
    if (useAmount) {
      setPresetByAmount(manguera: 'M-$nozzle', amount: amount);
    } else {
      setPresetByVolume(manguera: 'M-$nozzle', liters: liters);
    }

    // Datos de conveniencia
    productId = product;
    price     = pricePerL;
    fuel   = const Fuel(name: 'Super', color: kSuperColor);
    nozzle = 1;
    selectedPosition = const PositionPhysical(number: 1,hoses: []);
    selectedHose = const HosePhysical(hoseKey: '12', nozzleNumber: 1, fuel: Fuel(name: 'Super', color: kSuperColor,), status: 'Available');

    // Dejar listo para facturar sin simular pasos
    stage = DispatchStage.unpaid;

    // 2) Construir ConsoleTransaction coherente y enlazar al control
    final tx = _buildMockTx(
      userId: userId,
      nozzle: nozzle,
      product: product,
      unitPrice: pricePerL,
    );

    // Adjuntar la tx al control para que facturación tenga todo
    consoleTx        = tx;
    saleId           = tx.saleId;
    saleNumber       = tx.saleNumber;
    productId        = tx.fuelCode;
    amountDispense   = tx.totalValue;
    volumenDispense  = tx.totalVolume;
    price            = tx.unitPrice;

    // 3) Registrar en providers (sin navegación)
    transactions.upsert(tx);     // queda en unpaid por tu predicado
    despachos.addDispatch(this); // aparece el card en FirstPage
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
        ? (12.0 + rnd.nextDouble() * 6.0)                           // ~12–18 L
        : (isVolume ? (preset.volume ?? 10.0)
                    : ((preset.amount ?? 50000) / unitPrice));
    final totalValue = double.parse((totalVolume * unitPrice).toStringAsFixed(2));

    return ConsoleTransaction(
      id: 100000 + rnd.nextInt(900000),
      fuelingIndex: 1 + rnd.nextInt(999),
      nozzleNumber: nozzle,
      fuelCode: 1,
      fuelTankNumber: 1,
      totalValue: totalValue,
      totalVolume: double.parse(totalVolume.toStringAsFixed(3)),
      unitPrice: double.parse(unitPrice.toStringAsFixed(3)),
      duration: 2,
      dateTime: now,
      initialTotalizer: 100000 + rnd.nextInt(10000),
      finalTotalizer:  100000 + rnd.nextInt(10000),
      attendantId: userId,
      attendantIdRaw: userId,
      customerId: null,
      currentVolume: null,

      // 🔴 Para tu _isUnpaid: saleStatus==0 && !paymentConfirmed
      saleStatus: 0,
      saleNumber: 20000 + rnd.nextInt(80000),
      saleId: 'SIM-${rnd.nextInt(999999).toString().padLeft(6, '0')}',

      reference: 'SIMULATED',
      paymentType: 'N/A',
      mode: preset.isVolume ? 'VOLUMEN' : (tankFull ? 'FULL' : 'MONTO'),
      invoiceType: invoiceType?.name,

      epIdEmpresa: 1,
      paymentConfirmed: false,
      createdAt: now,
      userEmail: null,
    );
  }
}
