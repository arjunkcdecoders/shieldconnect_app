class SessionResponse {
  final bool isLoggedIn;
  final SessionAdmin? admin;

  SessionResponse({required this.isLoggedIn, this.admin});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      isLoggedIn: json['isLoggedIn'] ?? false,
      admin: json['admin'] != null ? SessionAdmin.fromJson(json['admin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLoggedIn': isLoggedIn,
      'admin': admin?.toJson(),
    };
  }
}

class SessionAdmin {
  final String id;
  final String email;
  final String role;
  final String? name;

  SessionAdmin({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  factory SessionAdmin.fromJson(Map<String, dynamic> json) {
    return SessionAdmin(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'role': role,
      'name': name,
    };
  }
}
