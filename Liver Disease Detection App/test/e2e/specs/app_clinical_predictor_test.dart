import 'package:flutter_test/flutter_test.dart';
import 'package:liver_disease_detection_app/services/clinical_risk_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile E2E Spec: Clinical Risk Predictor & Math Parity', () {
    final riskService = ClinicalRiskService();

    test('CLIN-03: ClinicalRiskService calculates risk accurately on boundary conditions', () {
      final healthyResult = riskService.assessRisk(
        age: 30,
        gender: 'Male',
        totalBilirubin: 0.8,
        directBilirubin: 0.2,
        alkalinePhosphotase: 80.0,
        sgpt: 25.0,
        sgot: 22.0,
        totalProteins: 7.2,
        albumin: 4.5,
        agRatio: 1.5,
      );

      expect(healthyResult.riskLevel.toLowerCase(), equals('low'));
      expect(healthyResult.riskProbability, lessThan(0.40));

      final elevatedResult = riskService.assessRisk(
        age: 55,
        gender: 'Male',
        totalBilirubin: 3.5,
        directBilirubin: 1.8,
        alkalinePhosphotase: 280.0,
        sgpt: 120.0,
        sgot: 110.0,
        totalProteins: 5.8,
        albumin: 2.8,
        agRatio: 0.7,
      );

      expect(elevatedResult.riskProbability, greaterThan(healthyResult.riskProbability));
      expect(elevatedResult.riskLevel, equals('High'));
    });
  });
}
