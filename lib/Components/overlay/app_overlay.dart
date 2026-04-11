import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tester/constans.dart';

enum _OverlayLevel { success, error, warning, info }

class AppOverlay {
  AppOverlay._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void success(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _OverlayLevel.info);

  static void _show(BuildContext context, String message, _OverlayLevel level) {
    _dismiss();

    final overlay = Overlay.of(context);
    final config = _configFor(level);

    _currentEntry = OverlayEntry(
      builder: (ctx) => _OverlayToast(
        message: message,
        icon: config.icon,
        color: config.color,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_currentEntry!);
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static ({IconData icon, Color color}) _configFor(_OverlayLevel level) {
    return switch (level) {
      _OverlayLevel.success => (
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF00C853),
        ),
      _OverlayLevel.error => (
          icon: Icons.error_rounded,
          color: const Color(0xFFFF1744),
        ),
      _OverlayLevel.warning => (
          icon: Icons.warning_rounded,
          color: const Color(0xFFFF9100),
        ),
      _OverlayLevel.info => (
          icon: Icons.info_rounded,
          color: const Color(0xFF29B6F6),
        ),
    };
  }
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              onVerticalDragEnd: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kNewsurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: kContrateFondoOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: kNewtextSec.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
