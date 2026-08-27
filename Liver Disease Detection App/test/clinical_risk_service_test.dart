import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/services/clinical_risk_service.dart';

void main() {
  group('ClinicalRiskService Unit Tests', () {
    final riskService = ClinicalRiskService();

    test('Assesses normal biomarkers as Low Risk', () {
      final record = riskService.assessRisk(
        age: 35,
        gender: 'Female',
        totalBilirubin: 0.8,
        directBilirubin: 0.2,
        alkalinePhosphotase: 85.0,
        sgpt: 25.0,
        sgot: 22.0,
        totalProteins: 7.2,
        albumin: 4.2,
        agRatio: 1.4,
      );

      expect(record.riskLevel, equals('Low'));
      expect(record.riskLabel, equals('Low Risk'));
      expect(record.riskProbability, lessThan(0.35));
    });

    test('Assesses severe elevated enzymes as High Risk', () {
      final record = riskService.assessRisk(
        age: 58,
        gender: 'Male',
        totalBilirubin: 2.8,
        directBilirubin: 1.1,
        alkalinePhosphotase: 210.0,
        sgpt: 120.0,
        sgot: 160.0,
        totalProteins: 6.2,
        albumin: 3.1,
        agRatio: 0.8,
      );

      expect(record.riskLevel, equals('High'));
      expect(record.riskLabel, equals('At Risk'));
      expect(record.riskProbability, greaterThanOrEqualTo(0.65));
      expect(record.contributingFactors.isNotEmpty, isTrue);
    });

    test('Detects De Ritis ratio > 2.0 pattern', () {
      final record = riskService.assessRisk(
        age: 45,
        gender: 'Male',
        totalBilirubin: 1.5,
        directBilirubin: 0.4,
        alkalinePhosphotase: 110.0,
        sgpt: 40.0,
        sgot: 100.0, // AST / ALT = 2.5
        totalProteins: 7.0,
        albumin: 3.8,
        agRatio: 1.2,
      );

      expect(record.contributingFactors.any((f) => f.contains('AST/ALT Ratio > 2.0')), isTrue);
    });
  });
}
