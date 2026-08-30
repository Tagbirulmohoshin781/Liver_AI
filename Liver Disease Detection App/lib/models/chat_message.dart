import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? attachedImagePath;
  final List<String>? suggestions;
  final bool isError;
  final Map<String, dynamic>? biopsyData;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachedImagePath,
    this.suggestions,
    this.isError = false,
    this.biopsyData,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      attachedImagePath: json['attachedImagePath'],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      isError: json['isError'] ?? false,
      biopsyData: json['biopsyData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'attachedImagePath': attachedImagePath,
      'suggestions': suggestions,
      'isError': isError,
      'biopsyData': biopsyData,
    };
  }

  /// Regex to match markdown headers (## or ###), tolerating leading emojis, Unicode symbols, and trailing markdown characters
  static final RegExp sectionHeaderRegex = RegExp(
    r'^#{2,3}\s*(?:[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]\s*)?(.*?)$',
    multiLine: true,
    unicode: true,
  );

  /// Parses markdown headers (e.g., ### 🩺 Clinical Overview, ### 🔬 Biomarker, etc.) into structured sections.
  Map<String, String> get structuredSections {
    final sections = <String, String>{};
    final lines = text.split('\n');
    String currentHeader = '';
    final currentContent = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('### ') || trimmed.startsWith('## ')) {
        final match = sectionHeaderRegex.firstMatch(trimmed);
        if (currentHeader.isNotEmpty) {
          sections[currentHeader] = currentContent.toString().trim();
          currentContent.clear();
        }
        if (match != null && (match.group(1)?.trim().isNotEmpty ?? false)) {
          currentHeader = match.group(1)!.trim();
        } else {
          currentHeader = trimmed.replaceFirst(RegExp(r'^#{2,3}\s*'), '');
        }
      } else {
        if (currentHeader.isNotEmpty) {
          currentContent.writeln(line);
        } else {
          // Content before first header
          if (trimmed.isNotEmpty) {
            currentHeader = 'Clinical Overview';
            currentContent.writeln(line);
          }
        }
      }
    }

    if (currentHeader.isNotEmpty) {
      sections[currentHeader] = currentContent.toString().trim();
    }

    return sections;
  }

  bool get hasMultipleSections => structuredSections.length >= 2;

  /// Extracts key bullet takeaways for quick skimming.
  List<String> get bulletPoints {
    final bullets = <String>[];
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final clean = trimmed.replaceFirst(RegExp(r'^[-*]\s+|\d+\.\s+'), '').replaceAll('**', '');
        if (clean.isNotEmpty && clean.length > 5 && !clean.toLowerCase().contains('disclaimer')) {
          bullets.add(clean);
        }
      }
    }
    return bullets;
  }
}
