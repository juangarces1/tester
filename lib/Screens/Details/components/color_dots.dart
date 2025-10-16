
import 'package:flutter/material.dart';
import 'package:tester/Components/rounded_icon_btn.dart';
import 'package:tester/Models/FuelRed/product.dart';
import 'package:tester/constans.dart';
import 'package:tester/sizeconfig.dart';


class ColorDots extends StatefulWidget {
  const ColorDots({
    super.key,
    required this.product,
  });

  final Product product;

 
  @override
  State<ColorDots> createState() => _ColorDotsState();
}

class _ColorDotsState extends State<ColorDots> {
   late Product _product;
  
   @override  
  void initState() {
    super.initState();
    _product=widget.product;    
  }

  @override
  Widget build(BuildContext context) {  
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
      child: Row(
        children: [
         Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color:kSecondaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    "Cant:${_product.cantidad.toInt().toString()}",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: kTextColorBlack
                    ),
                  ),
                  const SizedBox(width: 20),                 
                   Text(
                    "Stock:${_product.inventario.toString()}",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: kTextColorBlack
                    ),
                  ),
                  const SizedBox(width: 5),  
                ],
              ),
            ),
          
          const Spacer(),
          RoundedIconBtn(
            icon: Icons.remove, 
            press: _removeProduct,
            showShadow: true,
            color: kPrimaryColor,
          ),
          SizedBox(width: getProportionateScreenWidth(15)),
          RoundedIconBtn(
            icon: Icons.add,
            showShadow: true,
            press: _addProduct,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  void _removeProduct() {
    if (widget.product.cantidad > 0)    {
        widget.product.cantidad= widget.product.cantidad -1;
        widget.product.inventario = widget.product.inventario +1; 
          
        // _product.cantidad= _product.cantidad -1;
        setState(() {
          _product;
        });
    }
  }

  void _addProduct() {
    if (widget.product.inventario > 0){
        widget.product.cantidad=widget.product.cantidad + 1;
        widget.product.inventario=widget.product.inventario - 1;
        
      // _product.cantidad=_product.cantidad+1 ;
        setState(() {
              _product;
        });
    }
   
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    this.isSelected = false,
  });

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: EdgeInsets.all(getProportionateScreenWidth(8)),
      height: getProportionateScreenWidth(40),
      width: getProportionateScreenWidth(40),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border:
            Border.all(color: isSelected ? kPrimaryColor : Colors.transparent),
        shape: BoxShape.circle,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}