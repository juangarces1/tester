import 'package:flutter/material.dart';
import 'package:tester/constans.dart';


class ShowAlertFactura {
  static Future<String?> show(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    TextEditingController textFieldController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Buscar Factura',
              style: TextStyle(
                color: kBlueColorLogo, // Personaliza según tu tema
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textFieldController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: (value) {
                if (value == null || value.length != 10) {
                  return 'Introduce 10 dígitos';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: "Escribe aquí el número",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Color del texto
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, // Color del texto
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(textFieldController.text);
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
