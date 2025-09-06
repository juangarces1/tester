import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:tester/Components/app_bar_custom.dart';
import 'package:tester/ConsoleModels/dispatch_response.dart';

import 'package:tester/ConsoleModels/pump_faces_model.dart';            // PumpFacesResponse, PumpData, DispenserFace
import 'package:tester/ConsoleModels/dispensersstatusresponse.dart';    // DispenserStatus, DispenserHose
import 'package:tester/constans.dart';
import 'package:tester/helpers/console_api_helper.dart';                 // getPumpsAndFaces(), getDispensersStatus()
import 'dart:async';   
// ======================================================
//  MODELOS VISUALES (solo para la UI, no JSON)
// ======================================================

/// Manguera con estado operativo (si existe).
class MangueraVisual {
  final DispenserFace faceItem;  
  final String descripcion;        // dato físico de pump-beaches
  final DispenserHose? hoseStatus;      // estado operativo (puede ser null)
  const MangueraVisual({
    required this.faceItem,
    this.hoseStatus,
    this.descripcion = '',
  });

  int get nozzleNumber => int.tryParse(faceItem.id) ?? 0;
}

/// Cara (A/B) con sus mangueras.
class CaraVisual {
  final String letra;                   // "A", "B", etc.
  final List<MangueraVisual> hoses;
  const CaraVisual({required this.letra, required this.hoses});
}

/// Dispensador completo con 2 caras (si existen).
class DispensadorVisual {
  final int id;
  final String name;
  final CaraVisual? caraA;
  final CaraVisual? caraB;
  const DispensadorVisual({
    required this.id,
    required this.name,
    this.caraA,
    this.caraB,
  });
}

// ======================================================
//  DASHBOARD PRINCIPAL
// ======================================================

class DispensersDashboard extends StatefulWidget {
  final bool isActive; // para navegación si es necesario
  const DispensersDashboard({Key? key, required this.isActive}) : super(key: key);

  @override
  State<DispensersDashboard> createState() => _DispensersDashboardState();
}

class _DispensersDashboardState extends State<DispensersDashboard>  
    with AutomaticKeepAliveClientMixin<DispensersDashboard> {

  Timer? _refreshTimer;
   bool _isInitialLoading = true;
  List<DispensadorVisual> _data = [];

   TabController? _tabCtrl;

    /* ---------- helpers ---------- */
  void _startTimer() {
    _refreshTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchData(initial: false),
    );
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }


/* ───────── ciclo de vida ───────── */
  @override
  void initState() {
    super.initState();
    _fetchData(initial: true);            // primer golpe (loader)
    if (widget.isActive) _startTimer();     // solo si ya es visible
  }

  @override
  void didUpdateWidget(covariant DispensersDashboard old) {
    super.didUpdateWidget(old);

    // ↔ cambió visibilidad
    if (widget.isActive && !old.isActive) {
      _startTimer();                      // se mostró
    } else if (!widget.isActive && old.isActive) {
      _stopTimer();                       // se ocultó
    }
  }

  @override
  void dispose() {
    _stopTimer();    
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

 Future<void> _fetchData({required bool initial}) async {
  if (initial) setState(() => _isInitialLoading = true);

  try {
    final newData = await _loadData();
    if (!mounted) return;

    if (initial) {
      _isInitialLoading = false;          // actualizo flag primero
    }

    if (!listEquals(_data, newData)) {
      setState(() => _data = newData);    // solo redibujo si cambió
    } else if (initial) {
      setState(() {});                    // forza rebuild para quitar loader
    }
  } catch (_) {
    if (!mounted) return;
    if (initial) {
      setState(() => _isInitialLoading = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar estado')),
      );
    }
  }
}


  

 /// ---------------------------------------------------------------------------
///  Carga el mapa físico + estados y los fusiona en modelos visuales.
///  - Prioriza la descripción que viene en la cara (`dispFace.description`);
///    si está vacía usa la que trae el hose (`hoseStat.description`).
///  - Si no existe estado, marca la manguera como 'Unknown'.
/// ---------------------------------------------------------------------------
Future<List<DispensadorVisual>> _loadData() async {
  /* 1️⃣  Llamadas a las APIs ---------------------------------------------- */
  final pumps    = await ConsoleApiHelper.getPumpsAndFaces();      // topología
  final statuses = await ConsoleApiHelper.getDispensersStatus();   // estados

  /* 2️⃣  Índice Nº manguera → DispenserHose ------------------------------- */
  final Map<int, DispenserHose> estadoPorNozzle = {};
  for (final ds in statuses) {
    if (ds.hoses.isNotEmpty) {
      estadoPorNozzle[ds.number] = ds.hoses.first;
    }
  }

  /* 3️⃣  Fusionar en modelos visuales ------------------------------------- */
  final List<DispensadorVisual> resultado = [];

  for (final pump in pumps) {
    final Map<String, List<MangueraVisual>> agrupadas = {}; // 'A', 'B', …

    for (final dispFace in pump.dispensers) {
      final letra     = _mapFaceNumberToLetter(dispFace.numberOfFace);
      final nozzleNum = int.tryParse(dispFace.id) ?? 0;
      final hoseStat  = estadoPorNozzle[nozzleNum];

      /* Descripción priorizada:
         1) la que viene en la cara (dispFace.description)
         2) si está vacía, la que trae el hose (hoseStat?.description)
         3) si ninguna, texto genérico */
      final desc = dispFace.description.isNotEmpty
          ? dispFace.description
          : (hoseStat?.description ?? 'Manguera $nozzleNum');

      agrupadas.putIfAbsent(letra, () => []);
      agrupadas[letra]!.add(
        MangueraVisual(
          faceItem:    dispFace,
          hoseStatus:  hoseStat,
          descripcion: desc,        // ← aquí llenamos tu campo
        ),
      );
    }

    final caraA = agrupadas.containsKey('A')
        ? CaraVisual(letra: 'A', hoses: agrupadas['A']!)
        : null;
    final caraB = agrupadas.containsKey('B')
        ? CaraVisual(letra: 'B', hoses: agrupadas['B']!)
        : null;

    resultado.add(
      DispensadorVisual(
        id:    pump.id,
        name:  pump.pumpName,
        caraA: caraA,
        caraB: caraB,
      ),
    );
  }

  return resultado;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:   MyCustomAppBar(
           elevation: 6,
          shadowColor: kColorFondoOscuro,
          title: 'Dispensadores',
          automaticallyImplyLeading: true,
          foreColor: Colors.white,
          backgroundColor: Colors.grey[900],
          actions: <Widget>[
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(child:  Image.asset(
                  'assets/splash.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),), // Ícono de perfil de usuario
            ),
          ],      
        ),
      body: _isInitialLoading
        // 1️⃣ Primer render: spinner central
        ? const Center(child: CircularProgressIndicator())
        // 2️⃣ Con datos: lista con RefreshIndicator, sin spinner al refrescar
        : RefreshIndicator(
            color: Colors.greenAccent,         // círculo
            backgroundColor: Colors.grey[850], // fondo del círculo
            onRefresh: () => _fetchData(initial: false),
            child: _data.isEmpty
                // Lista vacía
                ? const Center(
                    child: Text(
                      'No hay dispensadores',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                // Lista con dispensadores
                : ListView.builder(
                    padding: const EdgeInsets.all(3),
                    itemCount: _data.length,
                    itemBuilder: (context, i) =>
                        _DispensadorCardVisual(datos: _data[i]),
                  ),
          ),
    );
  }

  // convierte 1→A, 2→B, 3→C...
  String _mapFaceNumberToLetter(int n) {
    if (n < 1) return '?';
    final code = 64 + n; // ASCII 'A' = 65
    return String.fromCharCode(code);
  }
}

// ======================================================
//  CARD VISUAL
//  (adapta esto o sustituye por tu DispensadorCard existente)
// ======================================================

class _DispensadorCardVisual extends StatefulWidget {
  final DispensadorVisual datos;
  const _DispensadorCardVisual({Key? key, required this.datos}) : super(key: key);

  @override
  State<_DispensadorCardVisual> createState() => _DispensadorCardVisualState();
}

class _DispensadorCardVisualState extends State<_DispensadorCardVisual> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 7,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.datos.name.isNotEmpty ? widget.datos.name : 'Dispensador ${widget.datos.id}',
              style: const TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _caraColumn(widget.datos.caraA, 'A')),
                const SizedBox(width: 14),
                Expanded(child: _caraColumn(widget.datos.caraB, 'B')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Cara ----------
  Widget _caraColumn(CaraVisual? cara, String label) {
    if (cara == null) {
      return _caraVacia(label);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerCara(label, cara.hoses),
        ...cara.hoses.map(_hoseRow),
      ],
    );
  }

  Widget _caraVacia(String label) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('Cara $label',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              const Text('Sin mangueras', style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Cabecera de cara ----------
  Widget _headerCara(String label, List<MangueraVisual> hoses) {
    final estado = _getCaraStatus(hoses);
    final color = _getCaraStatusColor(estado);
    final icon = _getCaraIcon(estado);

    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('Cara $label',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------- Fila manguera ----------
  Widget _hoseRow(MangueraVisual mv) {
    final description = mv.descripcion;
    final fuelName  = _fuelFromDescription(description);
    final fuelColor = _fuelColorFromName(fuelName);
    final fuelIcon  = _fuelIconFromName(fuelName);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          children: [
            InkWell(
               borderRadius: BorderRadius.circular(11),
              onTap: () async {
            // ── 1️⃣ Sólo continúa si la manguera está "available" ────────────────
                  if (mv.hoseStatus?.status == 'Available') {
                    await showDialog(
                      context: context,
                      builder: (_) => PreDispenseDialog(mv: mv),
                    );
                    // Si necesitas recargar el dashboard después:
                    setState(() {});
                  } else {
                  
                    Fluttertoast.showToast(
                              msg:  switch (mv.hoseStatus?.status) {
                            'Fueling' => 'Manguera en uso: despachando.',
                            'Blocked'    => 'Manguera bloqueada.',
                            'Unpaid'     => 'Manguera pendiente de pago.',
                            'Authorized' => 'Manguera autorizada.',
                            _            => 'Manguera no disponible.',
                          },
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 2,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            
                            ); 
                    
                  }
                },
              child: Row(
                children: [
                  CircleAvatar(
                  
                    backgroundColor: fuelColor,
                    radius: 19,
                    child: Icon(fuelIcon, color: Colors.white, size: 25),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre combustible / descripción
                        Text(
                            fuelName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: fuelColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Código manguera + estado (pequeño)
                        Text(
                          'M${mv.nozzleNumber} - ${translateDispenserStatus(mv.hoseStatus?.status ?? 'Desconocido')}',
                          style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Botón para ver últimos despachos
            Row(
              children: [
                IconButton(
                  color: Colors.black,
                  iconSize: 30,
                  icon: const Icon(Icons.history),       // ⟳ o cualquier ícono
                  tooltip: 'Ver últimos despachos',
                 onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.grey[900],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => DispatchesBottomSheet(nozzle: mv.nozzleNumber, fuelname: fuelName),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLastDispatches(BuildContext ctx, int nozzle, String fuelname) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<List<DispatchResponse>>(
        future: fetchLastDispatches(nozzle),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(
              child: Text('Sin despachos recientes',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey[700], height: 1),
            itemBuilder: (_, i) => _DispatchCard(d: data[i], fuelname: fuelname,),
          );
        },
      ),
    ),
  );
}

  // ---------- Cara utils ----------
  String _getCaraStatus(List<MangueraVisual> hoses) {
    bool anyDispensing = false;
    bool anyUnpaid = false;
    bool anyBlocked = false;
    bool allAvailable = true;
    bool anyAuthorized = false;

    for (final h in hoses) {
      final s = (h.hoseStatus?.status ?? '').toLowerCase();
      if (s == 'fueling') anyDispensing = true;
      if (s == 'unpaid') anyUnpaid = true;
      if (s == 'blocked') anyBlocked = true;
      if (s != 'available') allAvailable = false;
      if (s != 'authorized') anyAuthorized = true;
    }
    if (anyAuthorized) return 'Autorizado';
    if (anyDispensing) return 'Despachando';
    if (anyUnpaid) return 'Pendiente';
    if (anyBlocked) return 'Bloqueada';
    if (allAvailable) return 'Disponible';
    return 'Revisar';
  }

  String translateDispenserStatus(String status) {
  switch (status) {
    case 'Fueling':
      return 'Despachando';
    case 'Unpaid':
      return 'No pagado';
    case 'Blocked':
      return 'Bloqueado';
    case 'Available':  
      return 'Disponible';
    case 'Authorized':
      return 'Autorizado';
    default:
      return 'Desconocido';
  }
}

  Color _getCaraStatusColor(String status) {
    switch (status) {
      case 'Disponible':
        return Colors.greenAccent;
      case 'Despachando':
        return Colors.amberAccent;
      case 'Pendiente':
        return Colors.indigoAccent;
      case 'Bloqueada':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  IconData _getCaraIcon(String status) {
    switch (status) {
      case 'Disponible':
        return Icons.check_circle_outline;
      case 'Despachando':
        return Icons.local_gas_station;
      case 'Pendiente':
        return Icons.error_outline;
      case 'Bloqueada':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ---------- Combustible desde descripción ----------
  String _fuelFromDescription(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('super') || d.contains('premium')) return 'Super';
    if (d.contains('gasolina')) return 'Regular';
    if (d.contains('diesel')) return 'Diesel';
    if (d.contains('exo') || d.contains('exoner')) return 'Exonerado';
    return 'Desconocido';
  }

  Color _fuelColorFromName(String name) {
    switch (name) {
      case 'Super':
        return const Color(0xFFb634b8); // kSuperColor
      case 'Regular':
        return const Color(0xFFec1c24); // kRegularColor
      case 'Diesel':
        return const Color(0xFF1dbd4a); // kDieselColor
      case 'Exonerado':
        return const Color(0xFF00a8f3); // kExoColor
      default:
        return Colors.grey;
    }
  }

  IconData _fuelIconFromName(String name) {
    switch (name) {
      case 'Super':
        return Icons.bolt;
      case 'Regular':
        return Icons.local_gas_station;
      case 'Diesel':
        return Icons.local_shipping;
      case 'Exonerado':
        return Icons.water_drop;
      default:
        return Icons.help_outline;
    }
  }
}

class PreDispenseDialog extends StatefulWidget {
  final MangueraVisual mv;
  const PreDispenseDialog({super.key, required this.mv});

  @override
  State<PreDispenseDialog> createState() => _PreDispenseDialogState();
}

class _PreDispenseDialogState extends State<PreDispenseDialog> {
  final _amountCtrl = TextEditingController();
  final _userCtrl   = TextEditingController();
  final bool _authorize   = true;
  bool _loading     = false;
  
  Future<void> _callPreDispense() async {
    final text = _amountCtrl.text.trim();
    final amount = double.tryParse(text);

    // 1) Validación de monto
    if (text.isEmpty || amount == null || amount <= 0) {
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: 'Ingrese un monto válido (mayor que 0)',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    
      
      return;
    }

    // 2) Si pasa validación, continúa con la llamada
    setState(() => _loading = true);
    final ok = await ConsoleApiHelper.preDispense(
      widget.mv.nozzleNumber,
      amount,
      'B32809EE018B2811',
      authorize: _authorize,
    );
    setState(() => _loading = false);

    // 3) Resultado
    Fluttertoast.showToast(
      msg: ok ? 'Manguera lista ✅' : 'Error al pre-setear ❌',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: ok ? Colors.green : Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
 
}


  Future<void> _callPostDispense() async {
    setState(() => _loading = true);
    final ok = await ConsoleApiHelper.postDispense(
       widget.mv.nozzleNumber,
    );
    Navigator.pop(context);               // cerramos el diálogo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Despacho iniciado 🟢' : 'Error al despachar ❌'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
 String _fuelFromDescription(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('super') || d.contains('premium')) return 'Super';
    if (d.contains('regular')) return 'Regular';
    if (d.contains('diesel')) return 'Diesel';
    if (d.contains('exo') || d.contains('exoner')) return 'Exonerado';
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Despachar ${_fuelFromDescription(widget.mv.descripcion)}-M${widget.mv.nozzleNumber}',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              style: const TextStyle(color: Colors.white), 
              keyboardType: TextInputType.number,
              decoration: kDecorationModalMonto.copyWith(
                labelText: 'Monto \$',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              decoration: kDecorationModalMonto
              
              .copyWith(
                labelText: 'Litros a despachar',
                hintText: '0.0',
              ),
            ),
            const SizedBox(height: 12),
           
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _callPreDispense,
                    child: const Text('PRE-DESPACHO'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:  _callPostDispense,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 53, 123, 55)),
                    child: const Text('TANQUE LLENO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class DispatchesBottomSheet extends StatefulWidget {
  final int nozzle;
  final String fuelname; // nombre del combustible para mostrar en la UI
  const DispatchesBottomSheet({super.key, required this.nozzle, required this.fuelname});

  @override
  State<DispatchesBottomSheet> createState() => _DispatchesBottomSheetState();
}

class _DispatchesBottomSheetState extends State<DispatchesBottomSheet> {
  final _scroll = ScrollController();
  final _items = <DispatchResponse>[];

  int _pageIndex = 1;        // página actual (1-based)
  bool _isLoading = false;
  bool _hasMore = true;      // mientras queden páginas por pedir
  

  @override
  void initState() {
    super.initState();
    _loadPage();                     // primera tanda (5)
    _scroll.addListener(_onScroll);  // vigila el final del ListView
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120 &&
        !_isLoading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() => _isLoading = true);

    try {
      final page = await fetchDispatchPage(
        nozzle: widget.nozzle,
        pageIndex: _pageIndex,
        pageSize: 5,
      );

      setState(() {
        _items.addAll(page.data);
        _pageIndex++;                 // siguiente página
        _hasMore = _pageIndex <= page.pageCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .75,
      child: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scroll,
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i < _items.length) {
                  final d = _items[i];
                  return _DispatchCard(d: d, fuelname: widget.fuelname);   // tu card de UI
                }
                // Footer “cargando…” mientras llega la siguiente página
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final DispatchResponse d;
  final String fuelname;
  const _DispatchCard({required this.d, required this.fuelname});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd/MM/yyyy');
    final t = DateFormat('hh:mm:ss a');

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda • Nº y datos base
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${d.id} (Manguera ${d.nozzleNumber})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
                const SizedBox(height: 4),
                _kv('Fecha', f.format(d.dateTime)),
                _kv('Producto', fuelname),
                _kv('Volumen', d.volume.toStringAsFixed(3)),
              ],
            ),
          ),
          // Columna derecha • Hora, precios y botón imprimir
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _kv('Hora', t.format(d.dateTime)),
              _kv('Precio', '\$${d.price.toStringAsFixed(2)}'),
              _kv('Total', '\$${d.total.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              IconButton(
                icon: Icon(Icons.print, color: Colors.deepPurple[200]),
                tooltip: 'Imprimir',
                onPressed: () {
                  // TODO: llama al método de impresión / ticket
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper de key-value
  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            text: '$k: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            children: [
              TextSpan(
                  text: v,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      );
}
