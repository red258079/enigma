class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'student' or 'admin'
  final String? studentId;
  final String? university;
  final String? major;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.studentId,
    this.university,
    this.major,
    this.avatarUrl,
  });

  bool get isGuest => id == 'guest';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      role: json['role'] ?? 'student',
      studentId: json['student_id'] ?? json['studentId'],
      university: json['university'],
      major: json['major'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'studentId': studentId,
      'university': university,
      'major': major,
      'avatarUrl': avatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? studentId,
    String? university,
    String? major,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      university: university ?? this.university,
      major: major ?? this.major,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

