class DhsiUser {
  final String name;
  final String avatar;

  DhsiUser({
    required this.name,
    required this.avatar,
  });

  factory DhsiUser.fromJson(Map<String, dynamic> json) {
    return DhsiUser(
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
    };
  }
}
