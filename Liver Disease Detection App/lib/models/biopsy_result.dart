class BiopsyResult {
  final String id;
  final String? imagePath;
  final String imageName;
  final DateTime timestamp;
  final Map<String, BiopsyMetric> metrics;
  final String executionEngine; // 'PyTorch (ONNX)' or 'Simulated'
  final String overallSeverity; // 'Normal', 'Mild', 'Moderate', 'Severe'
  final String? notes;

  BiopsyResult({
    required this.id,
    this.imagePath,
    required this.imageName,
    required this.timestamp,
    required this.metrics,
    this.executionEngine = 'PyTorch (ONNX)',
    required this.overallSeverity,
    this.notes,
  });

  factory BiopsyResult.fromJson(Map<String, dynamic> json) {
    final metricsMap = <String, BiopsyMetric>{};
    if (json['metrics'] != null) {
      (json['metrics'] as Map<String, dynamic>).forEach((k, v) {
        metricsMap[k] = BiopsyMetric.fromJson(v);
      });
    }

    return BiopsyResult(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: json['imagePath'],
      imageName: json['imageName'] ?? 'histology_patch.jpg',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      metrics: metricsMap,
      executionEngine: json['executionEngine'] ?? 'PyTorch (ONNX)',
      overallSeverity: json['overallSeverity'] ?? 'Moderate',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    final metricsJson = <String, dynamic>{};
    metrics.forEach((k, v) => metricsJson[k] = v.toJson());

    return {
      'id': id,
      'imagePath': imagePath,
      'imageName': imageName,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metricsJson,
      'executionEngine': executionEngine,
      'overallSeverity': overallSeverity,
      'notes': notes,
    };
  }
}

class BiopsyMetric {
  final String id;
  final String name;
  final String description;
  final double probability; // 0 to 100
  final bool isPositive;

  BiopsyMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.probability,
    required this.isPositive,
  });

  factory BiopsyMetric.fromJson(Map<String, dynamic> json) {
    return BiopsyMetric(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      isPositive: json['isPositive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'probability': probability,
      'isPositive': isPositive,
    };
  }
}
