import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/client_points.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/Models/FuelRed/transferencia.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Sinpes/lista_sinpes_screen.dart';
import 'package:tester/Screens/Transfers/transfer_screen.dart';
import 'package:tester/constans.dart';
import 'package:provider/provider.dart';

/// Versión rediseñada del FormPago - más limpia e intuitiva
///
/// Concepto: Grid de métodos de pago con chips visuales
/// - Tap simple = pagar todo el saldo con ese método
/// - Long press = ingresar monto específico
/// - Los métodos con monto asignado se muestran resaltados
class FormPagoV2 extends StatefulWidget {
  @override
  final GlobalKey<FormPagoV2State> key;
  final int index;
  final Color fontColor;
  final String ruta;
  final ExpansibleController expansibleController;

  const FormPagoV2({
    required this.key,
    required this.index,
    required this.fontColor,
    required this.ruta,
    required this.expansibleController,
  }) : super(key: key);

  @override
  FormPagoV2State createState() => FormPagoV2State();
}

class FormPagoV2State extends State<FormPagoV2> {
  late Invoice factura;

  // Definición de todos los métodos de pago
  late List<PaymentMethod> _paymentMethods;

  // Controla si se muestra el widget de ClientPoints
  // Se muestra si: hay combustible >90L O el usuario tocó PUN
  bool _showClientPoints = false;

  @override
  void initState() {
    super.initState();
    factura = Provider.of<FacturasProvider>(context, listen: false)
        .getInvoiceByIndex(widget.index);
    _initPaymentMethods();
  }

  void _initPaymentMethods() {
    _paymentMethods = [
      // ═══════════════════════════════════════════════════════════════
      // 1. EFECTIVO (más usado)
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'cash',
        label: 'EFE',
        icon: 'assets/COLON.jpg',
        color: const Color(0xFF4CAF50),
        getValue: () => factura.formPago!.totalEfectivo,
        setValue: (v) => factura.formPago!.totalEfectivo = v,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 2. TARJETAS (BAC, BN, STA, DAV)
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'bac',
        label: 'BAC',
        icon: 'assets/Bac.png',
        color: const Color(0xFFE53935),
        getValue: () => factura.formPago!.totalBac,
        setValue: (v) => factura.formPago!.totalBac = v,
      ),
      PaymentMethod(
        id: 'bn',
        label: 'BN',
        icon: 'assets/BN.jpg',
        color: const Color(0xFF1565C0),
        getValue: () => factura.formPago!.totalBn,
        setValue: (v) => factura.formPago!.totalBn = v,
      ),
      PaymentMethod(
        id: 'scotia',
        label: 'STA',
        icon: 'assets/Scottia.png',
        color: const Color(0xFFD32F2F),
        getValue: () => factura.formPago!.totalSctia,
        setValue: (v) => factura.formPago!.totalSctia = v,
      ),
      PaymentMethod(
        id: 'dav',
        label: 'DAV',
        icon: 'assets/davicasa.png',
        color: const Color(0xFFE65100),
        getValue: () => factura.formPago!.totalDav,
        setValue: (v) => factura.formPago!.totalDav = v,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 3. PUNTOS
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'points',
        label: 'PUN',
        icon: 'assets/points.jpg',
        color: const Color(0xFFFFA000),
        getValue: () => factura.formPago!.totalPuntos,
        setValue: (v) => factura.formPago!.totalPuntos = v,
        isSpecial: true,
        onSpecialTap: _goPoints,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 4. SINPE
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'sinpe',
        label: 'SIN',
        icon: 'assets/sinpe.png',
        color: const Color(0xFF7B1FA2),
        getValue: () => factura.formPago!.totalSinpe,
        setValue: (v) => factura.formPago!.totalSinpe = v,
        isSpecial: true,
        onSpecialTap: _goSinpes,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 5. TRANSFERENCIA
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'transfer',
        label: 'TRF',
        icon: 'assets/transferencia.png',
        color: const Color(0xFF00838F),
        getValue: () => factura.formPago!.totalTransfer,
        setValue: (v) {},
        isSpecial: true,
        onSpecialTap: _goTransfers,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 6. CHEQUE
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'cheque',
        label: 'CHE',
        icon: 'assets/CHEQUE.jpg',
        color: const Color(0xFF5D4037),
        getValue: () => factura.formPago!.totalCheques,
        setValue: (v) => factura.formPago!.totalCheques = v,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 7. DÓLARES
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'dollar',
        label: 'DOL',
        icon: 'assets/dollar.png',
        color: const Color(0xFF2E7D32),
        getValue: () => factura.formPago!.totalDollars,
        setValue: (v) => factura.formPago!.totalDollars = v,
      ),

      // ═══════════════════════════════════════════════════════════════
      // 8. CUPONES
      // ═══════════════════════════════════════════════════════════════
      PaymentMethod(
        id: 'cupon',
        label: 'CUP',
        icon: 'assets/CUPONES.png',
        color: const Color(0xFFE91E63),
        getValue: () => factura.formPago!.totalCupones,
        setValue: (v) => factura.formPago!.totalCupones = v,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kNewsurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kNewborder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Expansible(
        animationStyle: AnimationStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic),
        controller: widget.expansibleController,
        maintainState: true,
        headerBuilder: (context, anim) => _buildHeader(anim),
        bodyBuilder: (context, anim) => _buildBody(),
      ),
    );
  }

  Widget _buildHeader(Animation<double> anim) {
    final isOpen = widget.expansibleController.isExpanded;
    return InkWell(
      onTap: () => isOpen
          ? widget.expansibleController.collapse()
          : widget.expansibleController.expand(),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kNewgreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payment_rounded,
                color: kNewgreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forma de Pago',
                    style: TextStyle(
                      color: widget.fontColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toca para pagar todo • Mantén para monto',
                    style: TextStyle(
                      color: kNewtextMut,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: anim.value * 0.5,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.expand_more_rounded,
                color: widget.fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F141E), Color(0xFF1A2332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          // Cliente/Puntos section - solo si hay combustible >90L o usuario tocó PUN
          if (_shouldShowClientPoints())
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClientPoints(factura: factura),
            ),

          // Divider - solo si se muestra ClientPoints
          if (_shouldShowClientPoints())
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              color: kNewborder.withOpacity(0.5),
            ),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════════
          // GRID DE MÉTODOS DE PAGO
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  _paymentMethods.map((pm) => _buildPaymentChip(pm)).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════════
          // MÉTODOS ACTIVOS (con montos asignados)
          // ═══════════════════════════════════════════════════════════════
          _buildActivePayments(),

          // ═══════════════════════════════════════════════════════════════
          // BOTÓN RESET
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildResetButton(),
          ),
        ],
      ),
    );
  }

  /// Chip individual para cada método de pago
  /// Todos los chips tienen el mismo tamaño para uniformidad
  Widget _buildPaymentChip(PaymentMethod pm) {
    final hasValue = pm.getValue() > 0;

    return GestureDetector(
      onTap: () => _handleTap(pm),
      onLongPress: () => _handleLongPress(pm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 95, // Ancho fijo para todos los chips
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue ? pm.color.withOpacity(0.25) : kNewsurfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? pm.color : kNewborder,
            width: hasValue ? 2 : 1,
          ),
          boxShadow: hasValue
              ? [
                  BoxShadow(
                    color: pm.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono/imagen - tamaño fijo para todos con fondo blanco
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  pm.icon,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              pm.label,
              style: TextStyle(
                color: hasValue ? Colors.white : kNewtextPri,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            // Mostrar monto si existe
            if (hasValue) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '¢${pm.getValue().toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lista de pagos activos (los que tienen monto)
  Widget _buildActivePayments() {
    final activePayments =
        _paymentMethods.where((pm) => pm.getValue() > 0).toList();

    if (activePayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kNewgreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kNewgreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: kNewgreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Pagos Seleccionados',
                style: TextStyle(
                  color: kNewgreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ¢${_calculateTotal().toInt()}',
                style: const TextStyle(
                  color: kNewgreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                activePayments.map((pm) => _buildActivePaymentTag(pm)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePaymentTag(PaymentMethod pm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pm.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${pm.label}: ¢${pm.getValue().toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _clearPaymentMethod(pm),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton.icon(
      onPressed: goRefresh,
      style: TextButton.styleFrom(
        foregroundColor: kNewred,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 20),
      label: const Text(
        'Limpiar Todo',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleTap(PaymentMethod pm) {
    // Si tiene handler especial (SINPE, Transfer, Puntos)
    if (pm.isSpecial && pm.onSpecialTap != null) {
      pm.onSpecialTap!();
      return;
    }

    // Si no hay saldo, mostrar mensaje
    if (factura.saldo <= 0) {
      _showNoBalanceToast();
      return;
    }

    // Pagar todo el saldo restante con este método
    setState(() {
      pm.setValue(pm.getValue() + factura.saldo);
      FacturaService.updateFactura(context, factura);
    });
  }

  void _handleLongPress(PaymentMethod pm) {
    if (pm.isSpecial) {
      _handleTap(pm); // Para métodos especiales, redirigir a tap
      return;
    }

    if (factura.saldo <= 0 && pm.getValue() == 0) {
      _showNoBalanceToast();
      return;
    }

    _showAmountDialog(pm);
  }

  void _showAmountDialog(PaymentMethod pm) {
    final controller = TextEditingController(
      text: pm.getValue() > 0 ? pm.getValue().toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNewsurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(pm.icon, width: 32, height: 32),
            ),
            const SizedBox(width: 12),
            Text(
              pm.label,
              style: const TextStyle(color: kNewtextPri),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: kNewtextPri,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: kNewtextMut),
                prefixText: '¢ ',
                prefixStyle: const TextStyle(
                  color: kNewgreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: kNewsurfaceHi,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón rápido para el saldo restante
            if (factura.saldo > 0)
              TextButton(
                onPressed: () {
                  controller.text = factura.saldo.toInt().toString();
                },
                child: Text(
                  'Usar saldo restante: ¢${factura.saldo.toInt()}',
                  style: const TextStyle(color: kNewgreen),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: kNewtextMut)),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx);
              _setPaymentAmount(pm, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kNewgreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _setPaymentAmount(PaymentMethod pm, double amount) {
    // Guardar valor anterior
    final previousValue = pm.getValue();

    setState(() {
      pm.setValue(amount);
      FacturaService.updateFactura(context, factura);
    });

    // Verificar si el saldo quedó negativo
    if (factura.saldo < 0) {
      setState(() {
        pm.setValue(previousValue);
        FacturaService.updateFactura(context, factura);
      });
      _showExceedsBalanceToast();
    }
  }

  void _clearPaymentMethod(PaymentMethod pm) {
    setState(() {
      pm.setValue(0);
      FacturaService.updateFactura(context, factura);
    });
  }

  double _calculateTotal() {
    return _paymentMethods.fold(0.0, (sum, pm) => sum + pm.getValue());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LÓGICA PARA MOSTRAR CLIENT POINTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Determina si se debe mostrar el widget de ClientPoints
  /// Se muestra si:
  /// 1. Hay alguna transacción de combustible con cantidad > 90 litros
  /// 2. El usuario tocó el botón PUN (para redimir puntos)
  bool _shouldShowClientPoints() {
    // Si el usuario pidió ver puntos, mostrar
    if (_showClientPoints) return true;

    // Si hay combustible > 90L, mostrar para acumulación
    final acumulables = factura.buscarAcumulacion();
    return acumulables.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLERS ESPECIALES (igual que original)
  // ═══════════════════════════════════════════════════════════════════════════

  void _goPoints() {
    if (factura.saldo <= 0) {
      _showNoBalanceToast();
      return;
    }

    // Si no hay cliente frecuente, mostrar el widget
    if (factura.formPago!.clientePuntos.nombre.isEmpty) {
      setState(() {
        _showClientPoints = true;
      });
      Fluttertoast.showToast(
        msg: "Seleccione el Cliente Frecuente",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    if (factura.formPago!.clientePuntos.puntos == 0) {
      Fluttertoast.showToast(
        msg: "El cliente no tiene puntos",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final pointsToUse = factura.saldo < factura.formPago!.clientePuntos.puntos
        ? factura.saldo
        : factura.formPago!.clientePuntos.puntos.toDouble();

    setState(() {
      factura.formPago!.totalPuntos = pointsToUse;
      FacturaService.updateFactura(context, factura);
    });
  }

  void _goTransfers() {
    setState(() {
      factura.formPago!.transfer.totalTransfer = factura.saldo;
      FacturaService.updateFactura(context, factura);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferScreen(index: widget.index),
      ),
    );
  }

  void _goSinpes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaSinpesScreen(index: widget.index),
      ),
    );
  }

  void goRefresh() {
    setState(() {
      factura.formPago!.totalBac = 0;
      factura.formPago!.totalBn = 0;
      factura.formPago!.totalCheques = 0;
      factura.formPago!.totalCupones = 0;
      factura.formPago!.totalDav = 0;
      factura.formPago!.totalDollars = 0;
      factura.formPago!.totalEfectivo = 0;
      factura.formPago!.totalPuntos = 0;
      factura.formPago!.totalSctia = 0;
      factura.formPago!.totalTransfer = 0;
      factura.formPago!.transfer.totalTransfer = 0;
      factura.formPago!.totalSinpe = 0;
      factura.formPago!.transfer = Transferencia(
        cliente: Cliente(
          nombre: '',
          documento: '',
          codigoTipoID: '',
          email: '',
          puntos: 0,
          codigo: '',
          telefono: '',
          plazo: 0,
        ),
        transfers: [],
        monto: 0,
        totalTransfer: 0,
      );
      factura.formPago!.clientePuntos = Cliente(
        nombre: '',
        documento: '',
        codigoTipoID: '',
        email: '',
        puntos: 0,
        codigo: '',
        telefono: '',
        plazo: 0,
      );
      factura.formPago!.clienteFactura = Cliente(
        nombre: '',
        documento: '',
        codigoTipoID: '',
        email: '',
        puntos: 0,
        codigo: '',
        telefono: '',
        plazo: 0,
      );
      factura.formPago!.sinpe = Sinpe(
        numFact: '',
        fecha: DateTime.now(),
        id: 0,
        idCierre: 0,
        activo: 0,
        monto: 0,
        nombreEmpleado: '',
        nota: '',
        numComprobante: '',
      );

      FacturaService.updateFactura(context, factura);
    });
  }

  void setValues() {
    setState(() {
      FacturaService.updateFactura(context, factura);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOASTS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showNoBalanceToast() {
    Fluttertoast.showToast(
      msg: "La factura ya no tiene saldo",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showExceedsBalanceToast() {
    Fluttertoast.showToast(
      msg: "La cantidad es superior al saldo",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class PaymentMethod {
  final String id;
  final String label;
  final String icon;
  final Color color;
  final double Function() getValue;
  final void Function(double) setValue;
  final bool isSpecial;
  final VoidCallback? onSpecialTap;

  PaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.getValue,
    required this.setValue,
    this.isSpecial = false,
    this.onSpecialTap,
  });
}
