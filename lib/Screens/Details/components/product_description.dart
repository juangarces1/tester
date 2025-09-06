
import 'package:flutter/material.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';



class ProductDescription extends StatelessWidget {
  const ProductDescription({
    super.key,
    required this.product,
    this.pressOnSeeMore,
  });

  final Product product;
  final GestureTapCallback? pressOnSeeMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: Center(
            child: Text(
              
              product.detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kContrateFondoOscuro, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        
      ],
    );
  }
}