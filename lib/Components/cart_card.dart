import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/constans.dart';
import '../../../sizeconfig.dart';

class CartCard extends StatefulWidget {
  const CartCard({
    super.key,
    required this.product,   
  });
  final Product product;  
  @override
  State<CartCard> createState() => _CartCardState();
}

class _CartCardState extends State<CartCard> {
 
  
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
         Row(
        children: [
          SizedBox(
            width: 100,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 106, 106, 107),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: widget.product.unidad == "Unid" ? CachedNetworkImage(
                         imageUrl:'${Constans.getImagenesUrl()}/${widget.product.imageUrl}',
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          fit: BoxFit.cover,
                          height: 80,
                          width: 80,
                          placeholder: (context, url) => const Image(
                            image: AssetImage('assets/Logo.png'),
                            fit: BoxFit.cover,
                            height: 80,
                            width: 80,
                          ),                         
                        ) : Image(
                            image: widget.product.detalle =='Super' ?  const AssetImage('assets/super.png') : 
                                  widget.product.detalle=='Regular' ? const AssetImage('assets/regular.png') : 
                                  widget.product.detalle=='Exonerado' ? const AssetImage('assets/exonerado.png') :
                                  const AssetImage('assets/diesel.png'),
                        ),
              ),
            ),
          ),       
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.detalle,
                  style: const TextStyle(color: kContrateFondoOscuro, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
               
                Text.rich(
                  TextSpan(
                    text: "¢${NumberFormat("###,000", "en_US").format(widget.product.subtotal + widget.product.impMonto)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: kContrateFondoOscuro),
                    children: [
                      TextSpan(
                          text: " - Cant ${widget.product.cantidad}",
                          style: const TextStyle(
                           fontWeight: FontWeight.w600, color: kContrateFondoOscuro)),
                    ],
                  ),
                ),
              
              
              ],
            ),
          )
        ],
      ),
      const Divider(
            height: 2,
            thickness: 2,
            color: kTextColor,
      ),
      ]
    );
  }
}
