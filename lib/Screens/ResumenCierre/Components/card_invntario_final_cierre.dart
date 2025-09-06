import 'package:flutter/material.dart';
import 'package:tester/Models/linea_inventario.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardinventarioFinalCierre extends StatelessWidget {
  
  final List<LineaInventario> inventariofinal;
  final Color baseColor; 
  final Color foreColor;  

  const CardinventarioFinalCierre
  ({super.key, 
    required this.inventariofinal, 
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
        title: Text('Inventario ', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: inventariofinal.map((entry) {         
           return Container(
              color: VariosHelpers.getShadedColor(entry.articulo.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                     
                      Expanded(
                        child: Text(
                          entry.articulo.toString(),
                          
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
                         'Cantidad:',
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),

                        Text(
                         entry.cantidad.toString(),
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
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
