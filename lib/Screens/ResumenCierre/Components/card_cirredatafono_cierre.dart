import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/cierredatafono.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardCierredatafonosCierre extends StatelessWidget {
  
  final List<CierreDatafono> cierredatafonos;
  final Color baseColor; 
  final Color foreColor;  

  const CardCierredatafonosCierre({super.key, 
    required this.cierredatafonos, 
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
        title: Text('Cieere Datafonos', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: cierredatafonos.map((entry) {         
           return Container(
              color: VariosHelpers.getShadedColor(entry.idcierredatafono.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.terminal!, style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
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
