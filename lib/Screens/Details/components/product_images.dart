import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/helpers/constans.dart';
import 'package:tester/sizeconfig.dart';




class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  // ignore: library_private_types_in_public_api
  _ProductImagesState createState() => _ProductImagesState();
}



class _ProductImagesState extends State<ProductImages> {

// static String imagenesUrlRemoto = 'http://200.91.130.215:9091/photos'; 
 // static String imagenesUrlLocal = 'http://192.168.1.3:9091/photos';   
  //  static String imagenesUrlLocal = 'http://192.168.1.165:8081/photos'; 

  //   static String  getImagenesUrl () {
      
  //     return imagenesUrlLocal;
     
  //   }

  int selectedImage = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: getProportionateScreenHeight(300),
          child: AspectRatio(
            aspectRatio:0.7,
            child: Container(
               padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
              child: Hero(
                tag: widget.product.codigoArticulo.toString(),
                child: CachedNetworkImage(
                          imageUrl: '${Constans.getImagenesUrl()}/${widget.product.imageUrl}',
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
        ),
        // SizedBox(height: getProportionateScreenWidth(20)),
      //  Row(
      //    mainAxisAlignment: MainAxisAlignment.center,
      //    children: [
      //      ...List.generate(widget.product.images.length,
      //          (index) => buildSmallProductPreview(index)),
      //    ],
      //  )
      ],
    );
  }

  GestureDetector buildSmallProductPreview(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImage = index;
        });
      },
      child: AnimatedContainer(
        duration: defaultDuration,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(8),
        height: getProportionateScreenWidth(48),
        width: getProportionateScreenWidth(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: kPrimaryColor.withValues(alpha: selectedImage == index ? 1 : 0)),
        ),
        child: CachedNetworkImage(
                        imageUrl: widget.product.images[index],
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
                      ),
      ),
    );
  }
}
