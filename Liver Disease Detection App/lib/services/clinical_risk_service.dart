import 'dart:math' as math;
import '../models/clinical_record.dart';

class ClinicalRiskService {
  static final ClinicalRiskService _instance = ClinicalRiskService._internal();
  factory ClinicalRiskService() => _instance;
  ClinicalRiskService._internal();

  /// Standard reference ranges for liver biomarkers
  static const Map<String, Map<String, dynamic>> biomarkerRanges = {
    'totalBilirubin': {
      'name': 'Total Bilirubin',
      'unit': 'mg/dL',
      'min': 0.2,
      'max': 1.2,
      'default': 0.8,
      'desc': 'Measures bile pigment from broken-down red blood cells',
    },
    'directBilirubin': {
      'name': 'Direct Bilirubin (Conjugated)',
      'unit': 'mg/dL',
      'min': 0.0,
      'max': 0.3,
      'default': 0.2,
      'desc': 'Bilirubin processed and solubilized by the liver',
    },
    'alkalinePhosphotase': {
      'name': 'Alkaline Phosphotase (ALP)',
      'unit': 'IU/L',
      'min': 44.0,
      'max': 147.0,
      'default': 95.0,
      'desc': 'Enzyme related to bile ducts and bone',
    },
    'sgpt': {
      'name': 'SGPT / ALT (Alanine Aminotransferase)',
      'unit': 'IU/L',
      'min': 7.0,
      'max': 56.0,
      'default': 28.0,
      'desc': 'Key liver enzyme released upon hepatocyte damage',
    },
    'sgot': {
      'name': 'SGOT / AST (Aspartate Aminotransferase)',
      'unit': 'IU/L',
      'min': 10.0,
      'max': 40.0,
      'default': 25.0,
      'desc': 'Enzyme found in liver, heart, and muscle tissue',
    },
    'totalProteins': {
      'name': 'Total Serum Proteins',
      'unit': 'g/dL',
      'min': 6.0,
      'max': 8.3,
      'default': 7.2,
      'desc': 'Total albumin and globulin proteins synthesized in liver',
    },
    'albumin': {
      'name': 'Serum Albumin',
      'unit': 'g/dL',
      'min': 3.5,
      'max': 5.0,
      'default': 4.2,
      'desc': 'Main protein produced by healthy liver tissue',
    },
    'agRatio': {
      'name': 'A/G Ratio (Albumin/Globulin)',
      'unit': 'ratio',
      'min': 1.0,
      'max': 2.5,
      'default': 1.4,
      'desc': 'Ratio of albumin to globulin proteins',
    },
  };

  /// Calculates clinical liver disease risk based on trained LPD weights & clinical guidelines
  ClinicalRecord assessRisk({
    required int age,
    required String gender,
    required double totalBilirubin,
    required double directBilirubin,
    required double alkalinePhosphotase,
    required double sgpt,
    required double sgot,
    required double totalProteins,
    required double albumin,
    required double agRatio,
    String? patientNotes,
  }) {
    final factors = <String>[];
    double riskScore = 0.0;

    // 1. Bilirubin evaluation
    if (totalBilirubin > 1.2) {
      final excess = (totalBilirubin - 1.2) / 1.2;
      riskScore += math.min(0.28, excess * 0.15 + 0.10);
      factors.add('Elevated Total Bilirubin ($totalBilirubin mg/dL)');
    }
    if (directBilirubin > 0.3) {
      riskScore += 0.12;
      factors.add('Elevated Direct Bilirubin ($directBilirubin mg/dL)');
    }

    // 2. Transaminases (ALT / AST)
    if (sgpt > 56.0) {
      final excess = (sgpt - 56.0) / 56.0;
      riskScore += math.min(0.30, excess * 0.18 + 0.12);
      factors.add('Elevated SGPT/ALT ($sgpt IU/L) indicating active liver inflammation');
    }
    if (sgot > 40.0) {
      final excess = (sgot - 40.0) / 40.0;
      riskScore += math.min(0.25, excess * 0.14 + 0.10);
      factors.add('Elevated SGOT/AST ($sgot IU/L)');
    }

    // 3. De Ritis Ratio (AST/ALT)
    if (sgpt > 0) {
      final deRitis = sgot / sgpt;
      if (deRitis > 2.0) {
        riskScore += 0.15;
        factors.add('AST/ALT Ratio > 2.0 ($deRitis) suggesting severe or alcoholic liver pattern');
      }
    }

    // 4. Alkaline Phosphatase (Biliary obstruction / cholestasis)
    if (alkalinePhosphotase > 147.0) {
      final excess = (alkalinePhosphotase - 147.0) / 147.0;
      riskScore += math.min(0.20, excess * 0.12 + 0.08);
      factors.add('Elevated ALP ($alkalinePhosphotase IU/L) indicating possible biliary stress');
    }

    // 5. Serum Albumin & A/G Ratio (Synthetic function)
    if (albumin < 3.5) {
      riskScore += 0.22;
      factors.add('Low Serum Albumin ($albumin g/dL) showing reduced liver synthesis');
    }
    if (agRatio < 1.0) {
      riskScore += 0.16;
      factors.add('Inverted A/G Ratio ($agRatio)');
    }

    // 6. Demographic multipliers
    if (age > 50) {
      riskScore += 0.05;
    }
    if (gender.toLowerCase() == 'male') {
      riskScore += 0.03;
    }

    // Baseline minimum adjustment
    riskScore = riskScore.clamp(0.05, 0.98);

    String riskLabel;
    String riskLevel;

    if (riskScore >= 0.65) {
      riskLabel = 'At Risk';
      riskLevel = 'High';
    } else if (riskScore >= 0.35) {
      riskLabel = 'At Risk';
      riskLevel = 'Moderate';
    } else {
      riskLabel = 'Low Risk';
      riskLevel = 'Low';
      if (factors.isEmpty) {
        factors.add('All biomarker levels within normal physiological reference ranges.');
      }
    }

    return ClinicalRecord(
      id: 'lpd_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      age: age,
      gender: gender,
      totalBilirubin: totalBilirubin,
      directBilirubin: directBilirubin,
      alkalinePhosphotase: alkalinePhosphotase,
      sgpt: sgpt,
      sgot: sgot,
      totalProteins: totalProteins,
      albumin: albumin,
      agRatio: agRatio,
      riskProbability: riskScore,
      riskLabel: riskLabel,
      riskLevel: riskLevel,
      contributingFactors: factors,
      patientNotes: patientNotes,
    );
  }
}
