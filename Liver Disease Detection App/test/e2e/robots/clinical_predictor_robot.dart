import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [ClinicalPredictorScreen].
class ClinicalPredictorRobot {
  final WidgetTester tester;

  ClinicalPredictorRobot(this.tester);

  Finder get calculateButton => find.textContaining('Calculate');
  Finder get ageField => find.widgetWithText(TextField, 'Age');
  Finder get directBilirubinField => find.widgetWithText(TextField, 'Direct Bilirubin');
  Finder get calculateRiskButton => find.widgetWithText(ElevatedButton, 'Calculate Risk Score');

  Future<void> enterBiomarkerValue(String label, String value) async {
    final field = find.widgetWithText(TextField, label);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapCalculate() async {
    final btn = find.textContaining('Calculate');
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn.first);
      await tester.pumpAndSettle();
    }
  }
}
