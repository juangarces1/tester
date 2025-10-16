import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/tarjeta.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardTarjetasCierre extends StatelessWidget {
  
  final List<Tarjeta> tarjetas;
  final Color baseColor; 
  final Color foreColor;  

  const CardTarjetasCierre({super.key, 
    required this.tarjetas, 
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
        title: Text('Tarjetas', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: tarjetas.map((entry) {         
           return Container(
              color: VariosHelpers.getShadedColor(entry.idCanjeo.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
              
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                         '#  ${entry.idTarjeta}',
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                       const SizedBox(width: 10,),
                      Text('Total: ${VariosHelpers.formattedToCurrencyValue(entry.monto.toString())}', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
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
