import 'package:flutter/material.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_container.dart';
import '../models/user_profile.dart';
import '../models/biopsy_result.dart';
import '../models/clinical_record.dart';

class HomeDashboardScreen extends StatelessWidget {
  final UserProfile profile;
  final List<BiopsyResult> biopsyHistory;
  final List<ClinicalRecord> clinicalHistory;
  final Function(int) onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    required this.profile,
    required this.biopsyHistory,
    required this.clinicalHistory,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final latestBiopsy = biopsyHistory.isNotEmpty ? biopsyHistory.first : null;
    final latestClinical = clinicalHistory.isNotEmpty ? clinicalHistory.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Patient Glass Card ───────────────────────────
          GlassContainer(
            borderRadius: 24,
            isGlow: true,
            padding: const EdgeInsets.all(20),
            borderGradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.1),
                const Color(0xFF6366F1).withValues(alpha: 0.4),
              ],
            ),
            child: Row(
              children: [
                // Avatar Ring
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, const Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hello, ${profile.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: profile.isAdmin
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                  : accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              profile.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: profile.isAdmin ? const Color(0xFF8B5CF6) : accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.isAdmin
                            ? 'Clinical Administrator • System Telemetry Active'
                            : 'Liver Health & Histology Monitoring Hub',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick Diagnostic Status Grid ───────────────────────
          Row(
            children: [
              // Biopsy Scans Total
              Expanded(
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.biotech,
                              size: 18,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          Text(
                            '${biopsyHistory.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Biopsy Scans',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latestBiopsy != null
                            ? 'Latest: ${latestBiopsy.overallSeverity}'
                            : 'No scans recorded',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Clinical Tests Total
              Expanded(
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.monitor_heart,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          Text(
                            '${clinicalHistory.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Clinical Records',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latestClinical != null
                            ? 'Risk: ${latestClinical.riskLevel}'
                            : 'No lab records',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick Launch Actions ──────────────────────────────
          Text(
            'QUICK TOOLS & ENGINES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Admin Console shortcut if Admin
          if (profile.isAdmin)
            GlassCard(
              title: 'Administrator Console',
              subtitle: 'System metrics, telemetry, and user access management',
              icon: Icons.admin_panel_settings,
              iconColor: const Color(0xFF8B5CF6),
              onTap: () => onNavigateTab(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _FeaturePill(label: 'Admin Exclusive', color: Color(0xFF8B5CF6)),
                        _FeaturePill(label: 'Telemetry', color: Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                ],
              ),
            ),

          // 1. Biopsy AI Launcher
          GlassCard(
            title: 'Histology Biopsy Scanner',
            subtitle: 'Offline ONNX EfficientNet-B0 vision model for microscopic patches',
            icon: Icons.camera_enhance,
            iconColor: const Color(0xFF8B5CF6),
            onTap: () => onNavigateTab(1),
            isGlow: isDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const _FeaturePill(label: 'Offline ONNX', color: Color(0xFF8B5CF6)),
                      _FeaturePill(label: '4 Classes', color: accent),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.black38),
              ],
            ),
          ),

          // 2. Clinical Risk Calculator Launcher
          GlassCard(
            title: 'LPD Clinical Biomarker Risk',
            subtitle: 'Calculate liver disease probability using ALT, AST, Bilirubin & Albumin',
            icon: Icons.science,
            iconColor: const Color(0xFF38BDF8),
            onTap: () => onNavigateTab(2),
            isGlow: isDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _FeaturePill(label: '10 Biomarkers', color: Color(0xFF38BDF8)),
                      _FeaturePill(label: 'Instant Risk %', color: Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.black38),
              ],
            ),
          ),

          // 3. AI Health Assistant
          GlassCard(
            title: 'LiverAI Conversational Assistant',
            subtitle: 'Ask questions about liver health, medications, and diet guidelines',
            icon: Icons.forum,
            iconColor: accent,
            onTap: () => onNavigateTab(3),
            isGlow: isDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _FeaturePill(label: 'AASLD Guidelines', color: accent),
                      const _FeaturePill(label: 'Dual Offline/Online', color: Color(0xFF34D399)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.black38),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Health Tip Card ───────────────────────────────────
          GlassContainer(
            borderRadius: 18,
            fillColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liver Health Protocol',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clinical studies demonstrate that 2-3 cups of filtered black coffee daily and 150 min/week of moderate exercise significantly lower liver fat and ALT enzymes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  final Color color;

  const _FeaturePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
