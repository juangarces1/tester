import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tester/Models/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/constans.dart';
import 'package:tester/sizeconfig.dart';

class CardCartItem extends StatelessWidget {
  final Product product;
  final Function(Product) onIncreaseQuantity;
  final Function(Product) onDecreaseQuantity;
  final Function(Product) onDismissed;

  const CardCartItem({
    super.key,
    required this.product,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onDismissed,
  });

 

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Dismissible(
        key: Key('${product.codigoArticulo}${product.transaccion}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(product),
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 227, 225, 225),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Spacer(),
              SvgPicture.asset("assets/Back ICon.svg"),
            ],
          ),
        ),
        child: Column(
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
                child: product.transaccion == 0 ? CachedNetworkImage(
                    imageUrl:'${Constans.getImagenesUrl()}/${product.imageUrl}',
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
                        image: product.detalle =='Super' ?  const AssetImage('assets/super.png') : 
                              product.detalle=='Regular' ? const AssetImage('assets/regular.png') : 
                              product.detalle=='Exonerado' ? const AssetImage('assets/exonerado.png') :
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
                      product.detalle,
                      style: const TextStyle(color: kContrateFondoOscuro, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                    ),
                  
                    Text.rich(
                      TextSpan(
                        text: "Sub-Total ¢${NumberFormat("###,000", "en_US").format(product.subtotal)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: Colors.white),
                        children: [
                          TextSpan(
                              text: " - Cant ${product.cantidad}",
                              style: const TextStyle(
                              fontWeight: FontWeight.w500, color: kContrateFondoOscuro)),
                        ],
                      ),
                    ),
                  
                    product.transaccion == 0 ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => onIncreaseQuantity(product),
                          icon: const Icon(
                            Icons.add_circle, 
                            color: Colors.green,
                            size: 30,
                            )),
                        IconButton(
                          onPressed: () => onDecreaseQuantity(product),
                        
                          icon: const Icon(
                            Icons.remove_circle,
                             color: kPrimaryText,
                             size: 30,)),
                      ],
                    ) : const SizedBox(height: 0),
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
        ),
      ),
    );
  }


  

}
