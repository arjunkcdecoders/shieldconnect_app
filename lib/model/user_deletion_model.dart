class UserDeletionModel {
  final String? id;
  final String? userId;
  final String? chatId;
  final String? chatType;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDeletionModel({
    this.id,
    this.userId,
    this.chatId,
    this.chatType,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDeletionModel.fromJson(Map<String, dynamic> json) {
    return UserDeletionModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      userId: json['user_id'] as String?,
      chatId: json['chat_id'] as String?,
      chatType: json['chat_type'] as String?,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'chat_id': chatId,
      'chat_type': chatType,
      'deleted_at': deletedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
