import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/sinpe.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardSinpecierre extends StatelessWidget {
  
  final List<Sinpe> sinpes;
  final Color baseColor; 
  final Color foreColor;  

  const CardSinpecierre({super.key, 
    required this.sinpes, 
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
        title: Text('Sinpes', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: sinpes.map((entry) {         
           return Container(
              color: VariosHelpers.getShadedColor(entry.id.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.numComprobante, style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
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
