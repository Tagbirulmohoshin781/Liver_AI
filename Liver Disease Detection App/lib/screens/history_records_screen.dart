import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/widgets/glass_container.dart';
import '../models/biopsy_result.dart';
import '../models/clinical_record.dart';

class HistoryRecordsScreen extends StatefulWidget {
  final List<BiopsyResult> biopsyHistory;
  final List<ClinicalRecord> clinicalHistory;
  final Function(String) onDeleteBiopsy;
  final Function(String) onDeleteClinical;

  const HistoryRecordsScreen({
    super.key,
    required this.biopsyHistory,
    required this.clinicalHistory,
    required this.onDeleteBiopsy,
    required this.onDeleteClinical,
  });

  @override
  State<HistoryRecordsScreen> createState() => _HistoryRecordsScreenState();
}

class _HistoryRecordsScreenState extends State<HistoryRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Tab Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.biotech, size: 16),
                      const SizedBox(width: 6),
                      Text('Biopsy (${widget.biopsyHistory.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.science, size: 16),
                      const SizedBox(width: 6),
                      Text('Clinical (${widget.clinicalHistory.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBiopsyList(accent, isDark),
              _buildClinicalList(accent, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiopsyList(Color accent, bool isDark) {
    if (widget.biopsyHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.biotech,
        title: 'No Biopsy Scans Found',
        subtitle: 'Run a microscopic patch scan in Biopsy AI to save diagnostic reports.',
        accent: accent,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      itemCount: widget.biopsyHistory.length,
      itemBuilder: (context, index) {
        final scan = widget.biopsyHistory[index];
        final timeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(scan.timestamp);

        return GlassContainer(
          borderRadius: 18,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.imageName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
                    onPressed: () => widget.onDeleteBiopsy(scan.id),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Severity Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(scan.overallSeverity).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'STAGING: ${scan.overallSeverity.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getSeverityColor(scan.overallSeverity),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Metrics Preview
              ...scan.metrics.values.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      Text(
                        '${m.isPositive ? "DETECTED" : "NORMAL"} (${m.probability.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: m.isPositive ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClinicalList(Color accent, bool isDark) {
    if (widget.clinicalHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.science,
        title: 'No Clinical Records Found',
        subtitle: 'Calculate liver biomarker risk in the Clinical tab to store patient history.',
        accent: accent,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      itemCount: widget.clinicalHistory.length,
      itemBuilder: (context, index) {
        final rec = widget.clinicalHistory[index];
        final timeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(rec.timestamp);

        return GlassContainer(
          borderRadius: 18,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient: ${rec.age}y / ${rec.gender}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
                    onPressed: () => widget.onDeleteClinical(rec.id),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (rec.riskLevel == 'Low' ? const Color(0xFF34D399) : const Color(0xFFF87171))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'RISK: ${rec.riskLevel.toUpperCase()} (${(rec.riskProbability * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rec.riskLevel == 'Low' ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _miniStat('Total Bilirubin', '${rec.totalBilirubin} mg/dL', isDark),
                  _miniStat('SGPT/ALT', '${rec.sgpt} IU/L', isDark),
                  _miniStat('SGOT/AST', '${rec.sgot} IU/L', isDark),
                  _miniStat('Albumin', '${rec.albumin} g/dL', isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String val, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains('Severe') || severity.contains('F3') || severity.contains('F4')) {
      return const Color(0xFFF87171);
    }
    if (severity.contains('Moderate') || severity.contains('F2')) {
      return const Color(0xFFFBBF24);
    }
    return const Color(0xFF34D399);
  }
}
