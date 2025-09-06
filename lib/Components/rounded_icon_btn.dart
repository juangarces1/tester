

import 'package:flutter/material.dart';
import '../constans.dart';
import '../sizeconfig.dart';


class RoundedIconBtn extends StatelessWidget {
  const RoundedIconBtn({
    super.key,
    required this.icon,
    required this.press,
    required this.color,
    this.showShadow = false,
  });

  final IconData icon;
  final GestureTapCancelCallback press;
  final bool showShadow;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getProportionateScreenWidth(45),
      width: getProportionateScreenWidth(45),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (showShadow)
            BoxShadow(
              offset: const Offset(0, 6),
              blurRadius: 10,
              color: color.withOpacity(0.2)
            ),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
         
          backgroundColor: kColorFondoOscuro,
          shape:
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: press,
        child: Icon(icon, color: color,),
      ),
    );
  }
}