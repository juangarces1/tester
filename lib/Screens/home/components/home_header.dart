

import 'package:flutter/material.dart';
import 'package:tester/Models/Facturaccion/invoice.dart';
import 'package:tester/Screens/home/components/search_field.dart';

import '../../../sizeconfig.dart';
import 'icon_btn_with_counter.dart';


class HomeHeader extends StatelessWidget {  
  final Invoice factura;  
  const HomeHeader({
    super.key,   
    required this.factura 
  });

  @override
  Widget build(BuildContext context) {
    
   
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SearchField(),
          IconBtnWithCounter(
            svgSrc: "assets/Cart Icon.svg",  
            numOfitem: factura.detail!.length,          
            press: () {},
          ),         
        ],
      ),
    );
  }
}
