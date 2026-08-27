import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlassRiskGauge extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final String label;
  final String riskLevel;
  final double size;

  const GlassRiskGauge({
    super.key,
    required this.score,
    required this.label,
    required this.riskLevel,
    this.size = 180,
  });

  @override
  State<GlassRiskGauge> createState() => _GlassRiskGaugeState();
}

class _GlassRiskGaugeState extends State<GlassRiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant GlassRiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRiskColor(double val) {
    if (val >= 0.70) return const Color(0xFFF87171);
    if (val >= 0.40) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentVal = _animation.value;
        final riskColor = _getRiskColor(currentVal);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  value: currentVal,
                  activeColor: riskColor,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(currentVal * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: riskColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final bool isDark;

  _GaugePainter({
    required this.value,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active progress arc with gradient
    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          const Color(0xFF34D399),
          const Color(0xFFFBBF24),
          const Color(0xFFF87171),
        ],
        transform: GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark;
  }
}

class GlassLinearProgressBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value; // 0 to 100
  final bool isPositive;
  final Color? activeColor;

  const GlassLinearProgressBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isPositive,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? (isPositive ? const Color(0xFFF87171) : const Color(0xFF34D399));
    final statusText = isPositive ? 'DETECTED' : 'NOT DETECTED';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.error_outline : Icons.check_circle_outline,
                        size: 13,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Probability: ${value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
