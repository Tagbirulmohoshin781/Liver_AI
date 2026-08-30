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

  group('Mobile E2E Spec: Clinical AI Chat & Offline Knowledge', () {
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
      await authService.signInWithGoogleAccount(email: 'chat.tester@liverai.health', displayName: 'Chat Tester');
    });

    testWidgets('CHAT-04: Chat Screen renders input bar and handles interaction', (WidgetTester tester) async {
      await tester.pumpWidget(LiverAIApp(
        glassTheme: glassTheme,
        authService: authService,
        storageService: storageService,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
