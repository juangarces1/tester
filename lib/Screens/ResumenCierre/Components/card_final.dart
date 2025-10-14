import 'package:flutter/material.dart';
import 'package:tester/Components/button_cierre.dart';
import 'package:tester/constans.dart';
class CardFinal extends StatelessWidget {
  
  final Future Function()? precierrePress; 
   final Future Function()? cierrePress; 
  final bool showButton;
  const CardFinal({super.key, required this.precierrePress, this.cierrePress, required this.showButton});

  @override
  Widget build(BuildContext context) {
     return  Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          color: Colors.white,                    
          shadowColor: kPrimaryColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
          ),
          child:  Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // make an icon indicates to click and show more info
               Expanded(child: ButtonCierre(text: "Pre-Cierre", gradient: kBlueGradient,color: kBlueColorLogo, press:  precierrePress, )),
                 Expanded(child: ButtonCierre(text: "Cierre", gradient: kPrimaryGradientColor,color: kPrimaryColor, press: cierrePress, )),
              ],
            ),
          ),
        ),
    );
  }
}