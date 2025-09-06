import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';

import 'package:tester/Screens/clientes/cliente_frec_screen.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';


class ClientPoints extends StatelessWidget {
  final Invoice factura;
  final String ruta;
  const ClientPoints({super.key, required this.factura, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return InkWell(
     
       onTap: () => Navigator.push(context,  MaterialPageRoute(
                     builder: (context) => ClientesFrecScreen(
                       factura: factura,                      
                       ruta: ruta,
                     )
                     )),
     
      child: Container(
        decoration: BoxDecoration(
          color: kNewborder,
          border: Border.all(color: kTextColorWhite, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        height: 60,
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [                   
              Container(
                padding: const EdgeInsets.all(10),
                height: getProportionateScreenWidth(40),
                width: getProportionateScreenWidth(40),
                decoration: BoxDecoration(
                  color: kContrateFondoOscuro,
                  borderRadius: BorderRadius.circular(10),
                ),
                // ignore: deprecated_member_use
                child: SvgPicture.asset("assets/User Icon.svg", color:  factura.formPago!.clientePuntos.nombre == "" ? kTextColor : kPrimaryColor,),
              ),
              const SizedBox(width: 10,),               
              Expanded(
                child: Text(
                  factura.formPago!.clientePuntos.nombre == "" 
                  ? 'Seleccione Cliente Frecuente' 
                  : '${factura.formPago!.clientePuntos.nombre}(${factura.formPago!.clientePuntos.puntos})',               
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                     color:Colors.white,
                  )),
              ),
             
              
            ],
          ),
        ),
      ),
    );     
  }
}