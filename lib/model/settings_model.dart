class SettingsModel {
  final String? id;
  final String? docLimit;
  final String? audioLimit;
  final String? videoLimit;
  final String? imageLimit;
  final int? shareLimit;
  final int? msgLength;
  final String? uploadTypes;
  final int? callTimeout;
  final int? statusExpiry;
  final int? sessionExpiry;
  final int? maxGroup;
  final int? maxGroupMembers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SettingsModel({
    this.id,
    this.docLimit,
    this.audioLimit,
    this.videoLimit,
    this.imageLimit,
    this.shareLimit,
    this.msgLength,
    this.uploadTypes,
    this.callTimeout,
    this.statusExpiry,
    this.sessionExpiry,
    this.maxGroup,
    this.maxGroupMembers,
    this.createdAt,
    this.updatedAt,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      docLimit: json['docLimit'] as String? ?? json['doc_limit'] as String?,
      audioLimit: json['audioLimit'] as String? ?? json['audio_limit'] as String?,
      videoLimit: json['videoLimit'] as String? ?? json['video_limit'] as String?,
      imageLimit: json['imageLimit'] as String? ?? json['image_limit'] as String?,
      shareLimit: json['shareLimit'] as int? ?? json['share_limit'] as int?,
      msgLength: json['msgLength'] as int? ?? json['msg_length'] as int?,
      uploadTypes: json['uploadTypes'] as String? ?? json['upload_types'] as String?,
      callTimeout: json['callTimeout'] as int? ?? json['call_timeout'] as int?,
      statusExpiry: json['statusExpiry'] as int? ?? json['status_expiry'] as int?,
      sessionExpiry: json['sessionExpiry'] as int? ?? json['session_expiry'] as int?,
      maxGroup: json['maxGroup'] as int? ?? json['max_group'] as int?,
      maxGroupMembers: json['maxGroupMembers'] as int? ?? json['max_group_members'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'docLimit': docLimit,
      'audioLimit': audioLimit,
      'videoLimit': videoLimit,
      'imageLimit': imageLimit,
      'shareLimit': shareLimit,
      'msgLength': msgLength,
      'uploadTypes': uploadTypes,
      'callTimeout': callTimeout,
      'statusExpiry': statusExpiry,
      'sessionExpiry': sessionExpiry,
      'maxGroup': maxGroup,
      'maxGroupMembers': maxGroupMembers,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
