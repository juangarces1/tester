// lib/Screens/Dispatch/preset_step_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/Providers/experimental/active_dispatch_manager.dart';
import 'package:tester/Providers/experimental/dispatch_session.dart';
import 'package:tester/ViewModels/new_map.dart';
import 'package:tester/helpers/console_api_helper.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/Models/SignalR/nozzle_status_dto.dart';
import 'package:tester/Providers/map_provider.dart';

enum PresetMode { amount, volume, full }

class PresetStepPage extends StatelessWidget {
  final PositionPhysical position;
  final HosePhysical hose;

  const PresetStepPage({
    super.key,
    required this.position,
    required this.hose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Preset / Tanque lleno',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.75,
          children: [
            _HeroActionCard(
              title: 'PRE-DESPACHO',
              subtitle: 'Por Monto o Volumen',
              icon: Icons.tune,
              color: Colors.blueAccent,
              onTap: () {
                final fuelName = hose.fuel.name.toLowerCase();
                final isExonerado = fuelName.contains('exo');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnifiedPresetPage(
                      position: position,
                      hose: hose,
                      initialMode:
                          isExonerado ? PresetMode.volume : PresetMode.amount,
                    ),
                  ),
                );
              },
            ),
            _HeroActionCard(
              title: 'TANQUE LLENO',
              subtitle: 'Hasta detenerse',
              icon: Icons.water_drop,
              color: Colors.greenAccent,
              onTap: () async {
                await _authorizeDispatch(
                  context: context,
                  position: position,
                  hose: hose,
                  mode: PresetMode.full,
                  amount: null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UnifiedPresetPage extends StatefulWidget {
  final PositionPhysical position;
  final HosePhysical hose;
  final PresetMode initialMode;

  const UnifiedPresetPage({
    required this.position,
    required this.hose,
    required this.initialMode,
    super.key,
  });

  @override
  State<UnifiedPresetPage> createState() => _UnifiedPresetPageState();
}

class _UnifiedPresetPageState extends State<UnifiedPresetPage> {
  late PresetMode _currentMode;
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentMode == PresetMode.amount
        ? 'Preset por Monto'
        : _currentMode == PresetMode.volume
            ? 'Preset por Volumen'
            : 'Tanque Lleno';

    final accentColor = _currentMode == PresetMode.amount
        ? Colors.blueAccent
        : _currentMode == PresetMode.volume
            ? Colors.tealAccent
            : Colors.greenAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SegmentedButton<PresetMode>(
                segments: const [
                  ButtonSegment(
                      value: PresetMode.amount,
                      label: Text('Monto (₡)'),
                      icon: Icon(Icons.money)),
                  ButtonSegment(
                      value: PresetMode.volume,
                      label: Text('Litros (L)'),
                      icon: Icon(Icons.local_gas_station)),
                  ButtonSegment(
                      value: PresetMode.full,
                      label: Text('Lleno'),
                      icon: Icon(Icons.water_drop)),
                ],
                selected: {_currentMode},
                onSelectionChanged: (Set<PresetMode> newSelection) {
                  setState(() {
                    _currentMode = newSelection.first;
                    _ctrl.clear();
                    _error = null;
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  selectedBackgroundColor: accentColor.withValues(alpha: 0.2),
                  selectedForegroundColor: accentColor,
                  foregroundColor: Colors.white60,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_currentMode != PresetMode.full) ...[
              // Quick Chips
              _buildQuickChips(accentColor),
              const SizedBox(height: 48),
              // Input Field
              _LabeledField(
                label: _currentMode == PresetMode.amount
                    ? 'Monto a Despachar'
                    : 'Litros a Despachar',
                controller: _ctrl,
                hint: '0.00',
                prefix: _currentMode == PresetMode.amount
                    ? Icons.money
                    : Icons.local_gas_station,
                accentColor: accentColor,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final pricePerLiter = context
                      .read<MapProvider>()
                      .getPriceForFuel(widget.hose.fuel.name);
                  if (pricePerLiter <= 0) return const SizedBox.shrink();

                  final val =
                      double.tryParse(_ctrl.text.replaceAll(',', '')) ?? 0.0;
                  if (val <= 0) return const SizedBox.shrink();

                  String estimation = '';
                  if (_currentMode == PresetMode.amount) {
                    final liters = val / pricePerLiter;
                    estimation = '~ ${liters.toStringAsFixed(2)} Litros';
                  } else if (_currentMode == PresetMode.volume) {
                    final cost = val * pricePerLiter;
                    estimation =
                        '~ ₡ ${VariosHelpers.formattedToCurrencyValue(cost.toStringAsFixed(0))}';
                  }

                  if (estimation.isEmpty) return const SizedBox.shrink();

                  return Center(
                    child: Text(
                      estimation,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 60),
              Icon(Icons.ev_station,
                  size: 100, color: accentColor.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              const Text(
                'MODO TANQUE LLENO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                'El despacho se detendrá automáticamente\ncuando el tanque esté completo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 60),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],

            const SizedBox(height: 40),
            _HeroButton(
              color: accentColor,
              label: 'CONFIRMAR AUTORIZACIÓN',
              icon: Icons.check_circle_outline,
              onTap: _confirmOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips(Color accentColor) {
    if (_currentMode == PresetMode.amount) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [1000, 2000, 3000, 4000, 5000, 10000, 20000, 50000]
            .map((v) => _quickChip(
                VariosHelpers.formattedToCurrencyValue(v.toString()),
                () => _setQuickValue(v.toDouble()),
                accentColor))
            .toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [10, 20, 30, 50, 60, 80, 90, 100, 200, 300, 400, 500]
            .map((v) => _quickChip(
                '$v L', () => _setQuickValue(v.toDouble()), accentColor))
            .toList(),
      );
    }
  }

  Widget _quickChip(String label, VoidCallback onSelected, Color color) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      side: BorderSide(color: color, width: 1.5),
      label: Text(label,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: onSelected,
    );
  }

  void _setQuickValue(double v) {
    final s = _currentMode == PresetMode.amount
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
    _ctrl.text = s;
    _ctrl.selection = TextSelection.collapsed(offset: s.length);
    setState(() => _error = null);
  }

  void _confirmOrder() async {
    double? value;
    if (_currentMode != PresetMode.full) {
      value = double.tryParse(_ctrl.text.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        setState(() => _error = 'Ingresa un valor válido');
        return;
      }
    }

    await _authorizeDispatch(
      context: context,
      position: widget.position,
      hose: widget.hose,
      mode: _currentMode,
      amount: value,
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    final darkColor = color.computeLuminance() > 0.5
        ? color.withValues(
            red: (color.red * 0.5).toDouble(),
            green: (color.green * 0.5).toDouble(),
            blue: (color.blue * 0.5).toDouble())
        : color;

    return Card(
      elevation: 4,
      shadowColor: Colors.black54,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              flex: 65,
              child: Container(
                width: double.infinity,
                color: color,
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Icon(icon,
                          size: 90, color: onColor.withValues(alpha: 0.12)),
                    ),
                    Center(child: Icon(icon, size: 52, color: onColor)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 35,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(subtitle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: darkColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefix;
  final Color accentColor;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefix,
    required this.accentColor,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: TextStyle(
                  color: accentColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
        ),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: inputFormatters,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12),
            prefixIcon: Icon(prefix, color: accentColor, size: 28),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentColor, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    const BorderSide(color: Colors.white12, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          ),
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: onColor, size: 24),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: onColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Función de autorización compartida (top-level)
// ─────────────────────────────────────────────────────────────────────────────

/// Construye la intención, invoca al hardware (APIs de Consola) y si hay éxito,
/// la registra en el ActiveDispatchManager para ser trackeada en UI.
Future<void> _authorizeDispatch({
  required BuildContext context,
  required PositionPhysical position,
  required HosePhysical hose,
  required PresetMode mode,
  required double? amount,
}) async {
  // Obtener usuario del cierre activo
  final user = context.read<CierreActivoProvider>().usuario;
  final tagId = user?.attendantId ?? '';
  if (user == null || tagId.isEmpty) {
    Fluttertoast.showToast(
      msg: 'Debes iniciar sesión para autorizar.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
    return;
  }

  // Comprobar si la manguera está disponible (de manera cruda desde la info física recibida hace un momento)
  if (hose.status.toLowerCase() != 'available' &&
      hose.status.toLowerCase() != 'blocked') {
    Fluttertoast.showToast(
      msg: 'La manguera no parece estar lista. Verifica su estado actual.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
    return;
  }

  // Mostrar loading preventivo
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Colors.blueAccent),
    ),
  );

  final nozzleCode = hose.nozzleNumber.toString().padLeft(2, '0');
  bool isSuccess = false;

  // Realizar llamada al API
  try {
    if (mode == PresetMode.full) {
      isSuccess = await ConsoleApiHelper.presetTankFull(
        nozzleCode: nozzleCode,
        tagId: tagId,
      );
    } else if (mode == PresetMode.volume && amount != null) {
      isSuccess = await ConsoleApiHelper.presetByVolume(
        nozzleCode: nozzleCode,
        liters: amount,
        tagId: tagId,
      );
    } else if (mode == PresetMode.amount && amount != null) {
      isSuccess = await ConsoleApiHelper.presetByAmount(
        nozzleCode: nozzleCode,
        amount: amount,
        tagId: tagId,
      );
    }
  } catch (e) {
    isSuccess = false;
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // cierra loading

  if (isSuccess) {
    // ÉXITO: Crear la nueva Session Intention y guardarla globalmente
    final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    final realStatus = NozzleStatus.fromString(
      context.read<MapProvider>().getStatus(nozzleCode) ?? 'unknown',
    );
    final session = DispatchSession(
      id: sessionId,
      position: position,
      hose: hose,
      fuel: hose.fuel,
      invoiceType: InvoiceType.contado,
      preset: mode == PresetMode.amount && amount != null
          ? PresetInfo.amount(amount)
          : mode == PresetMode.volume && amount != null
              ? PresetInfo.volume(amount)
              : PresetInfo.empty(),
      isTankFull: mode == PresetMode.full,
      userIdentifier: tagId,
      currentStatus: realStatus,
    );

    context.read<ActiveDispatchManager>().registerDispatch(session);

    Fluttertoast.showToast(
      msg: '✅ Despacho autorizado',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    // Volver al inicio del wizard (pop hasta la primera pantalla del flujo)
    Navigator.of(context).popUntil((route) => route.isFirst);
  } else {
    Fluttertoast.showToast(
      msg: '❌ Error al autorizar en el hardware. Intenta de nuevo.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
