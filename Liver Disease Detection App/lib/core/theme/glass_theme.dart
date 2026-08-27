import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class GlassTheme extends ChangeNotifier {
  String _themePresetId = 'midnight';
  String _accentId = 'blue';
  Color? _customAccentColor;
  double _fontScale = 1.0;
  double _blurSigma = 16.0;

  String get themePresetId => _themePresetId;
  String get accentId => _accentId;
  double get fontScale => _fontScale;
  double get blurSigma => _blurSigma;

  ThemePreset get currentPreset =>
      AppColors.themePresets[_themePresetId] ?? AppColors.themePresets['midnight']!;

  bool get isDarkMode => currentPreset.isDark;

  AccentTheme get currentAccent {
    if (_customAccentColor != null) {
      return AccentTheme(
        id: 'custom',
        name: 'Custom',
        color: _customAccentColor!,
        glowColor: _customAccentColor!.withValues(alpha: 0.25),
        gradient: [_customAccentColor!, _customAccentColor!.withValues(alpha: 0.8)],
      );
    }
    return AppColors.accentThemes.firstWhere(
      (a) => a.id == _accentId,
      orElse: () => AppColors.accentThemes[0],
    );
  }

  Color get accentColor => currentAccent.color;
  Color get glowColor => currentAccent.glowColor;
  List<Color> get accentGradient => currentAccent.gradient;

  Color get backgroundColor => currentPreset.bgPrimary;
  Color get surfaceColor => currentPreset.bgSecondary;
  Color get sidebarColor => currentPreset.bgSidebar;
  Color get inputColor => currentPreset.bgInput;
  Color get borderColor => currentPreset.border;

  Color get textPrimary => currentPreset.textPrimary;
  Color get textSecondary => currentPreset.textSecondary;
  Color get textMuted => currentPreset.textMuted;

  Color get glassFillColor => isDarkMode
      ? currentPreset.bgSecondary.withValues(alpha: 0.68)
      : Colors.white.withValues(alpha: 0.85);

  Color get glassBorderColor => isDarkMode
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.08);

  LinearGradient get glassBorderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
            ? [
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.05),
                accentColor.withValues(alpha: 0.25),
                accentColor.withValues(alpha: 0.10),
              ]
            : [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.04),
                accentColor.withValues(alpha: 0.20),
              ],
      );

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themePresetId = prefs.getString('liver_theme_mode') ?? 'midnight';
      _accentId = prefs.getString('liver_accent_id') ?? 'blue';
      _fontScale = (prefs.getDouble('liver_font_scale') ?? 1.0).clamp(0.85, 1.25);
      _blurSigma = (prefs.getDouble('liver_blur_sigma') ?? 16.0).clamp(0.0, 30.0);
      final customHex = prefs.getInt('liver_custom_accent');
      if (customHex != null) {
        _customAccentColor = Color(customHex);
      }
      notifyListeners();
    } catch (_) {}
  }

  void setThemePreset(String presetId) async {
    if (AppColors.themePresets.containsKey(presetId)) {
      _themePresetId = presetId;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('liver_theme_mode', presetId);
      } catch (_) {}
    }
  }

  void toggleTheme(bool isDark) {
    setThemePreset(isDark ? 'midnight' : 'light');
  }

  void setAccent(String id) async {
    _accentId = id;
    _customAccentColor = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('liver_accent_id', id);
      await prefs.remove('liver_custom_accent');
    } catch (_) {}
  }

  void setCustomAccent(Color color) async {
    _customAccentColor = color;
    _accentId = 'custom';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('liver_custom_accent', color.toARGB32());
    } catch (_) {}
  }

  void setFontScale(double scale) async {
    _fontScale = scale.clamp(0.85, 1.25);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('liver_font_scale', _fontScale);
    } catch (_) {}
  }

  void setBlurSigma(double sigma) async {
    _blurSigma = sigma.clamp(0.0, 30.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('liver_blur_sigma', _blurSigma);
    } catch (_) {}
  }

  ThemeData get themeData {
    final baseTextTheme = isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final fontTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: accentColor,
        surface: surfaceColor,
      ),
      textTheme: fontTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
