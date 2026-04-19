import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/constans.dart';

/// Card del empleado (modal de sesión) en dark theme — coherente con
/// form_pago_v2, resumen_cierre y otras pantallas redesign.
class EmpleadoInfoCard extends StatelessWidget {
  final Empleado empleado;
  final VoidCallback? onTap;
  final bool showAttendantId;

  /// Callback para cerrar sesión. Si se provee, se muestra un botón
  /// al pie de la card.
  final VoidCallback? onLogout;

  const EmpleadoInfoCard({
    super.key,
    required this.empleado,
    this.onTap,
    this.showAttendantId = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kNewsurfaceHi,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNewborder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con avatar + nombre + badge de tipo
              Row(
                children: [
                  _Avatar(initials: _getInitials()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empleado.nombreCompleto,
                          style: const TextStyle(
                            color: kNewtextPri,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _Badge(text: empleado.tipoempleado),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _InfoRow(
                icon: Icons.credit_card_rounded,
                label: 'Cédula',
                value: empleado.cedulaEmpleado.toString(),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Tipo',
                value: empleado.tipoempleado.isEmpty
                    ? 'No asignado'
                    : empleado.tipoempleado,
              ),

              if (showAttendantId && empleado.attendantId != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.qr_code_rounded,
                  label: 'Attendant ID',
                  value: empleado.attendantId!,
                ),
              ],

              if (onLogout != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD64045), Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD64045)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: onLogout,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final first = empleado.nombre.trim();
    final last = empleado.apellido1.trim();
    var initials = '';
    if (first.isNotEmpty) initials += first[0].toUpperCase();
    if (last.isNotEmpty) initials += last[0].toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined,
              size: 14, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 6),
          Text(
            text.isEmpty ? 'N/A' : text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0EA5E9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kNewborder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kNewtextMut,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kNewtextPri,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version para listas (se mantiene en dark theme).
class EmpleadoListTile extends StatelessWidget {
  final Empleado empleado;
  final VoidCallback? onTap;

  const EmpleadoListTile({
    super.key,
    required this.empleado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: kNewsurfaceHi,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
        child: Text(
          _getInitials(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        empleado.nombreCompleto,
        style: const TextStyle(
          color: kNewtextPri,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 14, color: kNewtextMut),
              const SizedBox(width: 4),
              Text(empleado.tipoempleado,
                  style: const TextStyle(color: kNewtextSec)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 14, color: kNewtextMut),
              const SizedBox(width: 4),
              Text(
                empleado.turno.isEmpty ? 'Sin turno' : empleado.turno,
                style: const TextStyle(color: kNewtextSec),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: kNewtextMut),
    );
  }

  String _getInitials() {
    final first = empleado.nombre.trim();
    final last = empleado.apellido1.trim();
    var initials = '';
    if (first.isNotEmpty) initials += first[0].toUpperCase();
    if (last.isNotEmpty) initials += last[0].toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}
