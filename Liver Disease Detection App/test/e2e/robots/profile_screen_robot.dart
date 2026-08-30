import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [ProfileScreen].
class ProfileScreenRobot {
  final WidgetTester tester;

  ProfileScreenRobot(this.tester);

  Finder get userNameText => find.textContaining('Admin');
  Finder get ageField => find.widgetWithText(TextField, 'Age');
  Finder get genderDropdown => find.textContaining('Gender');
  Finder get saveButton => find.textContaining('Save Profile');

  Future<void> enterAge(String age) async {
    final field = find.widgetWithText(TextField, 'Age');
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field, age);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapSaveProfile() async {
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
    }
  }
}
