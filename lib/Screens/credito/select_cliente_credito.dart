import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/sizeconfig.dart';

import '../../constans.dart';


class SelectClienteCredito extends StatefulWidget {
  final Invoice factura;
  final String ruta;
  final EdgeInsets? padding;
  const SelectClienteCredito({
       super.key,
      required this.factura,
      required this.ruta,
      this.padding,
     });

  @override
  State<SelectClienteCredito> createState() => _SelectClienteCreditoState();
}

class _SelectClienteCreditoState extends State<SelectClienteCredito> {
  @override
  Widget build(BuildContext context) {
    return   InkWell(
        onTap: () => _goClientCredit(),
      child: Container(        
           height: 50,
           decoration: BoxDecoration(
            color: const Color.fromARGB(255, 224, 225, 230),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [  
              const Padding(
                padding: EdgeInsets.all(8.0),),                 
              Container(
                padding: const EdgeInsets.all(10),
                height: getProportionateScreenWidth(40),
                width: getProportionateScreenWidth(40),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 199, 201, 207),
                  borderRadius: BorderRadius.circular(10),
                ),
              // ignore: deprecated_member_use
              child: SvgPicture.asset("assets/User Icon.svg", color:  widget.factura.formPago!.clientePuntos.nombre == '' ? kTextColor : kPrimaryColor,),
              ),
              const SizedBox(width: 10,),               
              Expanded(child: Text(widget.factura.formPago!.clientePuntos.nombre == "" ? "Seleccione Un Cliente": widget.factura.formPago!.clientePuntos.nombre)),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: kTextColor,
              ),
              const SizedBox(width: 10)
            ],
          ),
        ),
    );
  }
  _goClientCredit() {
    // Navigator.push
    // (context,
    //     MaterialPageRoute(
    //       builder: (context) =>
    //         ClientesNewCredito(
    //           factura: widget.factura,                 
    //           ruta: widget.ruta,)
    //     )
    // ); 
  }
}