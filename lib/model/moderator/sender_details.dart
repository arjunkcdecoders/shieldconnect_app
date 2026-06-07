class SenderDetails {
  final String id;
  final String name;
  final String? avatar;
  final String? email;

  SenderDetails({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
  });

  factory SenderDetails.fromJson(Map<String, dynamic> json) {
    return SenderDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'avatar': avatar,
      'email': email,
    };
  }
}
