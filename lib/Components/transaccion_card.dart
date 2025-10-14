
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tester/Models/all_fact.dart';
import 'package:tester/Models/product.dart';
import '../sizeconfig.dart';

class TransactionCard extends StatefulWidget {
  const TransactionCard({
    super.key,
    this.width = 140,
    this.aspectRetio = 1.02,
    required this.product,
    required this.factura,    
    
  });

  final double width, aspectRetio;
  final Product product;
  final AllFact factura;
    

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: getProportionateScreenWidth(10)),
      child: SizedBox(
        width: getProportionateScreenWidth(widget.width),
        child: GestureDetector(          
          onTap: addToCart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.02,
                child: Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 75, 75, 75).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Hero(
                    tag: widget.product.transaccion.toString(),
                    child: Image(
                          image: widget.product.detalle =='Comb Super' ?  const AssetImage('assets/super.png') : 
                                widget.product.detalle=='Comb Regular' ? const AssetImage('assets/regular.png') : 
                                widget.product.detalle=='Comb Exonerado' ? const AssetImage('assets/exonerado.png') :
                                const AssetImage('assets/diesel.png'),
                      )
                  ),
                ),
              ),
              const SizedBox(height: 10),              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,               
                children: [
                  Text(
                    "Numero: ${widget.product.transaccion.toString()}",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),                             
                ],
              ),
              const SizedBox(height: 10),              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,               
                children: [
                  Text(
                    "Cant: ${widget.product.cantidad.toString()}",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),                             
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Text(
                    "\$${NumberFormat("###,000", "en_US").format(widget.product.total.toInt())}",
                    style:  TextStyle(
                      fontSize: getProportionateScreenWidth(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),                                
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void addToCart() {
    widget.factura.cart!.products.add(widget.product);
    widget.factura.transacciones.remove(widget.product);

    setState(() {
      widget.factura.transacciones;
      widget.factura.cart!.products;
    });

    // Navigator.pushReplacement(
    //   context,  
    //   MaterialPageRoute(
    //   builder: (context) => HomeScreen(
    //   factura: widget.factura,
    //   )
    // )
    // );
  }
}
