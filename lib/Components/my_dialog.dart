import 'package:flutter/material.dart';
import 'package:tester/constans.dart';


class MyDialog {
  static Future<void> showAlert(
    BuildContext context,
    String msg,
    String title
   
      ) async {
    return  showDialog(
    context: context,
    builder: (context) {
        return AlertDialog(
          title:  Center(child: Text(
            title,
            style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                      color: kPrimaryText,
                  ),
            )),
          content:  Center(child: Text(msg)),
          actions: <Widget>[
           
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Salir')
            ),
          ],

        );
    } 
  );
  }
  
}
