

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';




class ButtonCierre extends StatelessWidget {
  const ButtonCierre({
    super.key,
    this.text,
       this.press,
    this.gradient,
    this.color,
  });
  final String? text;
  final  Future Function()? press;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed:  press,
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
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}