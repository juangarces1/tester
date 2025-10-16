import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/transparcial.dart';
import 'package:tester/helpers/varios_helpers.dart';



class CardTransferenciaCierre extends StatelessWidget {
  
  final List<TransParcial> transfers;
  final Color baseColor; 
  final Color foreColor;
  

  const CardTransferenciaCierre({super.key, 
   required this.transfers, 
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
        title: Text('Transferencias', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: transfers.map((entry) {
         
           return Container(
              color: VariosHelpers.getShadedColor(entry.id.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                Row(
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
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(  'Transferencia #' , style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           entry.numeroDeposito,
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Aplicado', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           VariosHelpers.formattedToCurrencyValue(entry.aplicado.toString()),
                          
                          textAlign: TextAlign.right,
                          style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Saldo:', style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                      Expanded(
                        child: Text(
                           VariosHelpers.formattedToCurrencyValue(entry.saldo.toString()),
                          
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
