import 'package:flutter/material.dart';
import 'package:tester/Models/cierreactivo.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';


class CardCierre extends StatelessWidget {
  final CierreActivo cierre;
  final Function? onTapCallback; 
  final bool showButton;
  const CardCierre({super.key, required this.cierre, this.onTapCallback, required this.showButton});

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                   SizedBox(
                   width: 90,
                   child: AspectRatio(
                     aspectRatio: 0.88,
                     child: Container(
                       padding: EdgeInsets.all(getProportionateScreenWidth(5)),
                       decoration: const BoxDecoration(
                         color: Colors.white,
                           borderRadius: BorderRadius.only(topLeft: Radius.circular(15) , bottomLeft: Radius.circular(15))
                       ),
                       child:  const Image(
                                   image: AssetImage('assets/cierre1.png'),
                               ),
                     ),
                   ),
                 ),                         
                 const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cierre #: ${cierre.cierreFinal.idcierre.toString()}',
                        style: const TextStyle(color: kPrimaryColor, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                      Text(
                        'Fecha: ${VariosHelpers.formatYYYYmmDD(cierre.cierreFinal.fechafinalcierre!)}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                        Text(
                        'Cajero: ${cierre.cajero.nombre} ${cierre.cajero.apellido1}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
      
                        Text(
                        'Zona: ${cierre.cierreFinal.idzona}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                    
                      Text(
                          'Turno  ${cierre.cierreFinal.turno}',
                          style: const TextStyle(
                          fontWeight: FontWeight.w700, color:  Colors.black,),
                        ),

                       Text(
                          'Estado  ${cierre.cierreFinal.estado}',
                          style: const TextStyle(
                          fontWeight: FontWeight.w700, color:  Colors.black,),
                        ),  
                    ],
                  ),
                ),
               
                // make an icon indicates to click and show more info
                showButton ?     SizedBox(
                        width: 50,
                        height: 50, // Asegúrate de establecer una altura
                        child: ElevatedButton(
                          onPressed: () {
                            // Verificar si el callback está presente antes de llamarlo
                            if (onTapCallback != null) {
                              onTapCallback!();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(), // Asegura que el botón sea circular
                            padding: EdgeInsets.zero, // Elimina el padding por defecto
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/Forward.png',
                              width: 50, // Ajusta el ancho de la imagen
                              height: 50, // Ajusta la altura de la imagen
                              fit: BoxFit.cover, // Asegura que la imagen cubra el espacio
                            ),
                          ),
                        ),
                      ) : Container(),
              ],
            ),
          ),
        ),
    );
  }
}