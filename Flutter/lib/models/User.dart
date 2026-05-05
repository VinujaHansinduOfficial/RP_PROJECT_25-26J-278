class User {
  final String patientId;
  final String firstName;
  final String email;
  final bool hasAssignedDoctors;

  // Optional fields for backward compatibility
  final String? fullName;
  final String? gender;
  final String? phone;
  final String? dob;
  final String? role;
  final String? joinedAt;
  final int age = 0; // ← default age field for backward compatibility

  User({
    required this.patientId,
    required this.firstName,
    required this.email,
    required this.hasAssignedDoctors,
    this.fullName,
    this.gender,
    this.phone,
    this.dob,
    this.role,
    this.joinedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      patientId: json['patient_id'] ?? json['id'] ?? '',
      firstName: json['first_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      hasAssignedDoctors: json['has_assigned_doctors'] ?? false,
      fullName: json['full_name'] ?? json['firstName'],
      gender: json['gender'],
      phone: json['phone'],
      dob: json['dob'],
      role: json['role'] is Map ? json['role']['role_name'] : json['role'],
      joinedAt: json['joined_at'],
    );
  }
}
