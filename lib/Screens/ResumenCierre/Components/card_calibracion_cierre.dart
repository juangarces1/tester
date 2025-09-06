import 'package:flutter/material.dart';
import 'package:tester/Models/calibracion.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardCaliCierre extends StatelessWidget {
  
  final List<Calibracion> calibraciones;
  final Color baseColor; 
  final Color foreColor;
  

  const CardCaliCierre({super.key, 
   required this.calibraciones, 
   required this.baseColor, 
   required this.foreColor,
  
   
   });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: baseColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      child: ExpansionTile(
        collapsedIconColor: foreColor,
        iconColor: foreColor,
        title: Text('Calibraciones', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: calibraciones.map((entry) {
         
           return Container(
              color: VariosHelpers.getShadedColor(entry.idCalibraciones.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Disp ${entry.idDispensador} - ${entry.manguera!}', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                          VariosHelpers.formattedToCurrencyValue(entry.monto.toString()),
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),  
                   
                ],
              ),
            );
         
         // Retorna un contenedor vacío para 'cierres'
        }).toList(),
      ),
    );
  }

  

 

  

   




}
