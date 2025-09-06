import 'package:flutter/material.dart';
import 'package:tester/constans.dart';


class MyNoContent extends StatelessWidget {
  final String imgPath;
  final double width;
  final double height;
  final Color backgroundColor;
  final String text;
  final Color borderColor;
  final double borderWidth;

  const MyNoContent({super.key, 
    this.imgPath = 'assets/SanGerardo.png',
    this.width = 200.0,
    this.height = 180.0,
    this.backgroundColor = kSecondaryColor,
    this.text = '',
    this.borderColor = kPrimaryColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
  return Center(
    child: Container(
      width: width, // Ancho fijo
      height: height, // Alto fijo
      decoration: BoxDecoration(
        color: backgroundColor, // Fondo sólido
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(12), // Borde redondeado
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 10), // Espaciado dentro del borde
              child: Image.asset(
                imgPath,
                // Elimina el width y height para permitir que la imagen se escale dentro de los límites del contenedor
              ),
            ),
          ),
          const SizedBox(height: 10), // Espacio entre el GIF y el texto
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 10), 
        ],
      ),
    ),
  );
}

}
