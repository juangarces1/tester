import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/clientes/clientes_new_credito.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';
import 'package:provider/provider.dart';


class ShowClientCredito extends StatefulWidget {
  final int index;

  final EdgeInsets? padding;
  const ShowClientCredito({
       super.key,
      required this.index,
     
      this.padding,
     });

  @override
  State<ShowClientCredito> createState() => _ShowClientCreditoState();
}

class _ShowClientCreditoState extends State<ShowClientCredito> {
  @override
  Widget build(BuildContext context) {
    Invoice facturaC = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);
    return Container(
       padding:  widget.padding ?? const EdgeInsets.all(0),
       decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _goClientes(facturaC),
        child: Container(        
          decoration:  const BoxDecoration(color: Color.fromARGB(255, 9, 36, 67),
           
          borderRadius: BorderRadius.only(
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
                width: getProportionateScreenWidth(40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                    borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(3),
                  ),
                ),
                child: SvgPicture.asset(
                  "assets/User Icon.svg", 
                  // ignore: deprecated_member_use
                  color: facturaC.formPago!.clienteCredito.nombre == '' ? kTextColorBlack 
                  : kPrimaryColor,),
                  
              ),
              const SizedBox(width: 10,),        
              Flexible(
                child: Text(
                  facturaC.formPago!.clienteCredito.nombre == "" ? "Seleccione Un Cliente": facturaC.formPago!.clienteCredito.nombre,
                    style:  const TextStyle(
                      fontSize: 15,
                    color: Colors.white),),
              ),
              
             
            ],
          ),
        ),
      ),
    );
  }



 void _goClientes(Invoice facturaC) {
  //  Navigator.of(context).pop();
     Navigator.push(context,  
       MaterialPageRoute(
         builder: 
         (context) => ClientesNewCredito(index: widget.index,)
       )
     );
  }
  
}