class UserProfile {
  String id;
  String name;
  String email;
  String? password;
  bool isAdmin;
  String role; // 'Admin' | 'Patient'
  int? age;
  String? gender;
  String? bloodGroup;
  String? medicalNotes;
  bool hasHepatitisHistory;
  bool hasFattyLiverHistory;
  bool alcoholConsumption;
  DateTime lastUpdated;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.isAdmin = false,
    this.role = 'Patient',
    this.age,
    this.gender,
    this.bloodGroup,
    this.medicalNotes,
    this.hasHepatitisHistory = false,
    this.hasFattyLiverHistory = false,
    this.alcoholConsumption = false,
    required this.lastUpdated,
  });

  factory UserProfile.defaultProfile() => UserProfile.defaultPatient();

  factory UserProfile.defaultPatient() {
    return UserProfile(
      id: 'usr_patient_demo',
      name: 'Dipto (Patient)',
      email: 'dipto@liverai.health',
      password: 'password123',
      isAdmin: false,
      role: 'Patient',
      age: 32,
      gender: 'Male',
      bloodGroup: 'O+',
      medicalNotes: 'Routine checkup. Mild elevated ALT observed last year.',
      hasHepatitisHistory: false,
      hasFattyLiverHistory: true,
      alcoholConsumption: false,
      lastUpdated: DateTime.now(),
    );
  }

  factory UserProfile.defaultAdmin() {
    return UserProfile(
      id: 'usr_admin_demo',
      name: 'Dr. Sarah Connor (Admin)',
      email: 'admin@liverai.health',
      password: 'adminpassword',
      isAdmin: true,
      role: 'Admin',
      age: 42,
      gender: 'Female',
      bloodGroup: 'A+',
      medicalNotes: 'Lead Hepatologist & Clinical Administrator.',
      hasHepatitisHistory: false,
      hasFattyLiverHistory: false,
      alcoholConsumption: false,
      lastUpdated: DateTime.now(),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final bool isAdm = json['isAdmin'] == true ||
        json['is_admin'] == 1 ||
        json['is_admin'] == true ||
        json['role'] == 'Admin';

    return UserProfile(
      id: json['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? json['username'] ?? 'User',
      email: json['email'] ?? 'user@liverai.health',
      password: json['password'],
      isAdmin: isAdm,
      role: isAdm ? 'Admin' : 'Patient',
      age: json['age'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'] ?? json['blood_group'],
      medicalNotes: json['medicalNotes'] ?? json['medical_notes'],
      hasHepatitisHistory: json['hasHepatitisHistory'] ?? false,
      hasFattyLiverHistory: json['hasFattyLiverHistory'] ?? false,
      alcoholConsumption: json['alcoholConsumption'] ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isAdmin': isAdmin,
      'role': isAdmin ? 'Admin' : 'Patient',
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'medicalNotes': medicalNotes,
      'hasHepatitisHistory': hasHepatitisHistory,
      'hasFattyLiverHistory': hasFattyLiverHistory,
      'alcoholConsumption': alcoholConsumption,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
