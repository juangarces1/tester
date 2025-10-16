import 'package:flutter/material.dart';
import 'package:tester/constans.dart';


class LoaderComponent extends StatelessWidget {
  final String gifPath;
  final double width;
  final double height;
  final Color backgroundColor;
  final String? loadingText;
  final Color borderColor;
  final double borderWidth;

  const LoaderComponent({super.key, 
    this.gifPath = 'assets/FrGif.gif',
    this.width = 70.0,
    this.height = 70.0,
    this.backgroundColor = kNewsurface,
    this.loadingText = '',
    this.borderColor = kNewsurface,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
  return Center(
    child: Container(
      width: 150, // Ancho fijo
      height: 150, // Alto fijo
      decoration: BoxDecoration(
        color: Colors.transparent, // Fondo sólido
        border: Border.all(
          color: Colors.transparent,
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
                gifPath,
                // Elimina el width y height para permitir que la imagen se escale dentro de los límites del contenedor
              ),
            ),
          ),
          Text(
            loadingText ?? '',
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
