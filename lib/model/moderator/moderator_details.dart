class ModeratorDetails {
  final String name;
  final String email;
  final String role;

  ModeratorDetails({
    required this.name,
    required this.email,
    required this.role,
  });

  factory ModeratorDetails.fromJson(Map<String, dynamic> json) {
    return ModeratorDetails(
      name: json['name'] ?? 'System',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
