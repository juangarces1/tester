import 'dart:ui';
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

  const LoaderComponent({
    super.key,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black
                  .withValues(alpha: 0.3), // Fondo semi-transparente
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 10, right: 10, bottom: 10),
                    child: Image.asset(
                      gifPath,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    loadingText ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
