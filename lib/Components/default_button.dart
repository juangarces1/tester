

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';




class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    this.text,
    this.press,
    this.gradient,
    this.color,
    this.textColor,
  });
  final String? text;
  final Function? press;
  final Gradient? gradient;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed:  press as void Function()?,
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              
            ),
            padding: const EdgeInsets.all(8)
          ),
      
        child: Ink(
          decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(30.0)),
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 150.0, minHeight: 50.0),
            alignment: Alignment.center,
            child:  Text(text??'',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor ?? Colors.white, fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}