import 'package:flutter/material.dart';
import 'package:tester/helpers/varios_helpers.dart';


class DepositosCustomCard extends StatelessWidget {
  final String title;
  final double valor;  
  final Color baseColor; 
  final Color foreColor;
  final String colorVariable;
  const DepositosCustomCard({super.key, 
   required this.title,   
   required this.baseColor, 
   required this.foreColor,
   required this.valor,
    required this.colorVariable,
   
  });

  @override
  Widget build(BuildContext context) {
    return Container(
              color: VariosHelpers.getShadedColor(colorVariable, baseColor), // Usa el color generado
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style:   TextStyle(fontWeight: FontWeight.bold, color: foreColor)),
                  Expanded(
                    child: Text(
                      VariosHelpers.formattedToCurrencyValue(valor.toString()),
                      
                      textAlign: TextAlign.right,
                      style:   TextStyle(color: foreColor, fontWeight: FontWeight.bold,),
                    ),
                  ),
                ],
              ),
            );
  }

  

 

  

   




}
