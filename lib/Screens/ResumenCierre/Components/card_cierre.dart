import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tester/Models/cierrefinal.dart';
import 'package:tester/Models/empleado.dart';
import 'package:tester/Providers/cierre_activo_provider.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';
import 'package:tester/sizeconfig.dart';


class CardCierre extends StatefulWidget {
  
  final Function? onTapCallback; 
  final bool showButton;
  const CardCierre({super.key,  this.onTapCallback, required this.showButton});

  @override
  State<CardCierre> createState() => _CardCierreState();
}

class _CardCierreState extends State<CardCierre> {


 late CierreFinal cierre;
 late Empleado cajero;

 @override
  void initState() {
    
    super.initState();
    cierre = Provider.of<CierreActivoProvider>(context, listen: false).cierreFinal!;
    cajero = Provider.of<CierreActivoProvider>(context, listen: false).cajero!;
  }

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
                        'Cierre #: ${cierre.idcierre.toString()}',
                        style: const TextStyle(color: kPrimaryColor, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                      Text(
                        'Fecha: ${VariosHelpers.formatYYYYmmDD(cierre.fechafinalcierre!)}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                        Text(
                        'Cajero: ${cajero.nombre} ${cajero.apellido1}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
      
                        Text(
                        'Zona: ${cierre.idzona}',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                    
                      Text(
                          'Turno  ${cierre.turno}',
                          style: const TextStyle(
                          fontWeight: FontWeight.w700, color:  Colors.black,),
                        ),

                       Text(
                          'Estado  ${cierre.estado}',
                          style: const TextStyle(
                          fontWeight: FontWeight.w700, color:  Colors.black,),
                        ),  
                    ],
                  ),
                ),
               
                // make an icon indicates to click and show more info
                widget.showButton ?     SizedBox(
                        width: 50,
                        height: 50, // Asegúrate de establecer una altura
                        child: ElevatedButton(
                          onPressed: () {
                            // Verificar si el callback está presente antes de llamarlo
                            if (widget.onTapCallback != null) {
                              widget.onTapCallback!();
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