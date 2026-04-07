import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final String actionLabel;
  final String? productName;
  final VoidCallback? onLongPress;

  const ActionButton({
    super.key,
    required this.size,
    required this.onTap,
    required this.actionLabel,
    this.productName,
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
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.black87 : Colors.white;
    final labelColor = isDark
        ? textColor.withValues(alpha: 0.74)
        : textColor.withValues(alpha: 0.94);
    final sub = widget.productName?.trim();
    final showProduct = sub != null && sub.isNotEmpty;
    final iconFrac = showProduct ? 0.28 : 0.32;
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
                  size: widget.size * iconFrac,
                ),
                SizedBox(height: showProduct ? 2 : 6),
                Text(
                  widget.actionLabel.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: widget.size * (showProduct ? 0.075 : 0.09),
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 1.5,
                  ),
                ),
                if (showProduct) ...[
                  const SizedBox(height: 1),
                  SizedBox(
                    width: widget.size * 0.72,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        sub.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: widget.size * 0.16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
