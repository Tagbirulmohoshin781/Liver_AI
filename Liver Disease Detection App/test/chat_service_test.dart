import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatService Offline Knowledge Tests', () {
    final chatService = ChatService();

    test('Classifies clinical intents correctly', () {
      expect(ChatService.classifyClinicalIntent('Give me a 1 month liver diet plan'), 'timeline_plan');
      expect(ChatService.classifyClinicalIntent('30 day schedule for liver recovery'), 'timeline_plan');
      expect(ChatService.classifyClinicalIntent('How many pegs of alcohol are safe?'), 'alcohol_toxicity');
      expect(ChatService.classifyClinicalIntent('Can I drink beer or wine with fatty liver?'), 'alcohol_toxicity');
      expect(ChatService.classifyClinicalIntent('What are the warning signs of liver disease?'), 'symptoms');
      expect(ChatService.classifyClinicalIntent('Why is my ALT and AST elevated?'), 'biomarkers');
      expect(ChatService.classifyClinicalIntent('Interpret scan_1787846492516 biopsy'), 'histology_biopsy');
      expect(ChatService.classifyClinicalIntent('How to reverse fatty liver MASLD?'), 'fatty_liver');
    });

    test('Generates 1-Month 4-Week Regeneration Protocol response', () async {
      final msg = await chatService.sendMessage(
        userMessage: 'Give me a 1 month action plan to heal my liver',
        history: [],
      );

      expect(msg.text.contains('4-Week Step-by-Step Liver Regeneration Protocol'), isTrue);
      expect(msg.text.contains('Week 1: Metabolic Reset'), isTrue);
      expect(msg.text.contains('Week 2: Anti-Inflammatory'), isTrue);
      expect(msg.text.contains('Week 3: Mitochondrial'), isTrue);
      expect(msg.text.contains('Week 4: Biomarker Re-evaluation'), isTrue);
      expect(msg.text.contains('### 🩺 Clinical Overview & Assessment'), isTrue);
      expect(msg.text.contains('### ⚖️ Clinical Disclaimer'), isTrue);
      expect(msg.text.contains('external AI services are not available'), isFalse);
    });

    test('Generates Alcohol & Substance Toxicity response', () async {
      final msg = await chatService.sendMessage(
        userMessage: 'How many pegs of whiskey or alcohol are safe for fatty liver?',
        history: [],
      );

      expect(msg.text.contains('NO safe threshold'), isTrue);
      expect(msg.text.contains('acetaldehyde'), isTrue);
      expect(msg.text.contains('Mandatory Complete Abstinence'), isTrue);
      expect(msg.text.contains('### 🩺 Clinical Overview & Assessment'), isTrue);
      expect(msg.text.contains('### ⚖️ Clinical Disclaimer'), isTrue);
      expect(msg.text.contains('external AI services are not available'), isFalse);
    });

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
