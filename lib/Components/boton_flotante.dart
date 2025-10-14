
import 'package:flutter/material.dart';
import 'package:tester/Components/show_cart.dart';
import 'package:tester/constans.dart';


class FloatingButtonWithModal extends StatelessWidget {
  final int index;

  const FloatingButtonWithModal({super.key, required this.index});

  
  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: false,
      child: FloatingActionButton(
          heroTag: null,   
            onPressed: () => showModalBottomSheet(
              backgroundColor: kColorFondoOscuro,
              context: context,
              builder: (context) {
                return ShowCart(index: index);
              },
            ),
            backgroundColor: kContrateFondoOscuro,
             elevation: 8,
            child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: kPrimaryColor, // Ajusta el color como necesites
                  borderRadius: BorderRadius.circular(10), // Los bordes redondeados
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Asegura que la imagen también tenga bordes redondeados
                  child: Image.asset(
                    'assets/MyCart.png',
                    fit: BoxFit.cover, // Esto hace que la imagen se ajuste al tamaño del contenedor
                  ),
                ),),
          ),
    );
  }
}