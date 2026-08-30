import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liver_disease_detection_app/screens/biopsy_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Mobile E2E Spec: Biopsy Scanner Screen & Stage Metrics', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('BIO-02: Biopsy Scanner UI renders camera/gallery selection triggers', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BiopsyScannerScreen(
            onScanSaved: (_) {},
            onDiscussInChat: (_) {},
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.textContaining('Histology Biopsy AI'), findsOneWidget);
    });
  });
}
