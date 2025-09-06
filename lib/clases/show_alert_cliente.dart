import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/cliente.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';



class ShowAlertCliente {
  static Future<void> showAlert(
    BuildContext context,
    Cliente client,
    Function? press,
      ) async {
    return  showDialog(
    context: context,
    builder: (context) {
        return AlertDialog(
          title: const Center(child: Text(
            'Cliente Contado',
            style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                      color: kPrimaryText,
                  ),
            )),
          content:  client.nombre == "" 
          ? const SizedBox(
              height: 50,
            child: Center(
              child: Text('No Hay Cliente Seleccionado')))
          :  Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget> [  
              Center(
                child: Container(
                    padding: const EdgeInsets.all(10),
                    height: getProportionateScreenWidth(40),
                    width: getProportionateScreenWidth(40),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:  kPrimaryText,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                          
                  // ignore: deprecated_member_use
                  child: SvgPicture.asset("assets/User Icon.svg",
                  // ignore: deprecated_member_use
                  color:  client.nombre == '' ? Colors.white : kPrimaryColor, ),
                  ),
              ),    
              const SizedBox(height: 20,),    
                Text(
                 'Nombre: ${client.nombre}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                      color: Colors.black87,
                  ),
                ),
              
              const Divider(height: 10, thickness: 1, color: kColorFondoOscuro,),
                Text(
                'Documento: ${client.documento}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                      color: Colors.black87,
                  ),
                ),
               const Divider(height: 10, thickness: 1, color: kColorFondoOscuro,),
              Text(
                  'Email: ${client.email}',
                  style: const TextStyle(
                  fontSize: 14,
                    fontWeight: FontWeight.bold,
                      color: Colors.black87,
                  ),
                ),
            ]                   
          ),
          actions: <Widget>[
            TextButton(
              onPressed: press as void Function()?, 
              child:  client.nombre == "" ? const Text('Seleccionar') : const Text('Cambiar')
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Salir')
            ),
          ],

        );
    } 
  );
  }

  
  
}
