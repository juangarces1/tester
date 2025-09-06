import 'package:flutter/material.dart';

class Bubble {
  final Widget child; // La página que se abrirá
  final Offset position; // La posición de la burbuja

  Bubble({required this.child, required this.position});
}
