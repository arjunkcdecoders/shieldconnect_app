import 'user_model.dart';

class FriendModel {
  final String? id;
  final String? userId;
  final UserModel? user;
  final String? friendId;
  final UserModel? friend;
  final String? status;
  final String? requestedBy;
  final UserModel? requester;
  final List<String>? blockedBy;
  final List<String>? blockedUsers;
  final String? previousStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FriendModel({
    this.id,
    this.userId,
    this.user,
    this.friendId,
    this.friend,
    this.status,
    this.requestedBy,
    this.requester,
    this.blockedBy,
    this.blockedUsers,
    this.previousStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      userId: json['user_id'] is String ? json['user_id'] as String? : (json['user_id'] is Map ? json['user_id']['_id'] as String? : null),
      user: json['user_id'] is Map<String, dynamic> ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>) : null,
      friendId: json['friend_id'] is String ? json['friend_id'] as String? : (json['friend_id'] is Map ? json['friend_id']['_id'] as String? : null),
      friend: json['friend_id'] is Map<String, dynamic> ? UserModel.fromJson(json['friend_id'] as Map<String, dynamic>) : null,
      status: json['status'] as String?,
      requestedBy: json['requested_by'] is String ? json['requested_by'] as String? : (json['requested_by'] is Map ? json['requested_by']['_id'] as String? : null),
      requester: json['requested_by'] is Map<String, dynamic> ? UserModel.fromJson(json['requested_by'] as Map<String, dynamic>) : null,
      blockedBy: (json['blocked_by'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      blockedUsers: (json['blocked_users'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      previousStatus: json['previous_status'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': user?.toJson() ?? userId,
      'friend_id': friend?.toJson() ?? friendId,
      'status': status,
      'requested_by': requester?.toJson() ?? requestedBy,
      'blocked_by': blockedBy,
      'blocked_users': blockedUsers,
      'previous_status': previousStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
