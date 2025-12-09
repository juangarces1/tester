import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/Components/loader_component.dart';
import 'package:tester/Models/FuelRed/factura.dart';
import 'package:tester/Models/FuelRed/response.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/printer_provider.dart';           // ⬅️ NEW
import 'package:tester/Screens/Facturas/Components/factura_card.dart';
import 'package:tester/Screens/Facturas/detale_factura_screen.dart';
import 'package:tester/Screens/test_print/testprint.dart';         // ⬅️ NEW
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';

class FacturasScreen extends StatefulWidget {
  final String tipo;
  const FacturasScreen({super.key, required this.tipo});

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Factura> _backup = <Factura>[];
  List<Factura> _items = <Factura>[];

  bool _loading = false;
  bool _filtered = false;
  double _saldo = 0;

  bool _filtroSoloFacturas = false;
  bool _filtroSoloDevoluciones = false;
  bool _ordenDesc = true;

  @override
  void initState() {
    super.initState();
    // Inicializa impresora al montar (igual que en Depósitos)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().init();
      _fetch();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ====== Data ======
  Future<void> _fetch() async {
    setState(() => _loading = true);

    final cierre = context.read<CierreActivoProvider>().cierreFinal!;
    final tipoLower = widget.tipo.toLowerCase().trim();

    Response resp = (tipoLower == 'contado')
        ? await ApiHelper.getFacturasByCierre(cierre.idcierre)
        : await ApiHelper.getFacturasCredito(cierre.idcierre);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!resp.isSuccess) {
      _showError(resp.message);
      return;
    }

    final data = List<Factura>.from(resp.result);
    data.sort((a, b) => b.fechaHoraTrans.compareTo(a.fechaHoraTrans));

    setState(() {
      _backup = data;
      _items = List<Factura>.from(data);
      _filtered = false;
      _recalcSaldo();
    });
  }

  void _recalcSaldo() {
    _saldo = _items
        .where((f) => f.tipoDocumento == '00003')
        .fold<double>(0, (acc, f) => acc + (f.totalFactura ?? 0));
  }

  // ====== Filtro & Búsqueda (DESCRIPCLIENTE) ======
  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Factura> base = List<Factura>.from(_backup);

    if (q.isNotEmpty) {
      base = base.where((f) {
        final nombre = (f.descripCliente ?? '').toLowerCase();
        return nombre.contains(q);
      }).toList();
    }
    if (_filtroSoloFacturas) {
      base = base.where((f) => f.isFactura && !f.isDevolucion).toList();
    }
    if (_filtroSoloDevoluciones) {
      base = base.where((f) => f.isDevolucion).toList();
    }

    base.sort((a, b) => _ordenDesc
        ? b.fechaHoraTrans.compareTo(a.fechaHoraTrans)
        : a.fechaHoraTrans.compareTo(b.fechaHoraTrans));

    setState(() {
      _items = base;
      _filtered = q.isNotEmpty ||
          _filtroSoloFacturas ||
          _filtroSoloDevoluciones ||
          !_ordenDesc;
      _recalcSaldo();
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _filtroSoloFacturas = false;
      _filtroSoloDevoluciones = false;
      _ordenDesc = true;
      _items = List<Factura>.from(_backup);
      _filtered = false;
      _recalcSaldo();
    });
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();      // ⬅️ para estado en AppBar
    final isBound = printer.isBound;
    final isBusy = printer.busy;

    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewsurfaceHi,
        appBar: MyCustomAppBar(
          title: 'Facturas ${widget.tipo}',
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: kNewsurface,
          elevation: 2,
          shadowColor: Colors.white,
          actions: [
            // Indicador de estado de impresora (igual patrón que Depósitos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/splash.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isBound ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _openFiltersSheet,
              icon: const Icon(Icons.filter_alt, color: Colors.white),
              tooltip: 'Filtros',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // SearchBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: SearchBar(
                    controller: _searchCtrl,
                    hintText: 'Buscar por Cliente',
                    // Evita restricciones de ancho minimo del SearchBar (360px) que chocan con el padding
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      minHeight: 56,
                      maxHeight: 56,
                    ),
                    leading: const Icon(Icons.search),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _applyFilters(),
                    backgroundColor:
                        const WidgetStatePropertyAll(kContrateFondoOscuro),
                    elevation: const WidgetStatePropertyAll(0),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Lista / Empty
                Expanded(
                  child: RefreshIndicator.adaptive(
                    onRefresh: _fetch,
                    child: _items.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final f = _items[i];
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: kContrateFondoOscuro,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: FacturaCard(
                                  factura: f,
                                  index: i,
                                  onInfoPressed: () => _goInfoFactura(f),
                                  onPrintPressed: () =>
                                      _printFactura(f, isBusy: isBusy, isBound: isBound), // ⬅️ INTEGRA
                                  onConfirmPressed: () =>
                                      _confirmDevolucion(f),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),

            if (_loading)
              const Positioned.fill(
                child: IgnorePointer(
                  child: LoaderComponent(loadingText: 'Cargando...'),
                ),
              ),
          ],
        ),

        bottomNavigationBar: Container(
          height: 64,
          color: kNewborder,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Total: ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(
                VariosHelpers.formattedToCurrencyValue(_saldo.toString()),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              Badge(
                backgroundColor: Colors.white,
                label: Text('${_items.length}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600)),
                child:
                    const Icon(Icons.receipt_long, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 56),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: Colors.white.withValues(alpha: .7)),
                const SizedBox(height: 12),
                Text(
                  _filtered
                      ? 'No hay facturas para ese criterio.'
                      : 'No hay facturas registradas.',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ====== Filtros Sheet (mismo que antes) ======
  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool tSoloFacturas = _filtroSoloFacturas;
        bool tSoloDevol = _filtroSoloDevoluciones;
        bool tDesc = _ordenDesc;

        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        selected: tSoloFacturas,
                        label: const Text('Solo Facturas'),
                        onSelected: (v) => setModal(() => tSoloFacturas = v),
                      ),
                      FilterChip(
                        selected: tSoloDevol,
                        label: const Text('Solo Devoluciones'),
                        onSelected: (v) => setModal(() => tSoloDevol = v),
                      ),
                      FilterChip(
                        selected: tDesc,
                        label: const Text('Más recientes'),
                        onSelected: (v) => setModal(() => tDesc = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _filtroSoloFacturas = tSoloFacturas;
                              _filtroSoloDevoluciones = tSoloDevol;
                              _ordenDesc = tDesc;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.tune),
                          label: const Text('Aplicar filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Limpiar',
                        onPressed: () {
                          Navigator.pop(context);
                          _clearFilters();
                        },
                        icon: const Icon(Icons.filter_alt_off),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ====== Acciones ======
  void _goInfoFactura(Factura f) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleFacturaScreen(factura: f)),
    );
  }

  Future<void> _confirmDevolucion(Factura f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nota de crédito'),
        content: Text(
            '¿Desea realizar una Nota de Crédito al Doc. #${f.nFactura}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) _devolucion(f);
  }

  Future<void> _devolucion(Factura fact) async {
    if (fact.isDevolucion) {
      _showError('No se puede hacer devolución sobre una devolución');
      return;
    }

    setState(() => _loading = true);

    final prov = context.read<CierreActivoProvider>();
    final cierre = prov.cierreFinal!;
    final usuario = prov.usuario!;

    final req = {
      'facturaOrigen': fact.nFactura,   
      'numeroCierreActivo': cierre.idcierre,
      'cedulaUsuario': usuario.cedulaEmpleado.toString(),
    };

    final resp = await ApiHelper.post('Api/Facturacion/DevolucionSP', req);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!resp.isSuccess) {
      _showError(resp.message);
      return;
    }

    Fluttertoast.showToast(
      msg: 'Devolución creada con éxito',
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    await _fetch();
  }

  // ====== IMPRESIÓN (igual patrón que Depósitos) ======
  Future<void> _printFactura(Factura e, {required bool isBusy, required bool isBound}) async {
    if (isBusy) {
      Fluttertoast.showToast(msg: 'Impresora ocupada…');
      return;
    }

    if (!isBound) {
      Fluttertoast.showToast(msg: 'Impresora no conectada');
      return;
    }

    

      // Prepara datos del encabezado (usuario/pistero)
      final usuario = context.read<CierreActivoProvider>().usuario!;
      e.usuario = '${usuario.nombre} ${usuario.apellido1}';

      String tipoDocumento = e.isFactura ? 'FACTURA' : 'TICKET';
      if (tipoDocumento == 'FACTURA') {
         tipoDocumento = e.plazo == 0 ? 'CONTADO' : 'CREDITO';
      }
      
      if (e.isDevolucion) tipoDocumento = 'NOTA';
      final tipoPago = e.plazo == 0 ? 'CONTADO' : 'CREDITO';
     
      try {
        final tp = TestPrint(totalChars: 32); // mismo ancho que usas en depósitos
        await tp.printFactura(e, tipoDocumento, tipoPago);
        Fluttertoast.showToast(msg: 'Factura enviada a impresión');
      } catch (err, st) {
        debugPrint('printFactura error: $err\n$st');
        Fluttertoast.showToast(msg: 'Error al imprimir: $err');
      }
    
  }

  // ====== Util ======
  void _showError(String msg) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text(msg),
      // comportamiento por defecto: fixed
      // behavior: SnackBarBehavior.fixed,
    ),
  );
}

}
