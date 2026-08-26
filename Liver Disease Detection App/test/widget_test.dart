import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/main.dart';
import 'package:liver_disease_detection_app/core/theme/glass_theme.dart';
import 'package:liver_disease_detection_app/services/auth_service.dart';
import 'package:liver_disease_detection_app/services/storage_service.dart';

void main() {
  testWidgets('LiverAIApp smoke test', (WidgetTester tester) async {
    final glassTheme = GlassTheme();
    final authService = AuthService();
    final storageService = StorageService();

    await tester.pumpWidget(LiverAIApp(
      glassTheme: glassTheme,
      authService: authService,
      storageService: storageService,
    ));
  });
}
