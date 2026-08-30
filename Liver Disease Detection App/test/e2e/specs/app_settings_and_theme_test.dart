import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liver_disease_detection_app/core/theme/glass_theme.dart';
import 'package:liver_disease_detection_app/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Mobile E2E Spec: GlassTheme Presets & Settings Storage', () {
    late GlassTheme glassTheme;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      glassTheme = GlassTheme();
      await glassTheme.initialize();
    });

    testWidgets('SET-03: Settings Screen renders theme selection and controls', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: glassTheme.themeData,
        home: Scaffold(
          body: SettingsScreen(
            glassTheme: glassTheme,
            onClearAllData: () {},
            onLogout: () {},
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Theme'), findsWidgets);
    });
  });
}
