// lib/Screens/Dispatch/preset_step_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tester/Providers/despachos_provider.dart';
import 'package:tester/Screens/NewHome/Components/menu_page.dart';
import 'package:tester/Screens/NewHome/PagesWizard/dispatch_summary_page.dart';


class PresetStepPage extends StatelessWidget {
  final String dispatchId;
  const PresetStepPage({super.key, required this.dispatchId});

  @override
  Widget build(BuildContext context) {
    final despachosProv = Provider.of<DespachosProvider>(context, listen: false);
    final dispatch = despachosProv.getById(dispatchId)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('4. Preset / Tanque lleno', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            _ActionCard(
              title: 'Pre-despacho',
              subtitle: 'Configura por monto o por volumen',
              icon: Icons.tune,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PresetKindPage(
                      onAmountChosen: (amount) {
                        final nozzle = dispatch.selectedHose!.nozzleNumber.toString();
                        dispatch.setPresetByAmount(manguera: nozzle, amount: amount);
                        despachosProv.refresh();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => DispatchSummaryPage(dispatchId: dispatchId)),
                        );
                      },
                      onVolumeChosen: (liters) {
                        final nozzle = dispatch.selectedHose!.nozzleNumber.toString();
                        dispatch.setPresetByVolume(manguera: nozzle, liters: liters);
                        despachosProv.refresh();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => DispatchSummaryPage(dispatchId: dispatchId)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _ActionCard(
              title: 'Tanque lleno',
              subtitle: 'Deja que la bomba llene el tanque',
              icon: Icons.water_drop,
              color: Colors.green,
              onTap: () {
                dispatch.setTankFull(true);
                despachosProv.refresh();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DispatchSummaryPage(dispatchId: dispatchId)),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c1 = color.withOpacity(0.95);
    final c2 = color.withOpacity(0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PresetKindPage extends StatelessWidget {
  final void Function(double amount) onAmountChosen;
  final void Function(double liters) onVolumeChosen;
  const PresetKindPage({super.key, required this.onAmountChosen, required this.onVolumeChosen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Selecciona tipo de Preset', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menú',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            _ChoiceCard(
              title: 'Preset por Monto',
              subtitle: 'Autoriza por valor en dinero',
              icon: Icons.attach_money,
              accent: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreDispenseAmountFormPage(onPresetAmountChosen: (v) => onAmountChosen(v)),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _ChoiceCard(
              title: 'Preset por Volumen',
              subtitle: 'Autoriza por litros',
              icon: Icons.local_gas_station,
              accent: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreDispenseVolumeFormPage(onPresetVolumeChosen: (v) => onVolumeChosen(v)),
                  ),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent.withOpacity(0.9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreDispenseAmountFormPage extends StatefulWidget {
  final void Function(double amount) onPresetAmountChosen;
  const PreDispenseAmountFormPage({required this.onPresetAmountChosen, super.key});

  @override
  State<PreDispenseAmountFormPage> createState() => _PreDispenseAmountFormPageState();
}

class _PreDispenseAmountFormPageState extends State<PreDispenseAmountFormPage> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Preset por Monto', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menú',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _quickAmountChip(2000),
                   _quickAmountChip(3000),
                  _quickAmountChip(4000),
                  _quickAmountChip(5000),
                  _quickAmountChip(10000),                  
                  _quickAmountChip(20000),
                ],
              ),
            const Spacer(),
            _LabeledField(
              label: 'Monto (\$)',
              controller: _ctrl,
              hint: '0.00',
              prefix: Icons.attach_money,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 22),
            _GradientButton(
              color: Colors.blue,
              label: 'Continuar',
              icon: Icons.check,
              onTap: () {
                final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  setState(() => _error = 'Ingresa un monto válido');
                  return;
                }
                widget.onPresetAmountChosen(v);
              },
            ),
            const Spacer(flex: 2),
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
    backgroundColor: const Color(0xFF101010),
    side: const BorderSide(color: Colors.blueAccent),
    avatar: const Icon(Icons.flash_on, size: 18, color: Colors.white70),
    label: Text('\$${v.toStringAsFixed(0)}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    onPressed: () => _setQuickAmount(v),
  );
}
}

class PreDispenseVolumeFormPage extends StatefulWidget {
  final void Function(double liters) onPresetVolumeChosen;
  const PreDispenseVolumeFormPage({required this.onPresetVolumeChosen, super.key});

  @override
  State<PreDispenseVolumeFormPage> createState() => _PreDispenseVolumeFormPageState();
}

class _PreDispenseVolumeFormPageState extends State<PreDispenseVolumeFormPage> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Preset por Volumen', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ir al menú',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             const Spacer(),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _quickVolumeChip(100),
                _quickVolumeChip(200),
                _quickVolumeChip(500),
                _quickVolumeChip(60),
                _quickVolumeChip(20),
                _quickVolumeChip(220),
              ],
            ),
           const Spacer(),
            _LabeledField(
              label: 'Volumen (L)',
              controller: _ctrl,
              hint: '0.00',
              prefix: Icons.local_gas_station,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 22),
            _GradientButton(
              color: Colors.teal,
              label: 'Continuar',
              icon: Icons.check,
              onTap: () {
                final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  setState(() => _error = 'Ingresa un volumen válido');
                  return;
                }
                widget.onPresetVolumeChosen(v);
              },
            ),
            const Spacer(flex: 2),
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
    backgroundColor: const Color(0xFF101010),
    side: const BorderSide(color: Colors.tealAccent),
    avatar: const Icon(Icons.local_gas_station, size: 18, color: Colors.white70),
    label: Text('${v.toStringAsFixed(0)} L',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    onPressed: () => _setQuickLiters(v),
  );
}
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefix;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(prefix, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF101010),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c1 = color.withOpacity(0.95);
    final c2 = color.withOpacity(0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
