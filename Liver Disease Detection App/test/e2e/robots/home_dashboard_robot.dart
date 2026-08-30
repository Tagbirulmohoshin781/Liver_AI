import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen Object Robot for testing [HomeDashboardScreen].
class HomeDashboardRobot {
  final WidgetTester tester;

  HomeDashboardRobot(this.tester);

  Finder get chatCard => find.textContaining('Clinical AI Chat');
  Finder get biopsyCard => find.textContaining('Biopsy AI Scanner');
  Finder get predictorCard => find.textContaining('Clinical Risk');
  Finder get historyCard => find.textContaining('Diagnostic History');

  Future<void> tapChatCard() async {
    if (chatCard.evaluate().isNotEmpty) {
      await tester.tap(chatCard);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapBiopsyCard() async {
    if (biopsyCard.evaluate().isNotEmpty) {
      await tester.tap(biopsyCard);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapPredictorCard() async {
    if (predictorCard.evaluate().isNotEmpty) {
      await tester.tap(predictorCard);
      await tester.pumpAndSettle();
    }
  }
}
