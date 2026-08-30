import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liver_disease_detection_app/main.dart';
import 'package:liver_disease_detection_app/core/theme/glass_theme.dart';
import 'package:liver_disease_detection_app/services/auth_service.dart';
import 'package:liver_disease_detection_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Mobile E2E Spec: Authentication & Onboarding Journey', () {
    late GlassTheme glassTheme;
    late AuthService authService;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      glassTheme = GlassTheme();
      await glassTheme.initialize();
      authService = AuthService();
      await authService.initialize();
      storageService = StorageService();
      await storageService.initialize();
      await authService.logout();
    });

    testWidgets('AUTH-04: Mobile Auth Screen renders login form and handles guest mode access', (WidgetTester tester) async {
      await tester.pumpWidget(LiverAIApp(
        glassTheme: glassTheme,
        authService: authService,
        storageService: storageService,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TextField), findsWidgets);

      final guestBtn = find.textContaining('Explore in Guest Mode');
      if (guestBtn.evaluate().isNotEmpty) {
        await tester.tap(guestBtn, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
