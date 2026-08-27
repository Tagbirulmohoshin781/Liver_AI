import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? fillColor;
  final Gradient? borderGradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool isGlow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 16,
    this.fillColor,
    this.borderGradient,
    this.borderColor,
    this.borderWidth = 1.2,
    this.shadows,
    this.onTap,
    this.isGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.primaryColor;

    final defaultFill = isDark
        ? const Color(0xFF131A26).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.75);

    final defaultBorderGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.05),
              accent.withValues(alpha: 0.20),
            ]
          : [
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.03),
              accent.withValues(alpha: 0.15),
            ],
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor ?? defaultFill,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );

    // If onTap is provided, wrap in InkWell
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    final List<BoxShadow> effectiveShadows = shadows ??
        [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (isGlow)
            BoxShadow(
              color: (glowColor ?? accent).withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 24,
              spreadRadius: -2,
            ),
        ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _GlassBorderPainter(
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              gradient: borderGradient ?? defaultBorderGrad,
              solidColor: borderColor,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final Gradient? gradient;
  final Color? solidColor;

  _GlassBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    this.gradient,
    this.solidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (solidColor != null) {
      paint.color = solidColor!;
    } else if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.gradient != gradient ||
        oldDelegate.solidColor != solidColor;
  }
}
