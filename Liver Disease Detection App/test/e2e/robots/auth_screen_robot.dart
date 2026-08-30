import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/screens/auth_screen.dart';

/// Screen Object Robot for testing [AuthScreen].
class AuthScreenRobot {
  final WidgetTester tester;

  AuthScreenRobot(this.tester);

  // Finders
  Finder get emailField => find.byKey(const Key('auth_email_input'));
  Finder get passwordField => find.byKey(const Key('auth_password_input'));
  Finder get submitButton => find.byKey(const Key('auth_submit_btn'));
  Finder get guestDemoButton => find.textContaining('Instant Demo');
  Finder get toggleModeButton => find.byKey(const Key('auth_toggle_mode_btn'));
  Finder get nameField => find.byKey(const Key('auth_name_input'));

  /// Fallback finders if keys are not specified
  Finder get emailFieldFallback => find.widgetWithText(TextField, 'Email Address');
  Finder get passwordFieldFallback => find.widgetWithText(TextField, 'Password');

  Future<void> enterEmail(String email) async {
    final target = emailField.evaluate().isNotEmpty ? emailField : emailFieldFallback;
    if (target.evaluate().isNotEmpty) {
      await tester.enterText(target, email);
      await tester.pumpAndSettle();
    }
  }

  Future<void> enterPassword(String password) async {
    final target = passwordField.evaluate().isNotEmpty ? passwordField : passwordFieldFallback;
    if (target.evaluate().isNotEmpty) {
      await tester.enterText(target, password);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapSubmit() async {
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapGuestDemo() async {
    if (guestDemoButton.evaluate().isNotEmpty) {
      await tester.tap(guestDemoButton);
      await tester.pumpAndSettle();
    }
  }

  Future<void> toggleAuthMode() async {
    if (toggleModeButton.evaluate().isNotEmpty) {
      await tester.tap(toggleModeButton);
      await tester.pumpAndSettle();
    }
  }
}
