import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/widgets/glass_container.dart';
import '../models/chat_message.dart';

enum AiMessageFormatMode {
  cards,
  tabs,
  document,
  summary,
}

class FormattedAiMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Color accent;
  final bool isDark;
  final String timeStr;
  final Function(String) onCopy;

  const FormattedAiMessageBubble({
    super.key,
    required this.message,
    required this.accent,
    required this.isDark,
    required this.timeStr,
    required this.onCopy,
  });

  @override
  State<FormattedAiMessageBubble> createState() => _FormattedAiMessageBubbleState();
}

class _FormattedAiMessageBubbleState extends State<FormattedAiMessageBubble> {
  AiMessageFormatMode _formatMode = AiMessageFormatMode.cards;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sections = widget.message.structuredSections;
    final hasSections = widget.message.hasMultipleSections;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accent,
                  const Color(0xFF6366F1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),

          // Message Content Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Format Selector Bar (Only displayed if message has structured sections)
                if (hasSections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFormatChip(
                            mode: AiMessageFormatMode.cards,
                            label: 'Cards',
                            icon: Icons.dashboard_outlined,
                          ),
                          const SizedBox(width: 6),
                          _buildFormatChip(
                            mode: AiMessageFormatMode.tabs,
                            label: 'Categories',
                            icon: Icons.tab_outlined,
                          ),
                          const SizedBox(width: 6),
                          _buildFormatChip(
                            mode: AiMessageFormatMode.document,
                            label: 'Document',
                            icon: Icons.article_outlined,
                          ),
                          if (widget.message.bulletPoints.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildFormatChip(
                              mode: AiMessageFormatMode.summary,
                              label: 'Summary',
                              icon: Icons.bolt_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Main Rendered Format Area
                _buildFormattedContent(sections, hasSections),

                const SizedBox(height: 6),

                // Footer with Timestamp & Copy actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => widget.onCopy(widget.message.text),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 12,
                                    color: widget.isDark ? Colors.white54 : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildFormatChip({
    required AiMessageFormatMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _formatMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _formatMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.accent.withValues(alpha: widget.isDark ? 0.25 : 0.15)
              : (widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? widget.accent
                : (widget.isDark ? Colors.white12 : Colors.black12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected
                  ? widget.accent
                  : (widget.isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? widget.accent
                    : (widget.isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(Map<String, String> sections, bool hasSections) {
    if (!hasSections || _formatMode == AiMessageFormatMode.document) {
      return _buildDocumentView(widget.message.text);
    }

    switch (_formatMode) {
      case AiMessageFormatMode.cards:
        return _buildCardsView(sections);
      case AiMessageFormatMode.tabs:
        return _buildTabsView(sections);
      case AiMessageFormatMode.summary:
        return _buildSummaryView();
      case AiMessageFormatMode.document:
        return _buildDocumentView(widget.message.text);
    }
  }

  // --- 1. Structured Cards View ---
  Widget _buildCardsView(Map<String, String> sections) {
    final entries = sections.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final header = entry.key;
        final content = entry.value;
        final categoryConfig = _getCategoryConfig(header);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            borderColor: categoryConfig.borderColor ?? (widget.isDark ? Colors.white12 : Colors.black12),
            fillColor: categoryConfig.fillColor ??
                (widget.isDark
                    ? const Color(0xFF131A26).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.85)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryConfig.iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        categoryConfig.icon,
                        size: 14,
                        color: categoryConfig.iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        header,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: categoryConfig.headerColor ??
                              (widget.isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Markdown Section Content
                _buildMarkdown(content),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 2. Interactive Category Tabs View ---
  Widget _buildTabsView(Map<String, String> sections) {
    final entries = sections.entries.toList();
    if (_selectedTabIndex >= entries.length) {
      _selectedTabIndex = 0;
    }

    final currentEntry = entries[_selectedTabIndex];
    final categoryConfig = _getCategoryConfig(currentEntry.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Navigation Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(entries.length, (idx) {
              final isSelected = _selectedTabIndex == idx;
              final config = _getCategoryConfig(entries[idx].key);
              final shortTitle = entries[idx].key
                  .replaceAll(RegExp(r'[^\w\s]'), '')
                  .trim()
                  .split(' ')
                  .take(2)
                  .join(' ');

              return GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = idx),
                child: Container(
                  margin: const EdgeInsets.only(right: 6, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? config.iconColor.withValues(alpha: 0.2)
                        : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? config.iconColor : (widget.isDark ? Colors.white12 : Colors.black12),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(config.icon, size: 12, color: isSelected ? config.iconColor : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        shortTitle.isEmpty ? 'Part ${idx + 1}' : shortTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? config.iconColor : (widget.isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // Selected Category Card
        GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(14),
          borderColor: categoryConfig.borderColor,
          fillColor: categoryConfig.fillColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categoryConfig.icon, size: 16, color: categoryConfig.iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentEntry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: categoryConfig.headerColor ?? (widget.isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              _buildMarkdown(currentEntry.value),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. Summary / Key Takeaways View ---
  Widget _buildSummaryView() {
    final bullets = widget.message.bulletPoints;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      borderColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
      fillColor: const Color(0xFF6366F1).withValues(alpha: widget.isDark ? 0.12 : 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Key Clinical Takeaways & Action Plan',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (bullets.isEmpty)
            _buildMarkdown(widget.message.text)
          else
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, right: 8),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: widget.isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // --- 4. Classic Unified Document View ---
  Widget _buildDocumentView(String text) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: _buildMarkdown(text),
    );
  }

  // --- Helper: Markdown Renderer ---
  Widget _buildMarkdown(String data) {
    return MarkdownBody(
      data: data,
      selectable: false,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: widget.isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
        ),
        h3: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: widget.isDark ? Colors.white : Colors.black,
        ),
        h4: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: widget.accent,
        ),
        blockquote: TextStyle(
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
          color: widget.isDark ? Colors.amber.shade200 : Colors.amber.shade900,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: widget.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: Colors.amber.shade600, width: 3),
          ),
        ),
        tableBorder: TableBorder.all(
          color: widget.isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        tableHead: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: widget.accent,
        ),
        tableBody: TextStyle(
          fontSize: 11.5,
          color: widget.isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  _CategoryConfig _getCategoryConfig(String header) {
    final lower = header.toLowerCase();

    if (lower.contains('clinical overview') || lower.contains('assessment')) {
      return _CategoryConfig(
        icon: Icons.health_and_safety_outlined,
        iconColor: const Color(0xFF3B82F6),
        borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        fillColor: const Color(0xFF3B82F6).withValues(alpha: widget.isDark ? 0.08 : 0.04),
        headerColor: const Color(0xFF3B82F6),
      );
    } else if (lower.contains('biomarker') || lower.contains('histolog') || lower.contains('lab')) {
      return _CategoryConfig(
        icon: Icons.biotech_outlined,
        iconColor: const Color(0xFF06B6D4),
        borderColor: const Color(0xFF06B6D4).withValues(alpha: 0.3),
        fillColor: const Color(0xFF06B6D4).withValues(alpha: widget.isDark ? 0.08 : 0.04),
        headerColor: const Color(0xFF06B6D4),
      );
    } else if (lower.contains('risk') || lower.contains('red flag') || lower.contains('warning') || lower.contains('caution')) {
      return _CategoryConfig(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFF59E0B),
        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        fillColor: const Color(0xFFF59E0B).withValues(alpha: widget.isDark ? 0.10 : 0.05),
        headerColor: const Color(0xFFF59E0B),
      );
    } else if (lower.contains('management') || lower.contains('nutrition') || lower.contains('protocol') || lower.contains('plan')) {
      return _CategoryConfig(
        icon: Icons.task_alt_rounded,
        iconColor: const Color(0xFF10B981),
        borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
        fillColor: const Color(0xFF10B981).withValues(alpha: widget.isDark ? 0.08 : 0.04),
        headerColor: const Color(0xFF10B981),
      );
    } else if (lower.contains('disclaimer')) {
      return _CategoryConfig(
        icon: Icons.gavel_outlined,
        iconColor: Colors.grey,
        borderColor: Colors.grey.withValues(alpha: 0.2),
        fillColor: Colors.grey.withValues(alpha: widget.isDark ? 0.06 : 0.03),
        headerColor: Colors.grey,
      );
    }

    return _CategoryConfig(
      icon: Icons.insights_outlined,
      iconColor: widget.accent,
      borderColor: widget.accent.withValues(alpha: 0.25),
      fillColor: widget.accent.withValues(alpha: widget.isDark ? 0.06 : 0.03),
      headerColor: widget.accent,
    );
  }
}

class _CategoryConfig {
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final Color? fillColor;
  final Color? headerColor;

  _CategoryConfig({
    required this.icon,
    required this.iconColor,
    this.borderColor,
    this.fillColor,
    this.headerColor,
  });
}
