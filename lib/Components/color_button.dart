

import 'package:flutter/material.dart';
import '../sizeconfig.dart';

class ColorButton extends StatelessWidget {
  const ColorButton({
    super.key,
    this.text,
    this.press,
   required this.color,
   required this.ancho,

  });
  final String? text;
  final Function? press;
  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:getProportionateScreenWidth(ancho),
      height: getProportionateScreenHeight(50),
      child: TextButton(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         
          backgroundColor: color,
           elevation: 6,
        ),
        onPressed: press as void Function()?,
        child: Text(
          text!,
          style: TextStyle(
            fontSize: getProportionateScreenWidth(16),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}