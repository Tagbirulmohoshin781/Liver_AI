import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatService Offline Knowledge Tests', () {
    final chatService = ChatService();

    test('Generates Intent A Warning Signs response', () async {
      final msg = await chatService.sendMessage(
        userMessage: 'What are early warning signs of liver disease?',
        history: [],
      );

      expect(msg.text.contains('Warning Signs'), isTrue);
      expect(msg.text.contains('Jaundice'), isTrue);
      expect(msg.text.contains('external AI services are not available'), isFalse);
    });

    test('Generates Intent B Fatty Liver response', () async {
      final msg = await chatService.sendMessage(
        userMessage: 'Explain fatty liver NAFLD and NASH treatment',
        history: [],
      );

      expect(msg.text.contains('Fatty Liver Disease'), isTrue);
      expect(msg.text.contains('Steatosis'), isTrue);
      expect(msg.text.contains('external AI services are not available'), isFalse);
    });

    test('Parses Biopsy scan ID in Intent D', () async {
      final msg = await chatService.sendMessage(
        userMessage: 'Interpret scan findings ID: scan_1787846492516',
        history: [],
      );

      expect(msg.text.contains('Scan ID: scan_1787846492516'), isTrue);
      expect(msg.text.contains('Tissue Fibrosis Stage'), isTrue);
      expect(msg.text.contains('external AI services are not available'), isFalse);
    });
  });
}
