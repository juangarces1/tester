import 'package:flutter/material.dart';
import 'package:tester/Models/factura.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardFacturasCierre extends StatelessWidget {
  
  final List<Factura> facturas;
  final Color baseColor; 
  final Color foreColor;
  final String title;

  const CardFacturasCierre({super.key, 
   required this.facturas, 
   required this.baseColor, 
   required this.foreColor,
    required this.title
   
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
        title: Text(title, style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: facturas.map((entry) {
         
           return Container(
              color: VariosHelpers.getShadedColor(entry.clave.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
              entry.cliente.isNotEmpty ?      Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cliente:', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           entry.cliente,
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ): Container(),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text( entry.cliente.isNotEmpty ?   'Factura #' : 'Ticket #', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           entry.nFactura,
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           VariosHelpers.formattedToCurrencyValue(entry.totalFactura.toString()),
                          
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
