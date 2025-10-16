

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tester/Components/default_button.dart';
import 'package:tester/Models/Facturaccion/factura_service.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Providers/facturas_provider.dart';
import 'package:tester/Screens/Details/components/product_description.dart';
import 'package:tester/Screens/Details/components/product_images.dart';
import 'package:tester/Screens/Details/components/top_rounded_container.dart';
import 'package:tester/constans.dart';
import 'package:provider/provider.dart';

import '../../../sizeconfig.dart';
import 'color_dots.dart';

class Body extends StatefulWidget {
  final int index;
  final Product product;
  

  const Body({super.key,
   required this.product,
    required this.index,
   
   });

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
      Invoice factura = Provider.of<FacturasProvider>(context).getInvoiceByIndex(widget.index);

    return ListView(
      children: [
        const SizedBox(height: 10,),
        ProductImages(product: widget.product),
        TopRoundedContainer(
          color: kTextColor,
          child: Column(
            children: [
              ProductDescription(
                product: widget.product,
                pressOnSeeMore: () {},
              ),
              TopRoundedContainer(
                color: kSecondaryColor,
                child: Column(
                  children: [
                    ColorDots(product: widget.product),
                    TopRoundedContainer(
                      color: kColorFondoOscuro,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: SizeConfig.screenWidth * 0.20,
                          right: SizeConfig.screenWidth * 0.20,
                          bottom: getProportionateScreenWidth(1),
                          top: getProportionateScreenWidth(1),
                        ),
                        child: DefaultButton(
                          text: "Agregar",
                          press: () {
                              if(widget.product.cantidad > 0){
                                bool exists =false;                             
                                for (var element in factura.detail!) {
                                  if(element.codigoArticulo == widget.product.codigoArticulo){                                   
                                      exists=true;
                                  }
                                }
                                if (!exists)                            
                                {
                                  factura.detail!.add(widget.product);                                  
                                }   
                              setState(() {
                               FacturaService.updateFactura(context, factura);
                              });                         
                                Navigator.pop(context);
                              }
                              else{
                                Fluttertoast.showToast(
                                  msg: "Por favor seleccione una cantidad",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0
                                );                              
                              }                               
                          },
                          color: kPrimaryColor,
                          gradient: kPrimaryGradientColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  } 
}

