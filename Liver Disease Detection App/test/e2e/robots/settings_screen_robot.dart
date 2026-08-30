import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [SettingsScreen].
class SettingsScreenRobot {
  final WidgetTester tester;

  SettingsScreenRobot(this.tester);

  Finder get themePresets => find.textContaining('Theme Presets');
  Finder get clearDataButton => find.textContaining('Clear All Local Data');
  Finder get logoutButton => find.textContaining('Sign Out');

  Future<void> tapTheme(String themeName) async {
    final theme = find.textContaining(themeName);
    if (theme.evaluate().isNotEmpty) {
      await tester.tap(theme.first);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapClearData() async {
    if (clearDataButton.evaluate().isNotEmpty) {
      await tester.tap(clearDataButton);
      await tester.pumpAndSettle();
    }
  }
}
