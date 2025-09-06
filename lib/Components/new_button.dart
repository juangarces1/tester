

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../constans.dart';


class NewButton extends StatelessWidget {
  const NewButton({
    super.key,
    this.text,
    this.press,
  });
  final String? text;
  final Function? press;

  @override
  Widget build(BuildContext context) {
    return Container(
      
      margin: const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed:  press as void Function()?,
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              
            ),
            padding: const EdgeInsets.all(8),
           
          ),
      
        child: Text(text??'',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 22),
      ),
    ),);
  }
}