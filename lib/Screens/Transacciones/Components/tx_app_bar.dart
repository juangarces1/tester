// lib/Components/console_app_bar.dart
import 'package:flutter/material.dart';

class ConsoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  final Color? shadowColor;
  final Color? foreColor;
  final PreferredSizeWidget? bottom;

  // Opcionales nuevos (no rompen)
  final String? subtitle;                 // línea bajo el título
  final bool centerTitle;                 // centrar título
  final double? toolbarHeight;            // altura
  final bool showBottomDivider;           // línea inferior sutil
  final Color? bottomDividerColor;        // color de la línea
  final bool pillBackButton;              // botón back redondo (pill)
  final Color? leadingBackgroundColor;    // fondo del pill
  final Color? leadingIconColor;          // color ícono back
  final Color? leadingBorderColor;        // borde del pill
  final String? leadingTooltip;           // tooltip del back
  final Widget? leading;                  // override completo del leading
  final double? titleSpacing;             // espaciado del título

  const ConsoleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.shadowColor,
    this.foreColor,
    this.bottom,

    // nuevos
    this.subtitle,
    this.centerTitle = false,
    this.toolbarHeight,
    this.showBottomDivider = false,
    this.bottomDividerColor,
    this.pillBackButton = true,
    this.leadingBackgroundColor,
    this.leadingIconColor,
    this.leadingBorderColor,
    this.leadingTooltip,
    this.leading,
    this.titleSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = (subtitle == null)
        ? Text(title,
            style: TextStyle(
              color: foreColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ))
        : Column(
            crossAxisAlignment:
                centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: TextStyle(
                    color: foreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  color: (foreColor ?? Colors.white).withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    final effectiveLeading = leading ??
        (automaticallyImplyLeading && Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: pillBackButton
                    ? Tooltip(
                        message: leadingTooltip ?? 'Volver',
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60),
                              side: BorderSide(
                                color: leadingBorderColor ?? Colors.transparent,
                              ),
                            ),
                            backgroundColor: leadingBackgroundColor ?? Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back,
                            color: leadingIconColor ?? Colors.black,
                            size: 24,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: leadingTooltip ?? 'Volver',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: foreColor ?? Colors.black),
                      ),
              )
            : null);

    return AppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      actions: actions,
      leading: effectiveLeading,
      backgroundColor: backgroundColor,
      elevation: elevation ?? 4,
      shadowColor: shadowColor,
      bottom: bottom,
      shape: showBottomDivider
          ? Border(
              bottom: BorderSide(
                color: bottomDividerColor ?? Colors.black12,
                width: 1,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight((toolbarHeight ?? kToolbarHeight) + bottomHeight);
  }
}
