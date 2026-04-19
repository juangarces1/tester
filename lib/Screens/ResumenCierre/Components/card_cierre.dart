import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/FuelRed/cierrefinal.dart';
import 'package:tester/Models/FuelRed/empleado.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

class CardCierre extends StatefulWidget {
  final Function? onTapCallback;
  final bool showButton;
  const CardCierre({
    super.key,
    this.onTapCallback,
    required this.showButton,
  });

  @override
  State<CardCierre> createState() => _CardCierreState();
}

class _CardCierreState extends State<CardCierre> {
  late CierreFinal cierre;
  late Empleado cajero;

  @override
  void initState() {
    super.initState();
    cierre =
        Provider.of<CierreActivoProvider>(context, listen: false).cierreFinal!;
    cajero = Provider.of<CierreActivoProvider>(context, listen: false).cajero!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Material(
        color: kNewsurfaceHi,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kNewborder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cajero.nombre} ${cajero.apellido1}',
                          style: const TextStyle(
                            color: kNewtextPri,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Cajero del turno',
                          style: TextStyle(
                            color: kNewtextMut,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _EstadoChip(estado: cierre.estado ?? ''),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kNewborder),
                ),
                child: Column(
                  children: [
                    _row('Fecha',
                        cierre.fechafinalcierre != null
                            ? VariosHelpers.formatYYYYmmDD(
                                cierre.fechafinalcierre!)
                            : '—'),
                    const SizedBox(height: 8),
                    _row('Turno', cierre.turno ?? '—'),
                    const SizedBox(height: 8),
                    _row('Zona', cierre.idzona?.toString() ?? '—'),
                  ],
                ),
              ),
              if (widget.showButton) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => widget.onTapCallback?.call(),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF0EA5E9)),
                    label: const Text(
                      'Ver detalle',
                      style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.w700,
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

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: kNewtextMut,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: kNewtextPri,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final e = estado.toUpperCase();
    final (bg, fg) = switch (e) {
      'ABIERTO'  => (kNewgreen.withValues(alpha: 0.16), kNewgreen),
      'STANBY'   => (const Color(0xFFF59E0B).withValues(alpha: 0.16),
                     const Color(0xFFF59E0B)),
      'REVISADO' => (const Color(0xFF60A5FA).withValues(alpha: 0.18),
                     const Color(0xFF60A5FA)),
      _ => (kNewtextMut.withValues(alpha: 0.18), kNewtextMut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        e.isEmpty ? 'N/A' : e,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
