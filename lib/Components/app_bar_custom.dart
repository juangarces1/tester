import 'package:flutter/material.dart';

class MyCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  final Color? shadowColor;
  final Color? foreColor;
  final PreferredSizeWidget? bottom;

  /// Callback opcional para la acción de volver.
  /// Si no se proporciona, se usará Navigator.maybePop(context).
  final VoidCallback? onBack;

  const MyCustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.shadowColor,
    this.foreColor,
    this.bottom,
    this.onBack, // <- nuevo
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: foreColor, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: actions,
      leading: automaticallyImplyLeading && Navigator.canPop(context)
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _handleBack(context), // <- usa callback si viene
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 24.0),
              ),
            )
          : null,
      backgroundColor: backgroundColor,
      elevation: elevation ?? 4.0,
      shadowColor: shadowColor,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
