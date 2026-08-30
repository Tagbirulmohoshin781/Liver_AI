import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [AiChatScreen].
class AiChatScreenRobot {
  final WidgetTester tester;

  AiChatScreenRobot(this.tester);

  Finder get chatInputField => find.byType(TextField);
  Finder get sendButton => find.byIcon(Icons.send_rounded);
  Finder get suggestionChips => find.textContaining('Warning Signs');
  Finder get quickChips => find.textContaining('ALT / AST');

  Future<void> enterMessage(String message) async {
    final fields = chatInputField.evaluate();
    if (fields.isNotEmpty) {
      await tester.enterText(chatInputField.last, message);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapSend() async {
    if (sendButton.evaluate().isNotEmpty) {
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapSuggestionChip(String chipText) async {
    final chip = find.textContaining(chipText);
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip.first);
      await tester.pumpAndSettle();
    }
  }
}
