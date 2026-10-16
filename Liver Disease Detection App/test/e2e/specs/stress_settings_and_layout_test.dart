import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liver_disease_detection_app/core/theme/glass_theme.dart';
import 'package:liver_disease_detection_app/screens/settings_screen.dart';
import 'package:liver_disease_detection_app/core/widgets/glass_button.dart';
import 'package:liver_disease_detection_app/core/widgets/glass_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Phase 2 & 3: Settings Screen Overflow & A11y Font Scaling Tests', () {
    late GlassTheme glassTheme;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      glassTheme = GlassTheme();
      await glassTheme.initialize();
    });

    testWidgets('ACTION-01: GlassButton wraps long labels without horizontal RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: glassTheme.themeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: GlassButton(
                onPressed: () {},
                label: 'Clear Local Cache & Chat Logs',
                icon: Icons.delete_forever_outlined,
                isFullWidth: true,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clear Local Cache & Chat Logs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    final fontScales = [1.0, 1.25, 1.5, 1.75, 2.0];
    for (final scale in fontScales) {
      testWidgets('A11Y-SCALE-${(scale * 100).toInt()}%: Settings Screen adapts fluidly at ${(scale * 100).toInt()}% font scale', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        glassTheme.setFontScale(scale);

        await tester.pumpWidget(MaterialApp(
          theme: glassTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SettingsScreen(
              glassTheme: glassTheme,
              onClearAllData: () {},
              onLogout: () {},
            ),
          ),
        ));
        await tester.pumpAndSettle();

        // Verify key widgets are rendered and no layout exception occurred
        expect(find.textContaining('Engine, Themes & AI Studio'), findsOneWidget);
        expect(find.textContaining('Save & Apply All Settings'), findsOneWidget);
        expect(find.textContaining('Clear Local Cache & Chat Logs'), findsOneWidget);
        expect(find.textContaining('Sign Out Account'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Verify vertical scrollability works without bottom boundary traps
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Phase 4: Glass Blur Intensity Stress Testing (0 - 200px)', () {
    late GlassTheme glassTheme;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      glassTheme = GlassTheme();
      await glassTheme.initialize();
    });

    final blurValues = [0.0, 25.0, 50.0, 75.0, 100.0, 125.0, 150.0, 175.0, 200.0];
    for (final blur in blurValues) {
      testWidgets('BLUR-STRESS-${blur.toInt()}PX: GlassContainer renders safely at $blur px blur', (WidgetTester tester) async {
        glassTheme.setBlurSigma(blur);

        await tester.pumpWidget(MaterialApp(
          theme: glassTheme.themeData,
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                blurSigma: blur,
                padding: const EdgeInsets.all(20),
                child: Text('Blur Intensity: ${blur.toInt()}px'),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Blur Intensity: ${blur.toInt()}px'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Phase 5: Combined Stress Matrix Permutations', () {
    late GlassTheme glassTheme;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      glassTheme = GlassTheme();
      await glassTheme.initialize();
    });

    testWidgets('MATRIX-01 Normal: 100% font, 50 blur, Mobile (375x667)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      glassTheme.setFontScale(1.0);
      glassTheme.setBlurSigma(50.0);

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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MATRIX-02 High Blur: 100% font, 200 blur, Mobile (390x844)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      glassTheme.setFontScale(1.0);
      glassTheme.setBlurSigma(200.0);

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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MATRIX-03 High A11y: 200% font, 100 blur, Mobile (360x800)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      glassTheme.setFontScale(2.0);
      glassTheme.setBlurSigma(100.0);

      await tester.pumpWidget(MaterialApp(
        theme: glassTheme.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SettingsScreen(
            glassTheme: glassTheme,
            onClearAllData: () {},
            onLogout: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MATRIX-04 Extreme Stress: 200% font, 200 blur, Mobile & Desktop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      glassTheme.setFontScale(2.0);
      glassTheme.setBlurSigma(200.0);

      await tester.pumpWidget(MaterialApp(
        theme: glassTheme.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SettingsScreen(
            glassTheme: glassTheme,
            onClearAllData: () {},
            onLogout: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MATRIX-05 Orientation: 150% font, 150 blur, Tablet Landscape (1024x768)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      glassTheme.setFontScale(1.5);
      glassTheme.setBlurSigma(150.0);

      await tester.pumpWidget(MaterialApp(
        theme: glassTheme.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SettingsScreen(
            glassTheme: glassTheme,
            onClearAllData: () {},
            onLogout: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
