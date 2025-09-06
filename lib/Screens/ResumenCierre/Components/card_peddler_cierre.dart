import 'package:flutter/material.dart';
import 'package:tester/Models/peddler.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardPeddlerCierre extends StatelessWidget {
  
  final List<Peddler> peddlers;
  final Color baseColor; 
  final Color foreColor;  

  const CardPeddlerCierre({super.key, 
    required this.peddlers, 
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
        title: Text('Peddler', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: peddlers.map((entry) {         
           return Container(
              color: VariosHelpers.getShadedColor(entry.id.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                     
                      Expanded(
                        child: Text(
                          entry.cliente!.nombre??'',
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                         'Orden  ${entry.orden}',
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                       const SizedBox(width: 10,),
                      Text('Total: ${VariosHelpers.formattedToCurrencyValue(entry.total.toString())}', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
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
