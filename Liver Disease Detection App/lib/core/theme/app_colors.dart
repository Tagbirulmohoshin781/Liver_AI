import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgSidebar;
  final Color bgInput;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgSidebar,
    required this.bgInput,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    this.isDark = true,
  });
}

class AppColors {
  // Brand Base Colors
  static const Color primaryTeal = Color(0xFF10A37F);
  static const Color primaryTealHover = Color(0xFF0D8C6D);
  static const Color primaryTealGlow = Color(0x3310A37F);

  // 9 Website Themes Presets
  static const Map<String, ThemePreset> themePresets = {
    'dark': ThemePreset(
      id: 'dark',
      name: 'Dark Navy (Default)',
      bgPrimary: Color(0xFF07111E),
      bgSecondary: Color(0xFF0F172A),
      bgSidebar: Color(0xFF07111E),
      bgInput: Color(0xFF0F172A),
      border: Color(0xFF1E293B),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
      isDark: true,
    ),
    'oled': ThemePreset(
      id: 'oled',
      name: 'OLED Black',
      bgPrimary: Color(0xFF000000),
      bgSecondary: Color(0xFF0F0F0F),
      bgSidebar: Color(0xFF050505),
      bgInput: Color(0xFF141414),
      border: Color(0xFF262626),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFA0A0A0),
      textMuted: Color(0xFF666666),
      isDark: true,
    ),
    'midnight': ThemePreset(
      id: 'midnight',
      name: 'Midnight Glass (Web UI)',
      bgPrimary: Color(0xFF07111E),
      bgSecondary: Color(0xFF0F172A),
      bgSidebar: Color(0xFF07111E),
      bgInput: Color(0xFF0F172A),
      border: Color(0xFF1E293B),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF64748B),
      isDark: true,
    ),
    'nordic': ThemePreset(
      id: 'nordic',
      name: 'Nordic Slate',
      bgPrimary: Color(0xFF1E2430),
      bgSecondary: Color(0xFF283040),
      bgSidebar: Color(0xFF161B24),
      bgInput: Color(0xFF2B3446),
      border: Color(0xFF3B465C),
      textPrimary: Color(0xFFE5E9F0),
      textSecondary: Color(0xFFD8DEE9),
      textMuted: Color(0xFF8892B0),
      isDark: true,
    ),
    'cyberpunk': ThemePreset(
      id: 'cyberpunk',
      name: 'Cyberpunk Neon',
      bgPrimary: Color(0xFF120924),
      bgSecondary: Color(0xFF1C0D38),
      bgSidebar: Color(0xFF0A0418),
      bgInput: Color(0xFF241246),
      border: Color(0xFF42207A),
      textPrimary: Color(0xFFF3E8FF),
      textSecondary: Color(0xFFC084FC),
      textMuted: Color(0xFF8B5CF6),
      isDark: true,
    ),
    'emerald': ThemePreset(
      id: 'emerald',
      name: 'Emerald Forest',
      bgPrimary: Color(0xFF071813),
      bgSecondary: Color(0xFF0D2820),
      bgSidebar: Color(0xFF05110D),
      bgInput: Color(0xFF103329),
      border: Color(0xFF1B5042),
      textPrimary: Color(0xFFE6F7F2),
      textSecondary: Color(0xFF86D3BD),
      textMuted: Color(0xFF4E9983),
      isDark: true,
    ),
    'rose': ThemePreset(
      id: 'rose',
      name: 'Rose Pine',
      bgPrimary: Color(0xFF1A0F18),
      bgSecondary: Color(0xFF271725),
      bgSidebar: Color(0xFF130B12),
      bgInput: Color(0xFF341F31),
      border: Color(0xFF4C2647),
      textPrimary: Color(0xFFFAE8F5),
      textSecondary: Color(0xFFF0ABFC),
      textMuted: Color(0xFFA855F7),
      isDark: true,
    ),
    'sepia': ThemePreset(
      id: 'sepia',
      name: 'Warm Sepia',
      bgPrimary: Color(0xFFFBF0D9),
      bgSecondary: Color(0xFFF4E4C1),
      bgSidebar: Color(0xFFEDE0C4),
      bgInput: Color(0xFFEDE0C4),
      border: Color(0xFFD8C49D),
      textPrimary: Color(0xFF433422),
      textSecondary: Color(0xFF685338),
      textMuted: Color(0xFF8B7355),
      isDark: false,
    ),
    'light': ThemePreset(
      id: 'light',
      name: 'Light Clean',
      bgPrimary: Color(0xFFFFFFFF),
      bgSecondary: Color(0xFFF8FAFC),
      bgSidebar: Color(0xFFFFFFFF),
      bgInput: Color(0xFFF1F5F9),
      border: Color(0xFFCBD5E1),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF475569),
      textMuted: Color(0xFF64748B),
      isDark: false,
    ),
  };

  // Accent Color Palettes (Matching Website Swatches)
  static const List<AccentTheme> accentThemes = [
    AccentTheme(
      id: 'teal',
      name: 'Teal Emerald',
      color: Color(0xFF10A37F),
      glowColor: Color(0x4010A37F),
      gradient: [Color(0xFF10A37F), Color(0xFF059669)],
    ),
    AccentTheme(
      id: 'cyan',
      name: 'Electric Cyan',
      color: Color(0xFF06B6D4),
      glowColor: Color(0x4006B6D4),
      gradient: [Color(0xFF06B6D4), Color(0xFF0284C7)],
    ),
    AccentTheme(
      id: 'indigo',
      name: 'Deep Indigo',
      color: Color(0xFF6366F1),
      glowColor: Color(0x406366F1),
      gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    ),
    AccentTheme(
      id: 'violet',
      name: 'Royal Purple',
      color: Color(0xFF8B5CF6),
      glowColor: Color(0x408B5CF6),
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    AccentTheme(
      id: 'pink',
      name: 'Rose Pink',
      color: Color(0xFFEC4899),
      glowColor: Color(0x40EC4899),
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
    ),
    AccentTheme(
      id: 'amber',
      name: 'Amber Gold',
      color: Color(0xFFF59E0B),
      glowColor: Color(0x40F59E0B),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    AccentTheme(
      id: 'blue',
      name: 'Bright Blue',
      color: Color(0xFF2563EB),
      glowColor: Color(0x402563EB),
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    AccentTheme(
      id: 'emerald',
      name: 'Mint Emerald',
      color: Color(0xFF34D399),
      glowColor: Color(0x4034D399),
      gradient: [Color(0xFF34D399), Color(0xFF10B981)],
    ),
  ];

  // Severity Colors
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color success = Color(0xFF34D399);
  static const Color info = Color(0xFF38BDF8);

  // Fallbacks
  static const Color darkBg = Color(0xFF0B1329);
  static const Color darkBgSecondary = Color(0xFF111C38);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightBgSecondary = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
}

class AccentTheme {
  final String id;
  final String name;
  final Color color;
  final Color glowColor;
  final List<Color> gradient;

  const AccentTheme({
    required this.id,
    required this.name,
    required this.color,
    required this.glowColor,
    required this.gradient,
  });
}
