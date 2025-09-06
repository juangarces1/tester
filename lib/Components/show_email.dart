import 'package:flutter/material.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';

class ShowEmail extends StatefulWidget {
  final String? email;
  final Color? backgroundColor;
  const ShowEmail({super.key, this.email, this.backgroundColor});

  @override
  State<ShowEmail> createState() => _ShowEmailState();
}

class _ShowEmailState extends State<ShowEmail> {
  @override
  Widget build(BuildContext context) {
    return Container(        
          decoration:   BoxDecoration( color: widget.backgroundColor ??  const Color.fromARGB(255, 9, 36, 67),
           
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
            
         
          ),),
    
          
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,        
            children: [                   
               Container(
                padding: const EdgeInsets.all(10),
                height: 50,
                width: getProportionateScreenWidth(50),
                decoration: const BoxDecoration(
                  // Resto del código...
                ),
                child: Image.asset( // Aquí es donde cambias a Image.asset
                  "assets/email.png", // Cambia la ruta del archivo a la imagen correspondiente
                 fit: BoxFit.cover, // Puedes ajustar cómo se muestra la imagen con BoxFit
                ),
              ),
              const SizedBox(width: 10,),        
              Flexible(
                child: Text(
                   widget.email??'',
                    style:  const TextStyle(
                    color: Colors.white),),
              ),
              
             
            ],
          ),
        );
  }
}