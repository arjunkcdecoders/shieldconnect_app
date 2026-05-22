import 'user_model.dart';

class StatusModel {
  final String? id;
  final String? userId;
  final UserModel? user;
  final String? contentType;
  final String? content;
  final String? backgroundColor;
  final String? caption;
  final List<String>? viewerIds;
  final List<UserModel>? viewers;
  final DateTime? expireAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? privacyType;
  final List<String>? privacyList;

  StatusModel({
    this.id,
    this.userId,
    this.user,
    this.contentType,
    this.content,
    this.backgroundColor,
    this.caption,
    this.viewerIds,
    this.viewers,
    this.expireAt,
    this.createdAt,
    this.updatedAt,
    this.privacyType,
    this.privacyList,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      userId: json['user_id'] is String ? json['user_id'] as String? : (json['user_id'] is Map ? json['user_id']['_id'] as String? : null),
      user: json['user_id'] is Map<String, dynamic> ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>) : null,
      contentType: json['content_type'] as String?,
      content: json['content'] as String?,
      backgroundColor: json['background_color'] as String?,
      caption: json['caption'] as String?,
      viewerIds: (json['viewers'] as List<dynamic>?)
          ?.map((e) {
            if (e is String) return e;
            if (e is Map) {
              final userIdField = e['user_id'];
              if (userIdField is String) {
                return userIdField;
              } else if (userIdField is Map) {
                return userIdField['_id'] as String? ?? userIdField['id'] as String?;
              }
              return e['_id'] as String? ?? e['id'] as String?;
            }
            return null;
          })
          .whereType<String>()
          .toList(),
      viewers: (json['viewers'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) {
            final map = e as Map<String, dynamic>;
            if (map['user_id'] is Map<String, dynamic>) {
              return UserModel.fromJson(map['user_id'] as Map<String, dynamic>);
            }
            return UserModel.fromJson(map);
          })
          .toList(),
      expireAt: json['expireAt'] != null ? DateTime.tryParse(json['expireAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
      privacyType: json['privacy_type'] as String?,
      privacyList: (json['privacy_list'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': user?.toJson() ?? userId,
      'content_type': contentType,
      'content': content,
      'background_color': backgroundColor,
      'caption': caption,
      'viewers': viewers?.map((e) => e.toJson()).toList() ?? viewerIds,
      'expireAt': expireAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'privacy_type': privacyType,
      'privacy_list': privacyList,
    };
  }
}
