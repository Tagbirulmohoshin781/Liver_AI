import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isGlow;

  const GlassCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.isGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      margin: margin,
      padding: padding,
      onTap: onTap,
      isGlow: isGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null || trailing != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (iconColor ?? theme.primaryColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor ?? theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
