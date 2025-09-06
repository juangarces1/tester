import 'package:flutter/material.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/NewHome/Components/item_cart.dart';
import 'package:tester/constans.dart';
import 'package:provider/provider.dart';


class ShowCart extends StatefulWidget {
  final int index;
  const ShowCart({super.key, required this.index});

  @override
  State<ShowCart> createState() => _ShowCartState();
}

class _ShowCartState extends State<ShowCart> {
  

  @override
Widget build(BuildContext context) {
  Invoice factura = Provider.of<FacturasProvider>(context, listen: true).getInvoiceByIndex(widget.index);
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 136, 133, 133),
          width: 2.0,
          style: BorderStyle.solid
        ),
        borderRadius: BorderRadius.circular(20),
        color: kColorFondoOscuro
      ),
      padding: const EdgeInsets.all(10),
      child:  ListView.builder(
              itemCount: factura.detail!.length,
              itemBuilder: (context, index) {
                final product = factura.detail![index];
                return CardCartItem(
                  product: product,
                  onIncreaseQuantity: (product) {
                    setState(() {
                        if (product.inventario > 0){
                          product.cantidad=product.cantidad + 1;
                          product.inventario=product.inventario - 1;                             
                         
                          FacturaService.updateFactura(context, factura);
                        
                        }
                    });
                  },
                  onDecreaseQuantity: (product) {
                    setState(() {
                        if (product.cantidad > 1)    {
                            product.cantidad= product.cantidad -1;
                            product.inventario = product.inventario +1;                               
                           
                           FacturaService.updateFactura(context, factura);
                        }
                    });
                  },
                  onDismissed: (product) {
                   setState(() {               
                    
                     factura.detail!.removeAt(index);
                       FacturaService.updateFactura(context, factura);
                   });             
                  },
                );
              },
            ),
    ),
  );
}

}