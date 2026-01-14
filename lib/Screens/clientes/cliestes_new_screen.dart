import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/cliente.dart';
import 'package:tester/Providers/clientes_provider.dart';
import 'package:tester/Screens/clientes/cliente_card.dart';
import 'package:tester/Screens/clientes/clientes_add_screem.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/api_helper.dart';

enum SearchMode { nombre, documento }

class ClientesNewScreen extends StatefulWidget {
  final Invoice factura;
  final ClienteTipo tipo;

  const ClientesNewScreen({
    super.key,
    required this.factura,
    required this.tipo,
  });

  @override
  ClientesNewScreenState createState() => ClientesNewScreenState();
}

class ClientesNewScreenState extends State<ClientesNewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Resultados visibles
  final List<Cliente> _filterUsers = [];

  // Búsqueda
  SearchMode _mode = SearchMode.nombre;
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  final List<String> _recent = [];
  static const int _minLenName = 3;
  static const int _minLenDoc = 4;

  // Estado por ID (no por índice)
  final Set<String> _busyIds = <String>{};
  final Map<String, String> _statusById = <String, String>{};

  bool _isFiltered = false;

  String _norm(String s) => s.toLowerCase().trim();

  String _titleFor(ClienteTipo tipo) {
    final raw = tipo.toString().split('.').last.replaceAll('_', ' ');
    final label = raw
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return 'Clientes $label';
  }

  // Para forzar reconstrucción limpia de la lista entre búsquedas
  Key _resultsListKey = UniqueKey();
  Key _searchFieldKey = UniqueKey();

  // Referencia estable para evitar error en dispose con el contexto
  ClienteProvider? _clienteProvider;

  TextStyle baseStyle = const TextStyle(
    fontStyle: FontStyle.normal,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: kNewtextPri,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        _hideKeyboard();
      }
    });

    // Guardamos la referencia y escuchamos cambios
    _clienteProvider = context.read<ClienteProvider>();
    _clienteProvider?.addListener(_syncCachedData);

    // Carga inicial de datos si es tipo CONTADO y cache vacío
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataIfNeeded();
    });

    // Precarga inicial
    _syncCachedData();
  }

  Future<void> _loadInitialDataIfNeeded() async {
    if (widget.tipo == ClienteTipo.contado && _clienteProvider != null) {
      // SIEMPRE llamar - el provider decide si necesita cargar o no
      await _clienteProvider!.loadClientesContadoSmart();
    }
  }

  void _syncCachedData() {
    if (!mounted || _clienteProvider == null) return;

    // Si hay una búsqueda activa, la refrescamos en lugar de resetear.
    // Esto evita que al sincronizar un cliente (que causa un notifyListeners),
    // la pantalla "salte" de vuelta al cliente de la factura.
    if (_queryCtrl.text.trim().isNotEmpty) {
      _performSearch(force: false);
      return;
    }

    final cachedClientes =
        List<Cliente>.from(_clienteProvider!.clientesBy(widget.tipo));

    final clienteSel = widget.factura.formPago?.clienteFactura;

    setState(() {
      _filterUsers.clear();
      _statusById.clear();
      debugPrint(
          'Screen sync: Found ${cachedClientes.length} clients for type ${widget.tipo}');
      // No reseteamos la key aquí para no interrumpir el scroll si es reactivo
      // _resultsListKey = UniqueKey();

      if (clienteSel != null && clienteSel.nombre.isNotEmpty) {
        final id = _idOf(clienteSel);
        _filterUsers.add(clienteSel);
        _statusById[id] = 'Cliente actual ✓';
        _isFiltered = true;
      } else {
        _filterUsers.addAll(cachedClientes);
        _isFiltered = false;
      }
    });

    if (clienteSel != null &&
        clienteSel.nombre.isNotEmpty &&
        _tabController.index == 0) {
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    // Usamos la referencia guardada para evitar "Looking up a deactivated widget's ancestor"
    _clienteProvider?.removeListener(_syncCachedData);
    _debounce?.cancel();
    _queryCtrl.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ID estable para cada cliente
  String _idOf(Cliente c) {
    final codigo = (c.codigo).trim();
    if (codigo.isNotEmpty) return codigo;
    return c.documento.trim();
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _restartKeyboardForModeChange() {
    if (!_searchFocus.hasFocus) return;
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_searchFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kNewbg,
        appBar: AppBar(
          backgroundColor: kNewsurface,
          elevation: 2.0,
          shadowColor: kNewtextPri,
          foregroundColor: Colors.white,
          title: Text(_titleFor(widget.tipo), style: baseStyle),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60)),
                backgroundColor: kNewsurfaceHi,
                padding: EdgeInsets.zero,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                "assets/Back ICon.svg",
                height: 15,
                colorFilter:
                    const ColorFilter.mode(kNewtextPri, BlendMode.srcIn),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipOval(
                child: Image.asset(
                  'assets/splash.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.black,
              child: TabBar(
                indicatorColor: kNewtextPri,
                controller: _tabController,
                labelColor: kNewtextPri,
                unselectedLabelColor: kNewtextMut,
                onTap: (i) {
                  if (i == 0) {
                    // Si el usuario regresa a "Buscar Por", resetea la key para evitar reuso extraño
                    setState(() => _resultsListKey = UniqueKey());
                  } else {
                    _hideKeyboard();
                  }
                },
                tabs: const [Tab(text: 'Buscar Por'), Tab(text: 'Resultados')],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildFilterTab(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _getContent(),
                ),
              ],
            ),
            Consumer<ClienteProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading) {
                  return const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: kPrimaryColor,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: UniqueKey(),
          backgroundColor: kNewgreen,
          foregroundColor: kNewtextPri,
          onPressed: _goAdd,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    );
  }

  // =========================
  // Pestaña de búsqueda
  // =========================
  Widget _buildFilterTab() {
    final isDoc = _mode == SearchMode.documento;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SegmentedButton<SearchMode>(
                segments: const [
                  ButtonSegment(
                    value: SearchMode.nombre,
                    label: Text('Nombre'),
                    icon: Icon(Icons.person_search),
                  ),
                  ButtonSegment(
                    value: SearchMode.documento,
                    label: Text('Documento'),
                    icon: Icon(Icons.badge_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) {
                  final nextMode = set.first;
                  if (_mode == nextMode) return;
                  setState(() {
                    _mode = nextMode;
                    _queryCtrl.clear();
                    _filterUsers.clear();
                    _isFiltered = false;
                    _resultsListKey = UniqueKey();
                    _searchFieldKey = UniqueKey();
                  });
                  _restartKeyboardForModeChange();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? kPrimaryColor
                          : kNewsurfaceHi),
                  foregroundColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? kNewtextPri
                          : kNewtextMut),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Barra de búsqueda
            TextField(
              key: _searchFieldKey,
              focusNode: _searchFocus,
              controller: _queryCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              keyboardType: isDoc ? TextInputType.number : TextInputType.name,
              inputFormatters:
                  isDoc ? [FilteringTextInputFormatter.digitsOnly] : null,
              onChanged: _onQueryChanged,
              onSubmitted: (_) {
                _hideKeyboard();
                _performSearch(force: true);
              },
              style: const TextStyle(color: kNewtextPri),
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText:
                    isDoc ? 'Digite # de documento' : 'Nombre del cliente',
                hintStyle: const TextStyle(color: kNewtextMut),
                prefixIcon: const Icon(Icons.search, color: kNewtextSec),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_queryCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: kNewtextSec),
                        onPressed: () {
                          setState(() {
                            _queryCtrl.clear();
                            _filterUsers.clear();
                            _isFiltered = false;
                            _resultsListKey = UniqueKey();
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: kNewtextSec),
                      onPressed: () {
                        _hideKeyboard();
                        _performSearch(force: true);
                      },
                    ),
                  ],
                ),
                filled: true,
                fillColor: kNewsurfaceHi,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kNewborder),
                ),
                enabledBorder: darkBorder(radius: 12),
                focusedBorder:
                    darkBorder(color: kPrimaryColor, width: 1.8, radius: 12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            // Búsquedas recientes
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _recent
                    .map((q) => ActionChip(
                          label: Text(q, overflow: TextOverflow.ellipsis),
                          avatar: const Icon(Icons.history, size: 16),
                          onPressed: () {
                            _queryCtrl.text = q;
                            _hideKeyboard();
                            _performSearch(force: true);
                          },
                        ))
                    .toList(),
              ),
            ],

            // Ayuda
            const SizedBox(height: 12),
            Text(
              _mode == SearchMode.nombre
                  ? 'Tip: escribe al menos $_minLenName letras para filtrar por nombre.'
                  : 'Tip: escribe al menos $_minLenDoc dígitos para filtrar por documento.',
              style: const TextStyle(color: kNewtextMut),
            ),
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String _) {
    // Rebuild para mostrar/ocultar el botón de limpiar en el suffixIcon
    setState(() {});
    _debounce?.cancel();
    // Ajusta el delay a tu público objetivo (300–500ms). Aquí: 400ms.
    _debounce =
        Timer(const Duration(milliseconds: 1000), () => _performSearch());
  }

  Future<void> _performSearch({bool force = false}) async {
    final q = _queryCtrl.text.trim();

    // reglas mínimas
    if (!force) {
      if (_mode == SearchMode.nombre && q.length < _minLenName) {
        setState(() {
          _isFiltered = false;
          _filterUsers.clear();
          _resultsListKey = UniqueKey();
        });
        return;
      }
      if (_mode == SearchMode.documento && q.length < _minLenDoc) {
        setState(() {
          _isFiltered = false;
          _filterUsers.clear();
          _resultsListKey = UniqueKey();
        });
        return;
      }
    } else {
      if ((_mode == SearchMode.nombre && q.length < _minLenName) ||
          (_mode == SearchMode.documento && q.length < _minLenDoc)) {
        return;
      }
    }

    final prov = context.read<ClienteProvider>();

    // Busca en la lista cacheada según el tipo
    // (La carga inicial ya se hizo en _loadInitialDataIfNeeded)
    final clientes = prov.clientesBy(widget.tipo);

    // 👇 Comparación case-insensitive
    final qn = _norm(q);
    final Iterable<Cliente> result = (_mode == SearchMode.nombre)
        ? clientes.where((c) => _norm(c.nombre).contains(qn))
        : clientes.where((c) => _norm(c.documento).contains(qn));

    setState(() {
      _isFiltered = true;
      _filterUsers
        ..clear()
        ..addAll(result);
      _resultsListKey =
          UniqueKey(); // fuerza lista "limpia" (sin reuso peligroso)
    });

    if (_filterUsers.isNotEmpty) {
      _hideKeyboard();
      _tabController.animateTo(1);
      _addRecent(q);
    }
  }

  void _addRecent(String q) {
    if (q.isEmpty) return;
    _recent.remove(q);
    _recent.insert(0, q);
    if (_recent.length > 5) _recent.removeLast();
  }

  // =========================
  // Resultados
  // =========================
  Widget _getContent() => _filterUsers.isEmpty ? _noContent() : _getListView();

  Widget _noContent() {
    final prov = context.read<ClienteProvider>();
    final error = prov.errorMessage;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null && error.isNotEmpty) ...[
              const Icon(Icons.error_outline, color: kNewred, size: 40),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kNewred, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              _isFiltered
                  ? 'No hay Usuarios con ese criterio de búsqueda.'
                  : 'No hay Usuarios registradas.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kNewtextPri,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getListView() {
    // Snapshot inmutable para este frame → evita RangeError por cambios durante build
    final items = List<Cliente>.unmodifiable(_filterUsers);

    return ListView.builder(
      key: _resultsListKey,
      itemCount: items.length,
      itemBuilder: (context, indice) {
        if (indice >= items.length) {
          return const SizedBox
              .shrink(); // guard por si el scheduler llega tarde
        }

        final c = items[indice];
        final id = _idOf(c);

        return Column(
          children: [
            ClienteCard(
              key: ValueKey(id),
              cliente: c,
              factura: widget.factura,
              index: indice,
              onInfoUser: _goInfoUser,
              onSyncActividades: (doc, idx) => _syncActividades(doc, idx, id),
              onGetEmails: (doc, idx) => _getEmails(doc, idx, id),
              onEditarEmail: mostrarEditarEmailDialog,
              onAgregarEmail: mostrarAgregarEmailDialog,
              isBusy: _busyIds.contains(id),
              statusText: _statusById[id],
            ),
            if (indice < items.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _goInfoUser(Cliente clienteSel) {
    widget.factura.formPago!.clienteFactura = clienteSel;
    FacturaService.updateFactura(context, widget.factura);
    Navigator.of(context).pop();
  }

  void _goAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClietesAddScreen(
          factura: widget.factura,
        ),
      ),
    );

    if (!mounted) return;

    // Si regresamos con un Cliente creado, muéstralo en Resultados
    if (result is Cliente) {
      final created = result;
      final id = _idOf(created);

      // 1) Persistir en Provider
      final prov = context.read<ClienteProvider>();
      prov.upsertClienteBy(created, tipo: widget.tipo, asFirst: true);

      setState(() {
        // Dedupe por ID estable (documento/código)
        final existingIdx = _filterUsers.indexWhere((c) => _idOf(c) == id);
        if (existingIdx >= 0) {
          _filterUsers[existingIdx] = created;
        } else {
          _filterUsers.insert(0, created); // al tope de la lista
        }

        // Marca visual temporal en el card (aprovechando status por-ID)
        _statusById[id] = 'Creado ✓';

        _isFiltered = true;
        _resultsListKey =
            UniqueKey(); // lista “limpia” para evitar reuso peligroso
      });

      // Snack amistoso y navega a Resultados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cliente creado: ${created.nombre}')),
      );
      _tabController.animateTo(1);

      // Limpia el status después de 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _statusById.remove(id));
      });
    }
  }

  // =========================
  // Acciones por-card
  // =========================

  Future<void> _syncActividades(String documento, int index, String id) async {
    final clienteProvider = context.read<ClienteProvider>();
    _setBusyById(id, true, status: 'Sincronizando actividades…');

    switch (widget.tipo) {
      case ClienteTipo.credito:
      case ClienteTipo.peddler:
        await clienteProvider.syncActividadesCreditoBy(documento);
        break;
      case ClienteTipo.contado:
      case ClienteTipo.promo:
        await clienteProvider.syncActividadesContadoBy(documento);
        break;
    }
    if (!mounted) return;

    final err = clienteProvider.errorMessage;

    // Reemplaza en la lista por ID (no dependas del índice del provider)
    final updatedList = clienteProvider.clientesBy(widget.tipo);
    final actualizado = updatedList.firstWhere(
      (x) => _idOf(x) == id,
      orElse: () => _filterUsers.elementAt(index),
    );

    setState(() {
      final pos = _filterUsers.indexWhere((x) => _idOf(x) == id);
      if (pos >= 0) _filterUsers[pos] = actualizado;
    });

    if (err == null) {
      final count = actualizado.actividadesEconomicas?.length ?? 0;
      _doneById(id, 'Sincronizado ✓  ($count actividades)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Actividades sincronizadas ✅")),
      );
    } else {
      _failById(id, err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $err")),
      );
    }
  }

  Future<void> _getEmails(String codigo, int index, String id) async {
    _setBusyById(id, true, status: 'Buscando emails…');

    final response = await ApiHelper.getEmailsBy(codigo);
    if (!mounted) return;

    if (!response.isSuccess) {
      _failById(id, response.message);
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Error'),
          content: Text(response.message),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final correos = (response.result as List<dynamic>).cast<String>();

    setState(() {
      // busca por id por si el índice cambió
      final pos = _filterUsers.indexWhere((x) => _idOf(x) == id);
      if (pos >= 0) {
        final cli = _filterUsers[pos];
        cli.emails;
        for (final item in correos) {
          if (!cli.emails.contains(item)) cli.emails.add(item);
        }
        if (cli.email.isEmpty || !cli.emails.contains(cli.email)) {
          cli.email = cli.emails.isNotEmpty ? cli.emails.first : '';
        }
      }
    });

    final pos = _filterUsers.indexWhere((x) => _idOf(x) == id);
    final total = pos >= 0 ? (_filterUsers[pos].emails.length) : 0;
    _doneById(id, 'Emails actualizados ($total)');
  }

  Future<bool> _editEmail(
      String newEmail, String oldEmail, String codigo, String id) async {
    _setBusyById(id, true, status: 'Actualizando email…');

    final request = {
      'newEmail': newEmail,
      'oldEmail': oldEmail,
      'codCliente': codigo,
      'isCredito': false
    };
    final response = await ApiHelper.editEmail(codigo, request);
    if (!mounted) return false;

    if (!response.isSuccess) {
      _failById(id, response.message);
      return false;
    }

    _doneById(id, 'Email actualizado');
    return true;
  }

  Future<bool> _addEmail(String newEmail, String codigo, String id) async {
    _setBusyById(id, true, status: 'Agregando email…');

    final request = {
      'newEmail': newEmail,
      'oldEmail': '',
      'codCliente': codigo,
      'isCredito': false
    };
    final response = await ApiHelper.post('api/Users', request);
    if (!mounted) return false;

    if (!response.isSuccess) {
      _failById(id, response.message);
      return false;
    }

    _doneById(id, 'Email agregado');
    return true;
  }

  void agregarEmail(int clienteIndex, String nuevoEmail) async {
    final cliente = _filterUsers[clienteIndex];
    final id = _idOf(cliente);
    final ok = await _addEmail(nuevoEmail, cliente.documento, id);
    if (ok) {
      setState(() {
        cliente.email = nuevoEmail;
        cliente.emails;
        if (!cliente.emails.contains(nuevoEmail)) {
          cliente.emails.add(nuevoEmail);
        }
      });
    }
  }

  bool esCorreoValido(String correo) {
    final regexCorreo =
        RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regexCorreo.hasMatch(correo);
  }

  void mostrarEditarEmailDialog(Cliente cliente, int clienteIndex) {
    String emailTemporal = cliente.email;
    final controller = TextEditingController(text: emailTemporal);
    final id = _idOf(cliente);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Editar Correo'),
        content: TextField(
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => emailTemporal = value,
          controller: controller,
          decoration:
              const InputDecoration(hintText: "Introduce un nuevo correo"),
        ),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () => Navigator.of(context).pop(emailTemporal)),
        ],
      ),
    ).then((nuevoEmail) async {
      if (nuevoEmail == null) return;
      if (!esCorreoValido(nuevoEmail)) {
        Fluttertoast.showToast(
          msg: "Correo no valido",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: kNewred,
          textColor: kNewtextPri,
        );
        return;
      }
      if (nuevoEmail.isNotEmpty && nuevoEmail != cliente.email) {
        final old = cliente.email; // guarda antes de mutar
        final ok = await _editEmail(nuevoEmail, old, cliente.documento, id);
        if (ok) {
          setState(() {
            cliente.email = nuevoEmail;
            cliente.emails;
            cliente.emails.remove(old);
            if (!cliente.emails.contains(nuevoEmail)) {
              cliente.emails.add(nuevoEmail);
            }
          });
        }
      }
    });
  }

  void mostrarAgregarEmailDialog(Cliente cliente, int clienteIndex) {
    String emailTemporal = "";
    final controller = TextEditingController(text: emailTemporal);
    final id = _idOf(cliente);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Agregar un Correo'),
        content: TextField(
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => emailTemporal = value,
          controller: controller,
          decoration:
              const InputDecoration(hintText: "Introduce un nuevo correo"),
        ),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () => Navigator.of(context).pop(emailTemporal)),
        ],
      ),
    ).then((nuevoEmail) async {
      if (nuevoEmail == null) return;
      if (!esCorreoValido(nuevoEmail)) {
        Fluttertoast.showToast(
          msg: "Correo no valido",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: kNewred,
          textColor: kNewtextPri,
        );
        return;
      }
      if (nuevoEmail.isNotEmpty) {
        final ok = await _addEmail(nuevoEmail, cliente.documento, id);
        if (ok) {
          setState(() {
            cliente.email = nuevoEmail;
            cliente.emails;
            if (!cliente.emails.contains(nuevoEmail)) {
              cliente.emails.add(nuevoEmail);
            }
          });
        }
      }
    });
  }

  // =========================
  // Estado por-ID
  // =========================
  void _setBusyById(String id, bool value, {String? status}) {
    setState(() {
      if (value) {
        _busyIds.add(id);
      } else {
        _busyIds.remove(id);
      }
      if (status != null) _statusById[id] = status;
    });
  }

  void _doneById(String id, String message) {
    setState(() {
      _busyIds.remove(id);
      _statusById[id] = message;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _statusById.remove(id));
    });
  }

  void _failById(String id, String message) {
    setState(() {
      _busyIds.remove(id);
      _statusById[id] = 'Error: $message';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _statusById.remove(id));
    });
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
              child: const Text('Aceptar'),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
