import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/glass_gauge.dart';
import '../models/biopsy_result.dart';
import '../services/onnx_vision_service.dart';

class BiopsyScannerScreen extends StatefulWidget {
  final Function(BiopsyResult) onScanSaved;
  final Function(BiopsyResult) onDiscussInChat;

  const BiopsyScannerScreen({
    super.key,
    required this.onScanSaved,
    required this.onDiscussInChat,
  });

  @override
  State<BiopsyScannerScreen> createState() => _BiopsyScannerScreenState();
}

class _BiopsyScannerScreenState extends State<BiopsyScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OnnxVisionService _visionService = OnnxVisionService();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isAnalyzing = false;
  BiopsyResult? _currentResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _visionService.initialize();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
          _currentResult = null;
        });
        _runInference();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not open image picker: $e';
      });
    }
  }

  /// Generate synthetic biopsy histology patch for instant demo testing
  void _loadSampleHistology(String sampleName, String severityType) {
    // Generate an RGB synthetic biopsy histology patch with H&E dye colors (pink eosin & purple hematoxylin)
    final image = img.Image(width: 224, height: 224);
    
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        // H&E stained hepatocytes pattern
        int r = (190 + (x * 7 + y * 13) % 45).clamp(0, 255);
        int g = (110 + (x * 11 + y * 3) % 35).clamp(0, 255);
        int b = (175 + (x * 5 + y * 17) % 55).clamp(0, 255);

        if (severityType == 'fibrotic') {
          // Collagen streaks
          if ((x + y) % 32 < 6) {
            r = 120; g = 140; b = 210;
          }
        } else if (severityType == 'steatotic') {
          // Fat vacuoles (white circles)
          if ((x % 40 - 20) * (x % 40 - 20) + (y % 40 - 20) * (y % 40 - 20) < 64) {
            r = 245; g = 245; b = 250;
          }
        }
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));
    setState(() {
      _selectedImageBytes = pngBytes;
      _selectedImageName = sampleName;
      _currentResult = null;
    });
    _runInference();
  }

  Future<void> _runInference() async {
    if (_selectedImageBytes == null) return;
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _visionService.analyzeBiopsyImage(
        imageBytes: _selectedImageBytes!,
        imageName: _selectedImageName ?? 'histology_patch.jpg',
      );

      setState(() {
        _currentResult = result;
        _isAnalyzing = false;
      });

      widget.onScanSaved(result);
    } catch (e) {
      setState(() {
        _errorMessage = 'Inference error: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GlassCard(
            title: 'Histology Biopsy AI',
            subtitle: 'PyTorch EfficientNet-B0 multi-label offline vision classifier',
            icon: Icons.biotech,
            iconColor: const Color(0xFF8B5CF6),
            isGlow: isDark,
            child: Text(
              'Upload or capture a microscopic liver biopsy patch image to screen for tissue fibrosis, inflammation, steatosis, or ballooning degeneration.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),

          // ── Image Upload & Preview Drop Zone ──────────────────
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                if (_selectedImageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          _selectedImageBytes!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 12, color: Color(0xFF34D399)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedImageName ?? 'Patch',
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Select or Capture Biopsy Patch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supported: JPG, PNG • 224×224 Microscopic ROI',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        label: 'Gallery',
                        icon: Icons.photo_library,
                        isPrimary: false,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        label: 'Camera',
                        icon: Icons.camera_alt,
                        isPrimary: false,
                        height: 44,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sample histology selector
                Text(
                  'Or test with a sample biopsy patch:',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Sample A: NASH Steatosis', style: TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      onPressed: () => _loadSampleHistology('sample_steatosis_patch.png', 'steatotic'),
                    ),
                    ActionChip(
                      label: const Text('Sample B: Bridging Fibrosis', style: TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      onPressed: () => _loadSampleHistology('sample_fibrosis_patch.png', 'fibrotic'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Loading Indicator ─────────────────────────────────
          if (_isAnalyzing)
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: accent),
                    const SizedBox(height: 14),
                    const Text(
                      'Running Offline ONNX Neural Inference...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Evaluating 224×224 normalized RGB tensor against EfficientNet-B0 weights',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          if (_errorMessage != null)
            GlassContainer(
              borderRadius: 14,
              fillColor: const Color(0xFFF87171).withValues(alpha: 0.12),
              borderColor: const Color(0xFFF87171).withValues(alpha: 0.3),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ── Diagnostic Results Card ────────────────────────────
          if (_currentResult != null) ...[
            GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              borderGradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                  accent.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Engine Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Histology AI Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentResult!.imageName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 12, color: Color(0xFF8B5CF6)),
                            SizedBox(width: 4),
                            Text(
                              'PyTorch ONNX',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Overall Severity Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(_currentResult!.overallSeverity).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _getSeverityColor(_currentResult!.overallSeverity).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          color: _getSeverityColor(_currentResult!.overallSeverity),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTIMATED HISTOLOGICAL STAGING',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentResult!.overallSeverity,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _getSeverityColor(_currentResult!.overallSeverity),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4 Disease Metric Bars
                  ..._currentResult!.metrics.values.map((metric) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassLinearProgressBar(
                        title: metric.name,
                        subtitle: metric.description,
                        value: metric.probability,
                        isPositive: metric.isPositive,
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Discuss in AI Chat Action
                  GlassButton(
                    onPressed: () => widget.onDiscussInChat(_currentResult!),
                    isFullWidth: true,
                    label: 'Discuss Findings in LiverAI Chat',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ],
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
