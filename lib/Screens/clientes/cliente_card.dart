import 'package:flutter/material.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/Models/actividad_info.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/constans.dart';

class ClienteCard extends StatefulWidget {
  final Cliente cliente;
  final Invoice factura;
  final int index;

  // Callbacks
  final Function(Cliente e)? onInfoUser;
  final Function(String doc, int index)? onSyncActividades;
  final Function(String doc, int index)? onGetEmails;
  final Function(Cliente e, int index)? onEditarEmail;
  final Function(Cliente e, int index)? onAgregarEmail;

  // Estado por-card
  final bool isBusy;
  final String? statusText;

  // Flags de reuso
  final bool showEmails;
  final bool showActividades;
  final bool showSelectButton;
  final bool readOnly;
  final Color? backgroundColor;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.factura,
    required this.index,
    this.onInfoUser,
    this.onSyncActividades,
    this.onGetEmails,
    this.onEditarEmail,
    this.onAgregarEmail,
    this.isBusy = false,
    this.statusText,
    this.showEmails = true,
    this.showActividades = true,
    this.showSelectButton = true,
    this.readOnly = false,
    this.backgroundColor,
  });

  @override
  State<ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<ClienteCard> {
  String? selectedActividadCodigo;

  @override
  void initState() {
    super.initState();
    final e = widget.cliente;
    if (e.actividadSeleccionada != null) {
      selectedActividadCodigo = e.actividadSeleccionada!.codigo;
    } else if ((e.actividadesEconomicas?.isNotEmpty ?? false)) {
      final first = e.actividadesEconomicas!.first;
      selectedActividadCodigo = first.codigo;
      e.actividadSeleccionada = first;
    } else {
      selectedActividadCodigo = null;
    }
  }

  String actividadLabel(ActividadInfo a) {
    final tipo = (a.tipo ?? '').isEmpty ? '' : ' • ${a.tipo!.toUpperCase()}';
    final estado = (a.estado ?? '').isEmpty ? '' : ' (${a.estado})';
    return '${a.codigo} - ${a.descripcion}$tipo$estado';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.cliente;
    final bool hayActividades = (e.actividadesEconomicas?.isNotEmpty ?? false);
    final bool hasStatus = (widget.statusText != null && widget.statusText!.trim().isNotEmpty);

    // Contraste automático
    final Color cardBg = widget.backgroundColor ?? Theme.of(context).cardColor;
    final isDark = ThemeData.estimateBrightnessForColor(cardBg) == Brightness.dark;
    final Color onBg = isDark ? Colors.white : Colors.black87;
    final Color onBgMuted = isDark ? Colors.white70 : Colors.black54;

    final Color statusBg = _statusIsError(widget.statusText)
        ? Colors.red.withValues(alpha: 0.12)
        : Colors.green.withValues(alpha: 0.12);
    final Color statusFg = _statusIsError(widget.statusText)
        ? Colors.red
        : Colors.green;

    final bool disabled = widget.isBusy || widget.readOnly;

    // ====== EMAILS robusto ======
    final emails = _dedupeEmails(widget.cliente.emails);
    final selectedEmail = _selectedEmailOrNull(widget.cliente.email, emails);

    return Card(
      color: cardBg,
      shadowColor: kPrimaryColor,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Text(
              e.nombre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: onBg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              e.documento,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onBgMuted,
              ),
            ),

            // Estado / progreso
            const SizedBox(height: 8),
            if (widget.isBusy)
              LinearProgressIndicator(
                minHeight: 3,
                color: kPrimaryColor,
                backgroundColor: (isDark ? Colors.white10 : Colors.black12),
              )
            else if (hasStatus)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIsError(widget.statusText)
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 18,
                      color: statusFg,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.statusText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: statusFg, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // ====== Emails ======
            if (widget.showEmails) ...[
              DropdownButtonFormField<String>(
                key: ValueKey('emails-${widget.cliente.documento}-${emails.join("|")}'),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: onBgMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: onBgMuted.withValues(alpha: 0.4)),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                dropdownColor: cardBg,
                style: TextStyle(color: onBg),
                value: selectedEmail, // puede ser null
                hint: Text('Selecciona un email', style: TextStyle(color: onBgMuted)),
                onChanged: disabled
                    ? null
                    : (newValue) {
                        setState(() {
                          widget.cliente.email = newValue ?? '';
                          // asegúrate de dejar dedupe aplicado
                          widget.cliente.emails = _dedupeEmails(widget.cliente.emails);
                          if (newValue != null &&
                              !widget.cliente.emails.any((v) => v.toLowerCase() == newValue.toLowerCase())) {
                            widget.cliente.emails.insert(0, newValue);
                          }
                        });
                      },
                items: emails
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: onBg)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circleIconButton(
                    icon: Icons.edit,
                    color: Colors.orangeAccent,
                    onTap: disabled ? null : () => widget.onEditarEmail?.call(e, widget.index),
                  ),
                  _circleIconButton(
                    icon: Icons.refresh,
                    color: kBlueColorLogo,
                    onTap: disabled ? null : () => widget.onGetEmails?.call(e.documento, widget.index),
                  ),
                  _circleIconButton(
                    icon: Icons.add,
                    color: Colors.green,
                    onTap: disabled ? null : () => widget.onAgregarEmail?.call(e, widget.index),
                  ),
                ],
              ),

              const SizedBox(height: 14),
            ],

            // ====== ACTIVIDADES ======
            if (widget.showActividades) ...[
              Row(
                children: [
                  Icon(Icons.business_center, size: 18, color: onBg),
                  const SizedBox(width: 6),
                  Text('Actividades económicas',
                      style: TextStyle(fontWeight: FontWeight.bold, color: onBg)),
                ],
              ),
              const SizedBox(height: 8),

              if (!hayActividades)
                Column(
                  children: [
                    Text(
                      'Este cliente no tiene actividades en BD local.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onBgMuted),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_sync),
                      label: const Text('Cargar desde Hacienda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onBg,
                        side: BorderSide(color: onBgMuted.withValues(alpha: 0.6)),
                      ),
                      onPressed: disabled ? null : () => widget.onSyncActividades?.call(e.documento, widget.index),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (e.actividadSeleccionada != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: onBgMuted.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: onBg),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${e.actividadSeleccionada!.codigo} • ${e.actividadSeleccionada!.descripcion}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: onBg),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: e.actividadesEconomicas!.map((a) {
                        final selected = (e.actividadSeleccionada?.codigo == a.codigo);
                        final isPrincipal = (e.actividadPrincipal?.codigo == a.codigo);

                        return ChoiceChip(
                          selected: selected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(a.codigo ?? '', style: TextStyle(color: onBg)),
                              if (isPrincipal) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Principal', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ],
                          ),
                          onSelected: disabled ? null : (_) {
                            setState(() {
                              widget.cliente.actividadSeleccionada = a;
                              selectedActividadCodigo = a.codigo;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text('Re-sincronizar Hacienda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onBg,
                            side: BorderSide(color: onBgMuted.withValues(alpha: 0.6)),
                          ),
                          onPressed: disabled ? null : () => widget.onSyncActividades?.call(e.documento, widget.index),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 12),
            ],

            if (widget.showSelectButton)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  backgroundColor: isDark ? Colors.white : kPrimaryColor,
                  foregroundColor: isDark ? kPrimaryColor : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: disabled ? null : () => widget.onInfoUser?.call(e),
                child: const Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  bool _statusIsError(String? s) {
    if (s == null) return false;
    final t = s.trim().toLowerCase();
    return t.startsWith('error') || t.contains('error');
  }

  // === Helpers emails ===
  List<String> _dedupeEmails(List<String>? list) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in (list ?? const <String>[])) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      final key = v.toLowerCase();
      if (seen.add(key)) out.add(v);
    }
    return out;
  }

  String? _selectedEmailOrNull(String current, List<String> emails) {
    final cur = current.trim();
    if (cur.isEmpty) return null;
    final idx = emails.indexWhere((e) => e.toLowerCase() == cur.toLowerCase());
    return idx >= 0 ? emails[idx] : null;
  }

  Widget _circleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: (disabled ? Colors.grey : color).withValues(alpha: 0.15),
        child: Icon(icon, color: disabled ? Colors.grey : color, size: 20),
      ),
    );
  }
}
