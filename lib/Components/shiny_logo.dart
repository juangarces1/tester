import 'package:flutter/material.dart';

class ShinyLogo extends StatefulWidget {
  const ShinyLogo({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShinyLogoState createState() => _ShinyLogoState();
}

class _ShinyLogoState extends State<ShinyLogo> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..repeat();
    animation = Tween<double>(begin: -1.0, end: 2.0).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('assets/SanGerardo.png', width: 130), // Tu logo
       
      ],
    );
  }
}
