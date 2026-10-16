import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/glass_theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/chat_service.dart';

class SettingsScreen extends StatefulWidget {
  final GlassTheme glassTheme;
  final VoidCallback onClearAllData;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.glassTheme,
    required this.onClearAllData,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _hexController = TextEditingController();

  bool _useAdvancedIntelligence = true;
  String _selectedModel = 'groq';
  String _responseStyle = 'easy';
  double _temperature = 0.25;
  int _maxTokens = 1024;
  bool _enableAasld = true;
  bool _enableEasl = true;

  @override
  void initState() {
    super.initState();
    _useAdvancedIntelligence = _chatService.isAdvancedIntelligenceEnabled;
    _selectedModel = _chatService.selectedModel;
    _responseStyle = _chatService.responseStyle;
    _temperature = _chatService.temperature;
    _maxTokens = _chatService.maxTokens;
    _enableAasld = _chatService.enableAasldRag;
    _enableEasl = _chatService.enableEaslRag;

    final hexStr = widget.glassTheme.accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    _hexController.text = '#$hexStr';
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    _chatService.configure(
      useAdvancedIntelligence: _useAdvancedIntelligence,
      selectedModel: _selectedModel,
      responseStyle: _responseStyle,
      temperature: _temperature,
      maxTokens: _maxTokens,
      enableAasldRag: _enableAasld,
      enableEaslRag: _enableEasl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Model tuning & Theme settings synchronized successfully!'),
        backgroundColor: Color(0xFF10A37F),
      ),
    );
  }

  void _applyCustomHex(String val) {
    String clean = val.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final int? hexInt = int.tryParse(clean, radix: 16);
      if (hexInt != null) {
        final newColor = Color(0xFF000000 | hexInt);
        widget.glassTheme.setCustomAccent(newColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.glassTheme;
    final isDark = theme.isDarkMode;
    final accent = theme.accentColor;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Settings Card
          GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            borderGradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.5),
                const Color(0xFF6366F1).withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.tune, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engine, Themes & AI Studio',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Full 9-theme studio, custom hex accents & AI diagnostic tuning',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 1. 9 WEBSITE THEME PRESETS ───────────────────────
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Theme Presets (Website Engine)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          theme.currentPreset.name,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid of 9 theme cards (Responsive childAspectRatio based on font scale)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: (1.35 / (theme.fontScale > 1.15 ? (theme.fontScale * 0.75) : 1.0)).clamp(0.95, 1.40),
                  children: AppColors.themePresets.values.map((preset) {
                    final isSelected = theme.themePresetId == preset.id;
                    return GestureDetector(
                      onTap: () => theme.setThemePreset(preset.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: preset.bgPrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accent : preset.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: preset.bgSecondary)),
                                const SizedBox(width: 4),
                                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: preset.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                preset.name.split(' ')[0],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: preset.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 22),

                // Accent Color Swatches
                const Text('Accent Palette & Custom Studio', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...AppColors.accentThemes.map((item) {
                      final isSelected = theme.accentId == item.id;
                      return GestureDetector(
                        onTap: () {
                          theme.setAccent(item.id);
                          final hexStr = item.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
                          _hexController.text = '#$hexStr';
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: item.gradient),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: item.glowColor,
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // Custom Hex Input Box
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: TextField(
                          controller: _hexController,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Custom HEX (e.g. #10A37F)',
                            isDense: true,
                          ),
                          onChanged: _applyCustomHex,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),

                // Glass Blur Slider (Stress Tested 0 - 200px)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Glass Blur Intensity',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${theme.blurSigma.toInt()} px', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: accent)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: theme.blurSigma.clamp(0.0, 200.0),
                    min: 0.0,
                    max: 200.0,
                    divisions: 40,
                    activeColor: accent,
                    onChanged: (v) => theme.setBlurSigma(v),
                  ),
                ),

                // Font Size Scale (A11y Extreme Scaling 85% - 200%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Font Size Scale (Accessibility)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(theme.fontScale * 100).toInt()}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: accent)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: theme.fontScale.clamp(0.85, 2.0),
                    min: 0.85,
                    max: 2.0,
                    divisions: 23,
                    activeColor: accent,
                    onChanged: (v) => theme.setFontScale(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 2. AI MODEL TUNING & INTELLIGENCE LEVEL ──────────
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 20, color: accent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI Model Tuning & Intelligence',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // AI Engine Selector (From Website)
                const Text('AI Intelligence Engine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _modelPill('groq', 'Groq Llama-3.3 70B', accent, isDark),
                    const SizedBox(width: 6),
                    _modelPill('deepseek', 'DeepSeek Reasoner', accent, isDark),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _modelPill('gemini', 'Gemini 2.5 Flash', accent, isDark),
                    const SizedBox(width: 6),
                    _modelPill('lora', 'Liver LoRA Fine-Tuned', accent, isDark),
                  ],
                ),
                const Divider(height: 20),

                // Response Style Mode (From Website)
                const Text('Response Style & Diagnostic Formatting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _stylePill('easy', 'Concise & Easy', isDark),
                    _stylePill('detailed', 'Clinical Comprehensive', isDark),
                    _stylePill('bullet', 'Structured Bullet Points', isDark),
                    _stylePill('creative', 'Deep Medical Reasoning', isDark),
                  ],
                ),
                const Divider(height: 20),

                // Diagnostic Reasoning Temperature
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Diagnostic Temperature',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_temperature (${_temperature <= 0.3 ? "Strict Factual" : (_temperature <= 0.7 ? "Balanced" : "Exploratory")})',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _temperature,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: accent,
                    onChanged: (v) => setState(() => _temperature = double.parse(v.toStringAsFixed(2))),
                  ),
                ),
                const SizedBox(height: 6),

                // Max Tokens Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Max Output Tokens',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$_maxTokens tokens', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _maxTokens.toDouble(),
                    min: 512,
                    max: 2048,
                    divisions: 3,
                    activeColor: accent,
                    onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                  ),
                ),
                const Divider(height: 20),

                // Clinical Protocol RAG Toggles
                const Text('Clinical Guidelines RAG Integration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _protocolToggle(
                  title: 'AASLD Guidelines Protocol',
                  subtitle: 'American Association for the Study of Liver Diseases',
                  value: _enableAasld,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) => setState(() => _enableAasld = v),
                ),
                const SizedBox(height: 8),
                _protocolToggle(
                  title: 'EASL Clinical Guidelines',
                  subtitle: 'European Association for the Study of the Liver',
                  value: _enableEasl,
                  accent: accent,
                  isDark: isDark,
                  onChanged: (v) => setState(() => _enableEasl = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 3. DATA & SYSTEM ACTIONS ────────────────────────
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: accent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Data Persistence & Session Actions',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Save Configuration Button
                GlassButton(
                  onPressed: _saveSettings,
                  label: 'Save & Apply All Settings',
                  icon: Icons.save_outlined,
                  isFullWidth: true,
                  height: 48,
                ),
                const SizedBox(height: 12),

                // Clear Local History
                GlassButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Local History?'),
                        content: const Text('This will clear local cached scans, clinical records, and conversations.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onClearAllData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Local diagnostics cleared.')),
                              );
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  label: 'Clear Local Cache & Chat Logs',
                  icon: Icons.delete_forever_outlined,
                  isPrimary: false,
                  color: const Color(0xFFF97316),
                  isFullWidth: true,
                  height: 48,
                ),
                const SizedBox(height: 12),

                // Sign Out Button
                GlassButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out of your LiverAI account?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onLogout();
                            },
                            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  label: 'Sign Out Account',
                  icon: Icons.logout,
                  isPrimary: false,
                  color: const Color(0xFFF87171),
                  isFullWidth: true,
                  height: 48,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _protocolToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeTrackColor: accent.withValues(alpha: 0.5),
            activeThumbColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _modelPill(String id, String label, Color accent, bool isDark) {
    final isSelected = _selectedModel == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedModel = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.18) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stylePill(String id, String label, bool isDark) {
    final isSelected = _responseStyle == id;
    final accent = widget.glassTheme.accentColor;
    return GestureDetector(
      onTap: () => setState(() => _responseStyle = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.18) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
