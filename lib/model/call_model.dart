import 'user_model.dart';

class CallModel {
  final String? id;
  final String? initiatorId;
  final UserModel? initiator;
  final String? receiverId;
  final UserModel? receiver;
  final String? groupName;
  final bool? isGroup;
  final String? groupId;
  final String? groupAvatar;
  final String? callType;
  final String? status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CallModel({
    this.id,
    this.initiatorId,
    this.initiator,
    this.receiverId,
    this.receiver,
    this.groupName,
    this.isGroup,
    this.groupId,
    this.groupAvatar,
    this.callType,
    this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      initiatorId: json['initiator_id'] is String ? json['initiator_id'] as String? : (json['initiator_id'] is Map ? json['initiator_id']['_id'] as String? : null),
      initiator: json['initiator_id'] is Map<String, dynamic> ? UserModel.fromJson(json['initiator_id'] as Map<String, dynamic>) : null,
      receiverId: json['receiver_id'] is String ? json['receiver_id'] as String? : (json['receiver_id'] is Map ? json['receiver_id']['_id'] as String? : null),
      receiver: json['receiver_id'] is Map<String, dynamic> ? UserModel.fromJson(json['receiver_id'] as Map<String, dynamic>) : null,
      groupName: json['group_name'] as String?,
      isGroup: json['is_group'] as bool?,
      groupId: json['group_id'] as String?,
      groupAvatar: json['group_avatar'] as String?,
      callType: json['call_type'] as String?,
      status: json['status'] as String?,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'] as String) : null,
      duration: json['duration'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'initiator_id': initiator?.toJson() ?? initiatorId,
      'receiver_id': receiver?.toJson() ?? receiverId,
      'group_name': groupName,
      'is_group': isGroup,
      'group_id': groupId,
      'group_avatar': groupAvatar,
      'call_type': callType,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration': duration,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
