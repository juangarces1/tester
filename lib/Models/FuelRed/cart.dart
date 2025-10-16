

import 'package:tester/Models/FuelRed/product.dart';

class Cart {
   List<Product> products=[];
   int numOfItem= 0;
   double total =0;
  Cart({required this.products, required this.numOfItem});

  void cargaritems(){
      numOfItem=products.length.toInt();
  }

  void setTotal(){
    total=0;
    for (var element in products) {
      if(element.transaccion==0)
        { total+=element.totalProducto;}
     else{
          total+=element.total;
     }
    }}
    
}