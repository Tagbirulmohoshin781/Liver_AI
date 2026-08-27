import 'package:flutter/material.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final Color? color;
  final List<Color>? gradient;
  final bool isPrimary;
  final bool isFullWidth;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.color,
    this.gradient,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.color ?? theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final baseGradient = widget.gradient ??
        [
          accent,
          accent.withValues(alpha: 0.8),
        ];

    Widget buttonContent;
    if (widget.isLoading) {
      buttonContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (widget.child != null) {
      buttonContent = widget.child!;
    } else {
      buttonContent = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 18,
              color: widget.isPrimary ? Colors.white : accent,
            ),
            const SizedBox(width: 8),
          ],
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                letterSpacing: 0.2,
              ),
            ),
        ],
      );
    }

    final decoration = widget.isPrimary
        ? BoxDecoration(
            gradient: LinearGradient(colors: baseGradient),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: _isHovered || _isPressed ? 0.45 : 0.25),
                blurRadius: _isHovered ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.06)
                : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.2,
            ),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: widget.height,
            width: widget.isFullWidth ? double.infinity : null,
            padding: widget.padding,
            decoration: decoration,
            alignment: Alignment.center,
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
