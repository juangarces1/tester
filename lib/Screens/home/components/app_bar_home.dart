import 'package:flutter/material.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/constans.dart';


class AppBarHome extends StatelessWidget {
  const AppBarHome({
    super.key,
   
    required this.factura, 
   
  });
 
  final AllFact factura;
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
     
       padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          
          gradient: kGradientHome,
        
        ),
        child:  Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido ${factura.cierreActivo!.usuario.nombre} ${factura.cierreActivo!.usuario.apellido1}',
                      style:  const TextStyle(
                      fontStyle: FontStyle.normal, 
                      fontSize: 18,
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                  )),
                  const SizedBox(height: 10,),
                  Text(
                    'Cajero: ${factura.cierreActivo!.cajero.nombre} ${factura.cierreActivo!.cajero.apellido1}',
                      style:  const TextStyle(
                      fontStyle: FontStyle.normal, 
                      fontSize: 18,
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                  )),
                ],
                
              ),
             
            ],
          ),
        )),
    );
  }
}