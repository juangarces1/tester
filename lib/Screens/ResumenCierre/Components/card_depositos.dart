import 'package:flutter/material.dart';
import 'package:tester/Models/deposito.dart';
import 'package:tester/helpers/varios_helpers.dart';


class CardDepositoCierre extends StatelessWidget {
  
  final List<Deposito> depositos;
  final Color baseColor; 
  final Color foreColor;

  const CardDepositoCierre({super.key,  required this.depositos, required this.baseColor, required this.foreColor});

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
        title: Text('Depositos', style: TextStyle(color: foreColor,fontWeight: FontWeight.bold,)),
        children: depositos.map((entry) {
         
           return Container(
              color: VariosHelpers.getShadedColor(entry.iddeposito.toString(), baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.moneda!, style:  TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                  Expanded(
                    child: Text(
                       VariosHelpers.formattedToCurrencyValue(entry.monto.toString()),
                      
                      textAlign: TextAlign.right,
                      style:  TextStyle(color: foreColor,fontWeight: FontWeight.bold,),
                    ),
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
