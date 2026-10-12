import 'dart:convert';

class StudentProfile {
  // ── Primary Information (Stage 1: Auth) ──
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String studentId;

  // ── Secondary Information (Stage 2: Profile Page) ──
  final String? collegeName;
  final String? branch;
  final String? year;

  const StudentProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.studentId,
    this.collegeName,
    this.branch,
    this.year,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isSecondaryComplete =>
      collegeName != null &&
      collegeName!.trim().isNotEmpty &&
      branch != null &&
      branch!.trim().isNotEmpty &&
      year != null &&
      year!.trim().isNotEmpty;

  StudentProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? studentId,
    String? collegeName,
    String? branch,
    String? year,
  }) {
    return StudentProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      collegeName: collegeName ?? this.collegeName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'student_id': studentId,
      'college_name': collegeName,
      'branch': branch,
      'year': year,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      collegeName: map['college_name'] as String?,
      branch: map['branch'] as String?,
      year: map['year'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory StudentProfile.fromJson(String source) =>
      StudentProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
