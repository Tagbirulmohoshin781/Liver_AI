import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [BiopsyScannerScreen].
class BiopsyScannerRobot {
  final WidgetTester tester;

  BiopsyScannerRobot(this.tester);

  Finder get cameraButton => find.byIcon(Icons.camera_alt_rounded);
  Finder get galleryButton => find.byIcon(Icons.photo_library_rounded);
  Finder get scanCard => find.textContaining('Histopathology');
  Finder get analyzeButton => find.textContaining('Analyze');

  Future<void> tapGalleryButton() async {
    if (galleryButton.evaluate().isNotEmpty) {
      await tester.tap(galleryButton);
      await tester.pumpAndSettle();
    }
  }
}
