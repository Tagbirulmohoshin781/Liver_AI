import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final int maxLines;
  final double borderRadius;

  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GlassContainer(
          borderRadius: borderRadius,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? 12 : 2,
          ),
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
              prefixIcon: prefixIcon,
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              suffixIcon: suffixIcon ??
                  (suffixText != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, right: 6),
                          child: Text(
                            suffixText!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : null),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ],
    );
  }
}
