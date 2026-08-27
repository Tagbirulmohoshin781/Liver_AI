import 'package:flutter/material.dart';

class GlassStatusChip extends StatelessWidget {
  final String label;
  final bool isPositive;
  final double? probability;
  final IconData? icon;

  const GlassStatusChip({
    super.key,
    required this.label,
    required this.isPositive,
    this.probability,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPositive ? const Color(0xFFF87171) : const Color(0xFF34D399);
    final statusIcon = icon ?? (isPositive ? Icons.error_outline : Icons.check_circle_outline);
    final statusText = isPositive ? 'DETECTED' : 'NOT DETECTED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
          if (probability != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${probability!.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 10,
                color: statusColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
