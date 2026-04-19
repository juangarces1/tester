import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

class CardFinal extends StatefulWidget {
  final Future Function()? precierrePress;
  final Future Function()? cierrePress;
  final bool showButton;

  /// Estado actual del cierre — se usa para deshabilitar acciones ya
  /// realizadas (p.ej. Pre-Cierre queda disabled si el cierre ya está STANBY
  /// o REVISADO).
  final String? estado;

  const CardFinal({
    super.key,
    required this.precierrePress,
    this.cierrePress,
    required this.showButton,
    this.estado,
  });

  @override
  State<CardFinal> createState() => _CardFinalState();
}

class _CardFinalState extends State<CardFinal> {
  bool _busyPre = false;
  bool _busyFin = false;

  bool get _anyBusy => _busyPre || _busyFin;

  Future<void> _confirmAndPreCierre() async {
    if (widget.precierrePress == null || _anyBusy) return;

    final ok = await _confirm(
      accent: const Color(0xFFF59E0B),
      icon: Icons.pause_circle_rounded,
      title: 'Pasar a Pre-Cierre',
      body:
          'Marca el turno como STANBY para que puedas revisar el cuadre aparte. El siguiente cajero puede abrir su turno mientras tanto. Se puede revertir con una factura nueva.',
      confirmLabel: 'Pasar a STANBY',
    );
    if (ok != true) return;

    setState(() => _busyPre = true);
    try {
      await widget.precierrePress!();
    } finally {
      if (mounted) setState(() => _busyPre = false);
    }
  }

  Future<void> _confirmAndClose() async {
    if (widget.cierrePress == null || _anyBusy) return;

    final ok = await _confirm(
      accent: const Color(0xFFD64045),
      icon: Icons.warning_amber_rounded,
      title: 'Finalizar cierre',
      body:
          'Emite el ticket de cuadre, respalda el inventario final y marca el cierre como REVISADO. No se puede deshacer.',
      confirmLabel: 'Finalizar',
    );
    if (ok != true) return;

    setState(() => _busyFin = true);
    try {
      await widget.cierrePress!();
    } finally {
      if (mounted) setState(() => _busyFin = false);
    }
  }

  Future<bool?> _confirm({
    required Color accent,
    required IconData icon,
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNewsurfaceHi,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: kNewtextPri,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(color: kNewtextSec, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: kNewtextMut),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(icon, size: 20),
            label: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = (widget.estado ?? '').toUpperCase();
    final yaStanby = estado == 'STANBY' || estado == 'REVISADO';
    final yaCerrado = estado == 'REVISADO';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          _actionButton(
            label: yaStanby
                ? 'Pre-Cierre aplicado'
                : (_busyPre ? 'Procesando…' : 'Pre-Cierre'),
            icon: yaStanby
                ? Icons.check_circle_rounded
                : Icons.pause_circle_rounded,
            busy: _busyPre,
            enabled: !_anyBusy && !yaStanby,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            shadow: const Color(0xFFF59E0B),
            onTap: _confirmAndPreCierre,
          ),
          const SizedBox(height: 10),
          _actionButton(
            label: yaCerrado
                ? 'Cierre finalizado'
                : (_busyFin ? 'Cerrando…' : 'Finalizar Cierre'),
            icon: yaCerrado ? Icons.check_circle_rounded : Icons.lock_rounded,
            busy: _busyFin,
            enabled: !_anyBusy && !yaCerrado,
            gradient: const [Color(0xFFD64045), Color(0xFFB91C1C)],
            shadow: const Color(0xFFD64045),
            onTap: _confirmAndClose,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool busy,
    required bool enabled,
    required List<Color> gradient,
    required Color shadow,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? gradient
                : const [Color(0xFF4B5563), Color(0xFF374151)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (enabled ? shadow : Colors.black).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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
