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
}
