class ClinicalRecord {
  final String id;
  final DateTime timestamp;
  final int age;
  final String gender; // 'Male' or 'Female'
  final double totalBilirubin;
  final double directBilirubin;
  final double alkalinePhosphotase;
  final double sgpt;
  final double sgot;
  final double totalProteins;
  final double albumin;
  final double agRatio;
  
  // Results
  final double riskProbability; // 0.0 to 1.0
  final String riskLabel; // 'At Risk' | 'Low Risk'
  final String riskLevel; // 'High' | 'Moderate' | 'Low'
  final List<String> contributingFactors;
  final String? patientNotes;

  ClinicalRecord({
    required this.id,
    required this.timestamp,
    required this.age,
    required this.gender,
    required this.totalBilirubin,
    required this.directBilirubin,
    required this.alkalinePhosphotase,
    required this.sgpt,
    required this.sgot,
    required this.totalProteins,
    required this.albumin,
    required this.agRatio,
    required this.riskProbability,
    required this.riskLabel,
    required this.riskLevel,
    required this.contributingFactors,
    this.patientNotes,
  });

  factory ClinicalRecord.fromJson(Map<String, dynamic> json) {
    return ClinicalRecord(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      age: json['age'] ?? 45,
      gender: json['gender'] ?? 'Male',
      totalBilirubin: (json['totalBilirubin'] as num?)?.toDouble() ?? 1.0,
      directBilirubin: (json['directBilirubin'] as num?)?.toDouble() ?? 0.3,
      alkalinePhosphotase: (json['alkalinePhosphotase'] as num?)?.toDouble() ?? 180.0,
      sgpt: (json['sgpt'] as num?)?.toDouble() ?? 30.0,
      sgot: (json['sgot'] as num?)?.toDouble() ?? 35.0,
      totalProteins: (json['totalProteins'] as num?)?.toDouble() ?? 6.8,
      albumin: (json['albumin'] as num?)?.toDouble() ?? 3.4,
      agRatio: (json['agRatio'] as num?)?.toDouble() ?? 1.0,
      riskProbability: (json['riskProbability'] as num?)?.toDouble() ?? 0.25,
      riskLabel: json['riskLabel'] ?? 'Low Risk',
      riskLevel: json['riskLevel'] ?? 'Low',
      contributingFactors: List<String>.from(json['contributingFactors'] ?? []),
      patientNotes: json['patientNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'age': age,
      'gender': gender,
      'totalBilirubin': totalBilirubin,
      'directBilirubin': directBilirubin,
      'alkalinePhosphotase': alkalinePhosphotase,
      'sgpt': sgpt,
      'sgot': sgot,
      'totalProteins': totalProteins,
      'albumin': albumin,
      'agRatio': agRatio,
      'riskProbability': riskProbability,
      'riskLabel': riskLabel,
      'riskLevel': riskLevel,
      'contributingFactors': contributingFactors,
      'patientNotes': patientNotes,
    };
  }
}
