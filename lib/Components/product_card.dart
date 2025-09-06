import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/Screens/Details/product_screen.dart';
import 'package:tester/helpers/constans.dart';
import 'package:tester/helpers/varios_helpers.dart';

import '../constans.dart';
import '../sizeconfig.dart';



class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    this.width = 80,
    this.aspectRetio = 1.05,
    required this.product,
    required this.index, 
   
  });

  final double width, aspectRetio;
  final Product product;
  final int index;

 
    
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: getProportionateScreenWidth(10)),
      child: Container(
       
         padding: EdgeInsets.all(getProportionateScreenWidth(10)),
         decoration: BoxDecoration(
          color: VariosHelpers.getShadedColor(product.detalle.toString(), kColorFondoOscuro),
          borderRadius: BorderRadius.circular(15),
        ),
       
        child: GestureDetector(          
           onTap: () => Navigator.push(
            context,
             MaterialPageRoute(
               builder: (context) => ProductScreen(
                 index: index,
                 product: product,               
               )
             )
           ),       
         
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: aspectRetio,
                child: Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                  decoration: BoxDecoration(
                   
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Hero(
                    tag: product.codigoArticulo.toString(),
                    child: CachedNetworkImage(
                        imageUrl:'${Constans.getImagenesUrl()}/${product.imageUrl}',
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        fit: BoxFit.cover,
                        height: 70,
                        width: 70,
                        placeholder: (context, url) => const Image(
                          image: AssetImage('assets/Logo.png'),
                          fit: BoxFit.cover,
                          height: 70,
                          width: 70,
                        ),                         
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.detalle,
                style: const TextStyle(color: kContrateFondoOscuro, fontSize: 13),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                     "¢${NumberFormat("###,000", "en_US").format(product.total.toInt())}",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(18),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),                  
                ],
              )
            ],
          ),
        ),
      ),
    );
  }  
}
