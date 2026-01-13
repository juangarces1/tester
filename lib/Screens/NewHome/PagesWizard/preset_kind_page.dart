// lib/Screens/Dispatch/preset_step_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Screens/NewHome/PagesWizard/dispatch_summary_page.dart';
import 'package:tester/helpers/varios_helpers.dart';

class PresetStepPage extends StatelessWidget {
  final String dispatchId;
  const PresetStepPage({super.key, required this.dispatchId});

  @override
  Widget build(BuildContext context) {
    final despachosProv =
        Provider.of<DespachosProvider>(context, listen: false);
    final dispatch = despachosProv.getById(dispatchId)!;

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PresetKindPage(
                      onAmountChosen: (amount) {
                        final nozzle =
                            dispatch.selectedHose!.nozzleNumber.toString();
                        dispatch.setPresetByAmount(
                            manguera: nozzle, amount: amount);
                        despachosProv.refresh();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DispatchSummaryPage(dispatchId: dispatchId)),
                        );
                      },
                      onVolumeChosen: (liters) {
                        final nozzle =
                            dispatch.selectedHose!.nozzleNumber.toString();
                        dispatch.setPresetByVolume(
                            manguera: nozzle, liters: liters);
                        despachosProv.refresh();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DispatchSummaryPage(dispatchId: dispatchId)),
                        );
                      },
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
              onTap: () {
                dispatch.setTankFull(true);
                despachosProv.refresh();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DispatchSummaryPage(dispatchId: dispatchId)),
                );
              },
            ),
          ],
        ),
      ),
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
    // Dynamic contrast for icons/text on color block
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    // Deep shade for footer text
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
            // Dominant Color Block (65%)
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
                      child: Icon(
                        icon,
                        size: 90,
                        color: onColor.withValues(alpha: 0.12),
                      ),
                    ),
                    Center(
                      child: Icon(icon, size: 52, color: onColor),
                    ),
                  ],
                ),
              ),
            ),
            // White Info Footer (35%)
            Expanded(
              flex: 35,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
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

class PresetKindPage extends StatelessWidget {
  final void Function(double amount) onAmountChosen;
  final void Function(double liters) onVolumeChosen;
  const PresetKindPage(
      {super.key, required this.onAmountChosen, required this.onVolumeChosen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Tipo de Preset',
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
              title: 'PRESET MONTO',
              subtitle: 'Autoriza dinero (₡)',
              icon: Icons.money,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreDispenseAmountFormPage(
                        onPresetAmountChosen: (v) => onAmountChosen(v)),
                  ),
                );
              },
            ),
            _HeroActionCard(
              title: 'PRESET VOLUMEN',
              subtitle: 'Autoriza litros (L)',
              icon: Icons.local_gas_station,
              color: Colors.tealAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreDispenseVolumeFormPage(
                        onPresetVolumeChosen: (v) => onVolumeChosen(v)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PreDispenseAmountFormPage extends StatefulWidget {
  final void Function(double amount) onPresetAmountChosen;
  const PreDispenseAmountFormPage(
      {required this.onPresetAmountChosen, super.key});

  @override
  State<PreDispenseAmountFormPage> createState() =>
      _PreDispenseAmountFormPageState();
}

class _PreDispenseAmountFormPageState extends State<PreDispenseAmountFormPage> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Monto de Preset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                 _quickAmountChip(1000),
                _quickAmountChip(2000),
                _quickAmountChip(5000),
                _quickAmountChip(10000),
                _quickAmountChip(20000),
                _quickAmountChip(50000),
              ],
            ),
            const Spacer(),
            _LabeledField(
              label: 'Monto a Despachar',
              controller: _ctrl,
              hint: '0.00',
              prefix: Icons.money,
              accentColor: Colors.blueAccent,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
            ),
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
            const Spacer(),
            _HeroButton(
              color: Colors.blueAccent,
              label: 'CONFIRMAR MONTO',
              icon: Icons.check_circle_outline,
              onTap: () {
                final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  setState(() => _error = 'Ingresa un monto válido');
                  return;
                }
                widget.onPresetAmountChosen(v);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _setQuickAmount(double v) {
    final s = v.toStringAsFixed(0);
    _ctrl.text = s;
    _ctrl.selection = TextSelection.collapsed(offset: s.length);
    setState(() => _error = null);
  }

  Widget _quickAmountChip(double v) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: const BorderSide(color: Colors.blueAccent, width: 1.5),
    
      label: Text(VariosHelpers.formattedToCurrencyValue(v.toString()),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => _setQuickAmount(v),
    );
  }
}

class PreDispenseVolumeFormPage extends StatefulWidget {
  final void Function(double liters) onPresetVolumeChosen;
  const PreDispenseVolumeFormPage(
      {required this.onPresetVolumeChosen, super.key});

  @override
  State<PreDispenseVolumeFormPage> createState() =>
      _PreDispenseVolumeFormPageState();
}

class _PreDispenseVolumeFormPageState extends State<PreDispenseVolumeFormPage> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Volumen de Preset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _quickVolumeChip(10),
                _quickVolumeChip(20),
                _quickVolumeChip(50),
                _quickVolumeChip(100),
                _quickVolumeChip(200),
              ],
            ),
            const Spacer(),
            _LabeledField(
              label: 'Litros a Despachar',
              controller: _ctrl,
              hint: '0.00',
              prefix: Icons.local_gas_station,
              accentColor: Colors.tealAccent,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
            ),
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
            const Spacer(),
            _HeroButton(
              color: Colors.tealAccent,
              label: 'CONFIRMAR VOLUMEN',
              icon: Icons.check_circle_outline,
              onTap: () {
                final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  setState(() => _error = 'Ingresa un volumen válido');
                  return;
                }
                widget.onPresetVolumeChosen(v);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _setQuickLiters(double v) {
    final s = v.toStringAsFixed(2);
    _ctrl.text = s;
    _ctrl.selection = TextSelection.collapsed(offset: s.length);
    setState(() => _error = null);
  }

  Widget _quickVolumeChip(double v) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: const BorderSide(color: Colors.tealAccent, width: 1.5),
      avatar: const Icon(Icons.gas_meter_outlined,
          size: 18, color: Colors.tealAccent),
      label: Text('${v.toStringAsFixed(0)} L',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () => _setQuickLiters(v),
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
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
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
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white12, width: 1.5),
            ),
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
      height: 70, // Tall and heroic
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
