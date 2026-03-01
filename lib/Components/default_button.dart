// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,
    this.text,
    this.press,
    this.gradient,
    this.color,
    this.textColor,
  });

  final String? text;
  final Function? press;
  final Gradient? gradient;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed = press as void Function()?;
    final borderRadius = BorderRadius.circular(20);
    final fallbackColor = color ?? Theme.of(context).colorScheme.primary;

    Widget label = Text(
      text ?? '',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
      ),
    );

    // Con gradiente: Material + Ink + InkWell para splash perfecto
    if (gradient != null) {
      return Container(
        height: 50.0,
        margin: const EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: borderRadius,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 150.0,
                    minHeight: 50.0,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: label,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sin gradiente: ElevatedButton con estilo moderno
    return Container(
      height: 50.0,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.disabled)) {
              return fallbackColor.withValues(alpha: 0.6);
            }
            return fallbackColor;
          }),
          foregroundColor: MaterialStateProperty.all(textColor ?? Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
          elevation: MaterialStateProperty.resolveWith<double>((states) {
            if (states.contains(MaterialState.pressed)) return 2;
            return 4;
          }),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 150.0,
            minHeight: 50.0,
          ),
          child: Align(
            alignment: Alignment.center,
            child: label,
          ),
        ),
      ),
    );
  }
}
