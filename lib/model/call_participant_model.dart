class CallParticipantModel {
  final String? id;
  final String? callId;
  final String? userId;
  final String? status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final bool? isMuted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CallParticipantModel({
    this.id,
    this.callId,
    this.userId,
    this.status,
    this.joinedAt,
    this.leftAt,
    this.isMuted,
    this.createdAt,
    this.updatedAt,
  });

  factory CallParticipantModel.fromJson(Map<String, dynamic> json) {
    return CallParticipantModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      callId: json['call_id'] as String?,
      userId: json['user_id'] as String?,
      status: json['status'] as String?,
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'] as String) : null,
      leftAt: json['left_at'] != null ? DateTime.tryParse(json['left_at'] as String) : null,
      isMuted: json['is_muted'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'call_id': callId,
      'user_id': userId,
      'status': status,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_muted': isMuted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
