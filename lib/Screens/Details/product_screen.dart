
import 'package:flutter/material.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/Screens/Details/components/body.dart';
import 'package:tester/Screens/Details/components/custum_appbar.dart';
import 'package:tester/constans.dart';

class ProductScreen extends StatelessWidget { 
  final Product product;
  final int index;
  
  // ignore: use_key_in_widget_constructors
  const ProductScreen({   
    required this.index,   
    required this.product,    
  });
 
  @override
  Widget build(BuildContext context) {   
    return SafeArea(
     
      child: Scaffold(
        backgroundColor: kColorFondoOscuro,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child:  CustomAppBar(
           
            index: index,),
        ),
        body: Body(
          product: product,
          index: index,
        ),      
      ),
    );
  }
}

class ProductDetailsArguments {
  final Product product;

  ProductDetailsArguments({required this.product});
}



