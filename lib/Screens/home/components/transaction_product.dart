
import 'package:flutter/material.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';

import '../../../sizeconfig.dart';
import 'section_title.dart';

class TransactioProducts extends StatefulWidget {
 // ignore: use_key_in_widget_constructors
 const TransactioProducts({   
    required this.factura,  
  });
  final Invoice factura;
  @override
  State<TransactioProducts> createState() => _TransactioProductsState();
}

class _TransactioProductsState extends State<TransactioProducts> {
  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: SectionTitle(title: "Combustible", press: () {}),
        ),
        SizedBox(height: getProportionateScreenWidth(10)),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // child: Row(
          //   children: 
          //   [
          //     ...List.generate(
          //       widget.factura.detail!.length,
          //       (index)() {                 
          //           // return TransactionCard(
          //           //   product: widget.factura.detail![index],
          //           //   factura: widget.factura,
          //           // );                 
          //       },
          //     ),
          //     SizedBox(width: getProportionateScreenWidth(20)),
          //   ],
          // ),
        )
      ],
    );
  }
}
