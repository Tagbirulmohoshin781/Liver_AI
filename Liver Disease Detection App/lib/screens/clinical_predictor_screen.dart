import 'package:flutter/material.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/glass_text_field.dart';
import '../core/widgets/glass_gauge.dart';
import '../models/clinical_record.dart';
import '../models/user_profile.dart';
import '../services/clinical_risk_service.dart';

class ClinicalPredictorScreen extends StatefulWidget {
  final UserProfile profile;
  final Function(ClinicalRecord) onRecordSaved;

  const ClinicalPredictorScreen({
    super.key,
    required this.profile,
    required this.onRecordSaved,
  });

  @override
  State<ClinicalPredictorScreen> createState() => _ClinicalPredictorScreenState();
}

class _ClinicalPredictorScreenState extends State<ClinicalPredictorScreen> {
  final ClinicalRiskService _riskService = ClinicalRiskService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ageController;
  String _gender = 'Male';
  late TextEditingController _totBilirubinController;
  late TextEditingController _dirBilirubinController;
  late TextEditingController _alpController;
  late TextEditingController _sgptController;
  late TextEditingController _sgotController;
  late TextEditingController _proteinsController;
  late TextEditingController _albuminController;
  late TextEditingController _agRatioController;

  ClinicalRecord? _currentRecord;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: (widget.profile.age ?? 45).toString());
    _gender = widget.profile.gender ?? 'Male';
    _totBilirubinController = TextEditingController(text: '0.9');
    _dirBilirubinController = TextEditingController(text: '0.2');
    _alpController = TextEditingController(text: '120.0');
    _sgptController = TextEditingController(text: '32.0');
    _sgotController = TextEditingController(text: '28.0');
    _proteinsController = TextEditingController(text: '7.1');
    _albuminController = TextEditingController(text: '4.2');
    _agRatioController = TextEditingController(text: '1.4');

    // Run initial risk baseline
    _evaluateRisk();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _totBilirubinController.dispose();
    _dirBilirubinController.dispose();
    _alpController.dispose();
    _sgptController.dispose();
    _sgotController.dispose();
    _proteinsController.dispose();
    _albuminController.dispose();
    _agRatioController.dispose();
    super.dispose();
  }

  void _applyPreset(String type) {
    if (type == 'healthy') {
      _totBilirubinController.text = '0.7';
      _dirBilirubinController.text = '0.1';
      _alpController.text = '85.0';
      _sgptController.text = '22.0';
      _sgotController.text = '20.0';
      _proteinsController.text = '7.4';
      _albuminController.text = '4.5';
      _agRatioController.text = '1.6';
    } else if (type == 'moderate_nash') {
      _totBilirubinController.text = '1.5';
      _dirBilirubinController.text = '0.5';
      _alpController.text = '190.0';
      _sgptController.text = '84.0';
      _sgotController.text = '62.0';
      _proteinsController.text = '6.6';
      _albuminController.text = '3.3';
      _agRatioController.text = '0.9';
    } else if (type == 'severe_cirrhosis') {
      _totBilirubinController.text = '3.8';
      _dirBilirubinController.text = '1.9';
      _alpController.text = '310.0';
      _sgptController.text = '145.0';
      _sgotController.text = '195.0';
      _proteinsController.text = '5.4';
      _albuminController.text = '2.4';
      _agRatioController.text = '0.6';
    }
    _evaluateRisk();
  }

  void _evaluateRisk() {
    final record = _riskService.assessRisk(
      age: int.tryParse(_ageController.text) ?? 45,
      gender: _gender,
      totalBilirubin: double.tryParse(_totBilirubinController.text) ?? 0.8,
      directBilirubin: double.tryParse(_dirBilirubinController.text) ?? 0.2,
      alkalinePhosphotase: double.tryParse(_alpController.text) ?? 120.0,
      sgpt: double.tryParse(_sgptController.text) ?? 30.0,
      sgot: double.tryParse(_sgotController.text) ?? 30.0,
      totalProteins: double.tryParse(_proteinsController.text) ?? 7.0,
      albumin: double.tryParse(_albuminController.text) ?? 4.0,
      agRatio: double.tryParse(_agRatioController.text) ?? 1.2,
    );

    setState(() {
      _currentRecord = record;
    });

    widget.onRecordSaved(record);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            GlassCard(
              title: 'LPD Clinical Biomarker Assessment',
              subtitle: 'Liver Patient Dataset (LPD) Multi-Factor Risk Assessment',
              icon: Icons.science_outlined,
              iconColor: const Color(0xFF38BDF8),
              isGlow: isDark,
              child: Text(
                'Enter standard serum liver function test (LFT) values to calculate disease probability, identify abnormal biomarker patterns, and view clinical recommendations.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            // Quick Preset Chips
            Text(
              'QUICK LAB PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('🟢 Healthy Profile', style: TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  onPressed: () => _applyPreset('healthy'),
                ),
                ActionChip(
                  label: const Text('🟡 NASH / Elevated ALT', style: TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  onPressed: () => _applyPreset('moderate_nash'),
                ),
                ActionChip(
                  label: const Text('🔴 Advanced Fibrosis', style: TextStyle(fontSize: 11)),
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  onPressed: () => _applyPreset('severe_cirrhosis'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Live Risk Assessment Gauge ────────────────────────
            if (_currentRecord != null)
              GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(20),
                borderGradient: LinearGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    accent.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                child: Column(
                  children: [
                    GlassRiskGauge(
                      score: _currentRecord!.riskProbability,
                      label: _currentRecord!.riskLabel,
                      riskLevel: _currentRecord!.riskLevel,
                      size: 160,
                    ),
                    const SizedBox(height: 16),
                    // Contributing Factors
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CLINICAL FACTOR ANALYSIS:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white54 : Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._currentRecord!.contributingFactors.map((factor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _currentRecord!.riskLevel == 'Low'
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              size: 16,
                              color: _currentRecord!.riskLevel == 'Low'
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                factor,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Biomarker Input Fields Card ────────────────────────
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Biomarker Inputs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Age and Gender
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _ageController,
                          label: 'Age (Years)',
                          hintText: '45',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GlassContainer(
                              borderRadius: 14,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _gender,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF1B2433) : Colors.white,
                                  items: ['Male', 'Female'].map((g) {
                                    return DropdownMenuItem(
                                      value: g,
                                      child: Text(g, style: const TextStyle(fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _gender = val);
                                      _evaluateRisk();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bilirubin Row
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _totBilirubinController,
                          label: 'Total Bilirubin',
                          suffixText: 'mg/dL',
                          helperText: 'Normal: 0.2 - 1.2',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassTextField(
                          controller: _dirBilirubinController,
                          label: 'Direct Bilirubin',
                          suffixText: 'mg/dL',
                          helperText: 'Normal: 0.0 - 0.3',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Transaminases Row (ALT / AST)
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _sgptController,
                          label: 'SGPT / ALT',
                          suffixText: 'IU/L',
                          helperText: 'Normal: 7 - 56',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassTextField(
                          controller: _sgotController,
                          label: 'SGOT / AST',
                          suffixText: 'IU/L',
                          helperText: 'Normal: 10 - 40',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Alkaline Phosphatase
                  GlassTextField(
                    controller: _alpController,
                    label: 'Alkaline Phosphatase (ALP)',
                    suffixText: 'IU/L',
                    helperText: 'Normal: 44 - 147',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _evaluateRisk(),
                  ),
                  const SizedBox(height: 14),

                  // Proteins and Albumin Row
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _proteinsController,
                          label: 'Total Proteins',
                          suffixText: 'g/dL',
                          helperText: 'Normal: 6.0 - 8.3',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassTextField(
                          controller: _albuminController,
                          label: 'Serum Albumin',
                          suffixText: 'g/dL',
                          helperText: 'Normal: 3.5 - 5.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _evaluateRisk(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // A/G Ratio
                  GlassTextField(
                    controller: _agRatioController,
                    label: 'A/G Ratio (Albumin / Globulin)',
                    suffixText: 'Ratio',
                    helperText: 'Normal: 1.0 - 2.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _evaluateRisk(),
                  ),
                  const SizedBox(height: 18),

                  GlassButton(
                    onPressed: _evaluateRisk,
                    label: 'Calculate & Save Record',
                    icon: Icons.check_circle_outline,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
