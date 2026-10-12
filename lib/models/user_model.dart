class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? studentId;
  final String? university;
  final String? major;
  final String? avatarUrl;
  final bool isActive;
  final String? companyName;
  final String? currentPhase;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentId,
    this.university,
    this.major,
    this.avatarUrl,
    this.isActive = true,
    this.companyName = 'LG Display',
    this.currentPhase = 'adaptation',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Sinh viên Enigma',
      role: json['role'] ?? 'student',
      studentId: json['student_id'],
      university: json['university'],
      major: json['major'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      companyName: json['company_name'] ?? 'LG Display',
      currentPhase: json['current_phase'] ?? 'adaptation',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'student_id': studentId,
      'university': university,
      'major': major,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'company_name': companyName,
      'current_phase': currentPhase,
    };
  }

  String get phaseDisplay {
    switch (currentPhase) {
      case 'preparation':
        return 'Chặng 1: Chuẩn bị hành trang';
      case 'adaptation':
        return 'Chặng 2: Hòa nhập tháng đầu';
      case 'sustain':
        return 'Chặng 3: Duy trì & Bứt phá';
      default:
        return 'Chặng 2: Hòa nhập tháng đầu';
    }
  }
}
