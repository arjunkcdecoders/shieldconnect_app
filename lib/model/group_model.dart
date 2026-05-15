import 'user_model.dart';

class GroupModel {
  final String? id;
  final String? name;
  final String? description;
  final String? groupImage;
  final String? adminId;
  final UserModel? admin;
  final List<GroupMember>? members;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroupModel({
    this.id,
    this.name,
    this.description,
    this.groupImage,
    this.adminId,
    this.admin,
    this.members,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      groupImage: json['group_image'] as String?,
      adminId: json['admin_id'] is String ? json['admin_id'] as String? : (json['admin_id'] is Map ? json['admin_id']['_id'] as String? : null),
      admin: json['admin_id'] is Map<String, dynamic> ? UserModel.fromJson(json['admin_id'] as Map<String, dynamic>) : null,
      members: (json['members'] as List<dynamic>?)?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList(),
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'group_image': groupImage,
      'admin_id': admin?.toJson() ?? adminId,
      'members': members?.map((e) => e.toJson()).toList(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class GroupMember {
  final String? id;
  final String? userId;
  final UserModel? user;
  final String? role;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  GroupMember({
    this.id,
    this.userId,
    this.user,
    this.role,
    this.joinedAt,
    this.leftAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['_id'] as String? ?? json['id'] as String?,
      userId: json['user_id'] is String ? json['user_id'] as String? : (json['user_id'] is Map ? json['user_id']['_id'] as String? : null),
      user: json['user_id'] is Map<String, dynamic> ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>) : null,
      role: json['role'] as String?,
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'] as String) : null,
      leftAt: json['left_at'] != null ? DateTime.tryParse(json['left_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': user?.toJson() ?? userId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
    };
  }
}
