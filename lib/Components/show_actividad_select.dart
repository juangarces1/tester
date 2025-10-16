import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/actividad_info.dart';
import 'package:tester/constans.dart';

class ShowActividadSelect extends StatelessWidget {
  final ActividadInfo actividad;
  final EdgeInsets? padding;

  const ShowActividadSelect({
    super.key,
    required this.actividad,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
        color: kColorFondoOscuro,
      ),
      child: Row(
        children: [
          const Icon(Icons.business_center, color: kPrimaryColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "${actividad.codigo} - ${actividad.descripcion}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
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
