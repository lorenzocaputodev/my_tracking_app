import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';

class ActionButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final String actionLabel;
  final VoidCallback? onLongPress;

  const ActionButton({
    super.key,
    required this.size,
    required this.onTap,
    required this.actionLabel,
    this.onLongPress,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _longPressTimer;

  static const _longPressDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  void _onPointerDown() {
    if (widget.onLongPress == null) return;
    _longPressTimer = Timer(_longPressDuration, () {
      widget.onLongPress!();
    });
  }

  void _onPointerUp() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final turquoise = colors.action;
    final isDark = context.isDark;
    final textColor = colors.onAction;
    final labelColor = textColor.withValues(alpha: 0.78);
    final gradientColors = isDark
        ? [turquoise, turquoise.withBlue(150)]
        : [
            Color.lerp(turquoise, Colors.white, 0.06) ?? turquoise,
            turquoise.withBlue(165),
          ];
    final buttonBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.34);
    final buttonShadows = isDark
        ? [
            BoxShadow(
              color: turquoise.withValues(alpha: 0.34),
              blurRadius: 30,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ]
        : [
            BoxShadow(
              color: turquoise.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ];

    return Listener(
      onPointerDown: (_) => _onPointerDown(),
      onPointerUp: (_) => _onPointerUp(),
      onPointerCancel: (_) => _onPointerUp(),
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: gradientColors,
                center: const Alignment(-0.2, -0.2),
                radius: isDark ? 0.98 : 0.92,
              ),
              border: Border.all(color: buttonBorderColor, width: 1.1),
              boxShadow: buttonShadows,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: textColor,
                  size: widget.size * 0.32,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.actionLabel.toUpperCase(),
                  style: TextStyle(fontFamily: AppFonts.display,
                    fontSize: widget.size * 0.09,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
