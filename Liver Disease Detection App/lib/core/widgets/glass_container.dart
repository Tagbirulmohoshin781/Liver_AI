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

    // Perceptual Blur Scaling & Safe Physical GPU Clamping:
    // Physical Skia/Impeller blur is safely clamped to 45.0 to avoid GPU memory leaks and dark edge clipping.
    // At higher values (50-200), opacity is dynamically scaled to provide deep, high-contrast frosted glass.
    final double physicalBlur = blurSigma.clamp(0.0, 45.0);
    final double extraOpacity = blurSigma > 45.0
        ? (((blurSigma - 45.0) / 155.0) * 0.22).clamp(0.0, 0.25)
        : 0.0;

    final Color baseFill = fillColor ?? defaultFill;
    final Color effectiveFill = extraOpacity > 0
        ? baseFill.withValues(alpha: (baseFill.a + extraOpacity).clamp(0.0, 0.96))
        : baseFill;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveFill,
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

    final Widget paintedContent = CustomPaint(
      painter: _GlassBorderPainter(
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        gradient: borderGradient ?? defaultBorderGrad,
        solidColor: borderColor,
      ),
      child: content,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: physicalBlur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: physicalBlur, sigmaY: physicalBlur),
                child: paintedContent,
              )
            : paintedContent,
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
